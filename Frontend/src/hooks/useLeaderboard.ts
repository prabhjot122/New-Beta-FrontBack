// Leaderboard-specific hooks

import { useState, useCallback, useEffect } from 'react';
import { useApiState as useApiStateHook, usePaginatedApi } from './useApi';
import { leaderboardService } from '../services/leaderboardService';
import { 
  LeaderboardUser, 
  AroundMeUser, 
  TopPerformer,
  PaginationParams 
} from '../types/api';

// Hook for main leaderboard
export function useLeaderboard(initialParams: PaginationParams = { page: 1, limit: 50 }) {
  const [params, setParams] = useState(initialParams);
  
  const {
    data: leaderboard,
    pagination,
    loading,
    error,
    execute,
    reset
  } = usePaginatedApi<LeaderboardUser>([], null);

  const loadLeaderboard = useCallback(async (newParams?: Partial<PaginationParams>) => {
    const finalParams = { ...params, ...newParams };
    setParams(finalParams);

    // Add cache-busting timestamp to force fresh data
    const response = await leaderboardService.getLeaderboard({
      ...finalParams,
      _t: Date.now()
    });
    return {
      data: response.leaderboard,
      pagination: response.pagination
    };
  }, [params]);

  const refresh = useCallback(() => {
    return execute(() => loadLeaderboard());
  }, [execute, loadLeaderboard]);

  const loadPage = useCallback((page: number) => {
    return execute(() => loadLeaderboard({ page }));
  }, [execute, loadLeaderboard]);

  const changePageSize = useCallback((limit: number) => {
    return execute(() => loadLeaderboard({ page: 1, limit }));
  }, [execute, loadLeaderboard]);

  // Auto-load on mount
  useEffect(() => {
    refresh();
  }, []);

  return {
    leaderboard,
    pagination,
    loading,
    error,
    refresh,
    loadPage,
    changePageSize,
    reset
  };
}

// Hook for "Around Me" leaderboard
export function useAroundMe(range: number = 5) {
  const {
    data,
    loading,
    error,
    execute,
    reset
  } = useApiStateHook<{
    surrounding_users: AroundMeUser[];
    your_stats: any;
  } | null>(null);

  const loadAroundMe = useCallback(async (newRange?: number) => {
    const finalRange = newRange ?? range;
    return await leaderboardService.getAroundMe(finalRange);
  }, [range]);

  const refresh = useCallback(() => {
    return execute(() => loadAroundMe());
  }, [execute, loadAroundMe]);

  const changeRange = useCallback((newRange: number) => {
    return execute(() => loadAroundMe(newRange));
  }, [execute, loadAroundMe]);

  return {
    aroundMeData: data,
    surroundingUsers: data?.surrounding_users || [],
    userStats: data?.your_stats || null,
    loading,
    error,
    refresh,
    changeRange,
    reset
  };
}

// Hook for top performers
export function useTopPerformers(
  initialPeriod: 'daily' | 'weekly' | 'monthly' | 'all-time' = 'weekly',
  initialLimit: number = 10
) {
  const [period, setPeriod] = useState(initialPeriod);
  const [limit, setLimit] = useState(initialLimit);
  
  const {
    data,
    loading,
    error,
    execute,
    reset
  } = useApiStateHook<{
    period: string;
    top_performers: TopPerformer[];
    period_stats: any;
  } | null>(null);

  const loadTopPerformers = useCallback(async (
    newPeriod?: typeof period,
    newLimit?: number
  ) => {
    const finalPeriod = newPeriod ?? period;
    const finalLimit = newLimit ?? limit;
    
    setPeriod(finalPeriod);
    setLimit(finalLimit);
    
    return await leaderboardService.getTopPerformers(finalPeriod, finalLimit);
  }, [period, limit]);

  const refresh = useCallback(() => {
    return execute(() => loadTopPerformers());
  }, [execute, loadTopPerformers]);

  const changePeriod = useCallback((newPeriod: typeof period) => {
    return execute(() => loadTopPerformers(newPeriod));
  }, [execute, loadTopPerformers]);

  const changeLimit = useCallback((newLimit: number) => {
    return execute(() => loadTopPerformers(undefined, newLimit));
  }, [execute, loadTopPerformers]);

  // Auto-load on mount
  useEffect(() => {
    refresh();
  }, []);

  return {
    topPerformersData: data,
    topPerformers: data?.top_performers || [],
    periodStats: data?.period_stats || null,
    period,
    limit,
    loading,
    error,
    refresh,
    changePeriod,
    changeLimit,
    reset
  };
}

// Hook for user's leaderboard stats
export function useUserLeaderboardStats() {
  const {
    data: userStats,
    loading,
    error,
    execute,
    reset
  } = useApiStateHook<{
    rank: number | null;
    points: number;
    points_to_next_rank: number;
    percentile: number;
  } | null>(null);

  const loadUserStats = useCallback(async () => {
    const stats = await leaderboardService.getUserStats();
    if (stats) {
      return {
        ...stats,
        rank: stats.rank ?? null
      };
    }
    return null;
  }, []);

  const refresh = useCallback(() => {
    return execute(loadUserStats);
  }, [execute, loadUserStats]);

  return {
    userStats,
    rank: userStats?.rank || null,
    points: userStats?.points || 0,
    pointsToNextRank: userStats?.points_to_next_rank || 0,
    percentile: userStats?.percentile || 0,
    loading,
    error,
    refresh,
    reset
  };
}

// Hook for leaderboard summary (for dashboard widgets)
export function useLeaderboardSummary() {
  const {
    data,
    loading,
    error,
    execute,
    reset
  } = useApiStateHook<{
    totalUsers: number;
    topUser: { name: string; points: number } | null;
    userRank: number | null;
    userPercentile: number | null;
  } | null>(null);

  const loadSummary = useCallback(async () => {
    return await leaderboardService.getLeaderboardSummary();
  }, []);

  const refresh = useCallback(() => {
    return execute(loadSummary);
  }, [execute, loadSummary]);

  // Auto-load on mount
  useEffect(() => {
    refresh();
  }, []);

  return {
    summary: data,
    totalUsers: data?.totalUsers || 0,
    topUser: data?.topUser || null,
    userRank: data?.userRank || null,
    userPercentile: data?.userPercentile || null,
    loading,
    error,
    refresh,
    reset
  };
}

// Combined hook for leaderboard page
export function useLeaderboardPage() {
  const [activeTab, setActiveTab] = useState<'top' | 'around-me'>('top');
  
  const leaderboard = useLeaderboard();
  const aroundMe = useAroundMe();
  const userStats = useUserLeaderboardStats();

  const refreshAll = useCallback(() => {
    return Promise.all([
      leaderboard.refresh(),
      aroundMe.refresh(),
      userStats.refresh()
    ]);
  }, [leaderboard.refresh, aroundMe.refresh, userStats.refresh]);

  const switchTab = useCallback((tab: 'top' | 'around-me') => {
    setActiveTab(tab);
    if (tab === 'around-me' && !aroundMe.aroundMeData) {
      aroundMe.refresh();
    }
  }, [aroundMe]);

  return {
    activeTab,
    setActiveTab: switchTab,
    leaderboard,
    aroundMe,
    userStats,
    refreshAll,
    loading: leaderboard.loading || aroundMe.loading || userStats.loading,
    error: leaderboard.error || aroundMe.error || userStats.error
  };
}
