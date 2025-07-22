// Shares-specific hooks

import { useState, useCallback, useEffect } from 'react';
import { useApiState, usePaginatedApi, useAsyncOperation } from './useApi';
import { sharesService } from '../services/sharesService';
import { 
  PlatformType, 
  ShareResponse, 
  ShareHistoryItem, 
  ShareAnalyticsResponse,
  PaginationParams 
} from '../types/api';

// Hook for recording shares
export function useShareRecording() {
  const { loading, error, execute, reset } = useAsyncOperation();
  const [lastShareResult, setLastShareResult] = useState<ShareResponse | null>(null);

  const recordShare = useCallback(async (platform: PlatformType): Promise<ShareResponse | null> => {
    const result = await execute(() => sharesService.recordShare(platform));
    if (result) {
      setLastShareResult(result);
    }
    return result;
  }, [execute]);

  const shareAndOpen = useCallback(async (platform: PlatformType, content?: string) => {
    // Open share dialog first
    sharesService.openShareDialog(platform, content || '');
    
    // Record the share
    return await recordShare(platform);
  }, [recordShare]);

  return {
    recordShare,
    shareAndOpen,
    lastShareResult,
    loading,
    error,
    reset
  };
}

// Hook for share history
export function useShareHistory(
  initialParams: PaginationParams & { platform?: PlatformType } = { page: 1, limit: 20 }
) {
  const [params, setParams] = useState(initialParams);
  
  const {
    data: shares,
    pagination,
    loading,
    error,
    execute,
    loadMore,
    reset
  } = usePaginatedApi<ShareHistoryItem>([], null);

  const loadHistory = useCallback(async (newParams?: Partial<typeof params>) => {
    const finalParams = { ...params, ...newParams };
    setParams(finalParams);
    
    const response = await sharesService.getShareHistory(finalParams);
    return {
      data: response.shares,
      pagination: response.pagination
    };
  }, [params]);

  const refresh = useCallback(() => {
    return execute(() => loadHistory());
  }, [execute, loadHistory]);

  const loadPage = useCallback((page: number) => {
    return execute(() => loadHistory({ page }));
  }, [execute, loadHistory]);

  const filterByPlatform = useCallback((platform?: PlatformType) => {
    return execute(() => loadHistory({ page: 1, platform }));
  }, [execute, loadHistory]);

  const loadMoreShares = useCallback(() => {
    if (!pagination || pagination.page >= pagination.pages) return;
    
    return loadMore(() => loadHistory({ page: pagination.page + 1 }));
  }, [loadMore, loadHistory, pagination]);

  // Auto-load on mount
  useEffect(() => {
    refresh();
  }, []);

  return {
    shares,
    pagination,
    loading,
    error,
    refresh,
    loadPage,
    filterByPlatform,
    loadMoreShares,
    reset,
    hasMore: pagination ? pagination.page < pagination.pages : false
  };
}

// Hook for share analytics
export function useShareAnalytics() {
  const {
    data: analytics,
    loading,
    error,
    execute,
    reset
  } = useApiState<ShareAnalyticsResponse | null>(null);

  const loadAnalytics = useCallback(async () => {
    return await sharesService.getShareAnalytics();
  }, []);

  const refresh = useCallback(() => {
    return execute(loadAnalytics);
  }, [execute, loadAnalytics]);

  // Auto-load on mount
  useEffect(() => {
    refresh();
  }, []);

  return {
    analytics,
    totalShares: analytics?.total_shares || 0,
    pointsBreakdown: analytics?.points_breakdown || {},
    recentActivity: analytics?.recent_activity || [],
    loading,
    error,
    refresh,
    reset
  };
}

// Hook for platform sharing utilities
export function usePlatformSharing() {
  const availablePlatforms = sharesService.getAvailablePlatforms();

  const getShareUrl = useCallback((platform: PlatformType, content?: string) => {
    return sharesService.getShareUrl(platform, content);
  }, []);

  const openShareDialog = useCallback((platform: PlatformType, content?: string) => {
    sharesService.openShareDialog(platform, content || '');
  }, []);

  const hasSharedOnPlatform = useCallback((platform: PlatformType) => {
    return sharesService.hasSharedOnPlatform(platform);
  }, []);

  const getPointsForPlatform = useCallback((platform: PlatformType) => {
    return sharesService.getPointsForPlatform(platform);
  }, []);

  return {
    availablePlatforms,
    getShareUrl,
    openShareDialog,
    hasSharedOnPlatform,
    getPointsForPlatform
  };
}

// Hook for sharing widget/component
export function useSharingWidget() {
  const shareRecording = useShareRecording();
  const platformSharing = usePlatformSharing();
  const [selectedPlatform, setSelectedPlatform] = useState<PlatformType | null>(null);

  const handleShare = useCallback(async (platform: PlatformType, content?: string) => {
    setSelectedPlatform(platform);
    
    try {
      const result = await shareRecording.shareAndOpen(platform, content);
      
      if (result && result.points_earned > 0) {
        // Show success message or trigger celebration animation
        console.log(`Successfully shared on ${platform}! Earned ${result.points_earned} points.`);
      }
      
      return result;
    } catch (error) {
      console.error(`Failed to share on ${platform}:`, error);
      throw error;
    } finally {
      setSelectedPlatform(null);
    }
  }, [shareRecording]);

  const isSharing = useCallback((platform: PlatformType) => {
    return selectedPlatform === platform && shareRecording.loading;
  }, [selectedPlatform, shareRecording.loading]);

  return {
    handleShare,
    isSharing,
    lastShareResult: shareRecording.lastShareResult,
    error: shareRecording.error,
    availablePlatforms: platformSharing.availablePlatforms,
    getPointsForPlatform: platformSharing.getPointsForPlatform,
    hasSharedOnPlatform: platformSharing.hasSharedOnPlatform
  };
}

// Combined hook for shares dashboard/page
export function useSharesDashboard() {
  const analytics = useShareAnalytics();
  const history = useShareHistory({ page: 1, limit: 10 }); // Recent shares
  const sharing = useSharingWidget();

  const refreshAll = useCallback(() => {
    return Promise.all([
      analytics.refresh(),
      history.refresh()
    ]);
  }, [analytics.refresh, history.refresh]);

  // Calculate derived data
  const totalPointsEarned = Object.values(analytics.pointsBreakdown).reduce(
    (total, platform) => total + platform.points, 0
  );

  const mostActiveplatform = Object.entries(analytics.pointsBreakdown).reduce(
    (top, [platform, data]) => 
      data.shares > (analytics.pointsBreakdown[top]?.shares || 0) ? platform : top,
    'linkedin'
  );

  return {
    analytics,
    history,
    sharing,
    refreshAll,
    totalPointsEarned,
    mostActiveplatform,
    loading: analytics.loading || history.loading,
    error: analytics.error || history.error
  };
}

// Hook for share notifications/toasts
export function useShareNotifications() {
  const [notifications, setNotifications] = useState<Array<{
    id: string;
    type: 'success' | 'error' | 'info';
    message: string;
    platform?: PlatformType;
    points?: number;
  }>>([]);

  const addNotification = useCallback((notification: Omit<typeof notifications[0], 'id'>) => {
    const id = Date.now().toString();
    setNotifications(prev => [...prev, { ...notification, id }]);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
      setNotifications(prev => prev.filter(n => n.id !== id));
    }, 5000);
  }, []);

  const removeNotification = useCallback((id: string) => {
    setNotifications(prev => prev.filter(n => n.id !== id));
  }, []);

  const clearAll = useCallback(() => {
    setNotifications([]);
  }, []);

  return {
    notifications,
    addNotification,
    removeNotification,
    clearAll
  };
}
