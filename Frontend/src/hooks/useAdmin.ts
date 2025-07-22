// Admin-specific hooks

import { useState, useCallback, useEffect } from 'react';
import { useApiState, usePaginatedApi, useAsyncOperation, useDebouncedApi } from './useApi';
import { adminService } from '../services/adminService';
import { 
  AdminDashboardResponse, 
  AdminUser, 
  BulkEmailRequest,
  // PaginationParams
} from '../types/api';

// Hook for admin dashboard
export function useAdminDashboard() {
  const {
    data: dashboard,
    loading,
    error,
    execute,
    reset
  } = useApiState<AdminDashboardResponse | null>(null);

  const loadDashboard = useCallback(async () => {
    return await adminService.getDashboard();
  }, []);

  const refresh = useCallback(() => {
    return execute(loadDashboard);
  }, [execute, loadDashboard]);

  // Auto-load on mount
  useEffect(() => {
    refresh();
  }, []);

  return {
    dashboard,
    overview: dashboard?.overview || null,
    platformBreakdown: dashboard?.platform_breakdown || {},
    growthMetrics: dashboard?.growth_metrics || null,
    loading,
    error,
    refresh,
    reset
  };
}

// Hook for admin user management
export function useAdminUsers(
  initialParams: {
    page?: number;
    limit?: number;
    search?: string;
    sort?: string;
  } = { page: 1, limit: 50, search: '', sort: 'points' }
) {
  const [params, setParams] = useState(initialParams);
  
  const {
    data: users,
    pagination,
    loading,
    error,
    execute,
    reset
  } = usePaginatedApi<AdminUser>([], null);

  const loadUsers = useCallback(async (newParams?: Partial<typeof params>) => {
    const finalParams = { ...params, ...newParams };
    setParams(finalParams);
    
    const response = await adminService.getUsers(finalParams);
    return {
      data: response.users,
      pagination: response.pagination
    };
  }, [params]);

  const refresh = useCallback(() => {
    return execute(() => loadUsers());
  }, [execute, loadUsers]);

  const loadPage = useCallback((page: number) => {
    return execute(() => loadUsers({ page }));
  }, [execute, loadUsers]);

  const search = useCallback((searchQuery: string) => {
    return execute(() => loadUsers({ page: 1, search: searchQuery }));
  }, [execute, loadUsers]);

  const sort = useCallback((sortBy: string) => {
    return execute(() => loadUsers({ page: 1, sort: sortBy }));
  }, [execute, loadUsers]);

  const changePageSize = useCallback((limit: number) => {
    return execute(() => loadUsers({ page: 1, limit }));
  }, [execute, loadUsers]);

  // Auto-load on mount
  useEffect(() => {
    refresh();
  }, []);

  return {
    users,
    pagination,
    loading,
    error,
    refresh,
    loadPage,
    search,
    sort,
    changePageSize,
    reset,
    currentParams: params
  };
}

// Hook for bulk email functionality
export function useBulkEmail() {
  const { loading, error, execute, reset } = useAsyncOperation();
  const [lastResult, setLastResult] = useState<{ message: string; recipients: number } | null>(null);

  const sendBulkEmail = useCallback(async (emailData: BulkEmailRequest) => {
    const result = await execute(() => adminService.sendBulkEmail(emailData));
    if (result) {
      setLastResult(result);
    }
    return result;
  }, [execute]);

  return {
    sendBulkEmail,
    lastResult,
    loading,
    error,
    reset
  };
}

// Hook for user promotion
export function useUserPromotion() {
  const { loading, error, execute, reset } = useAsyncOperation();
  const [lastPromoted, setLastPromoted] = useState<{ message: string; user: string } | null>(null);

  const promoteUser = useCallback(async (userId: number) => {
    const result = await execute(() => adminService.promoteUser(userId));
    if (result) {
      setLastPromoted(result);
    }
    return result;
  }, [execute]);

  return {
    promoteUser,
    lastPromoted,
    loading,
    error,
    reset
  };
}

// Hook for user data export
export function useUserExport() {
  const { loading, error, execute, reset } = useAsyncOperation();

  const exportUsers = useCallback(async (
    format: 'csv' | 'json',
    filters?: { search?: string; minPoints?: number }
  ) => {
    const blob = await execute(() => adminService.exportUsers(format, filters));
    
    if (blob) {
      // Create download link
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `users.${format}`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    }
    
    return blob;
  }, [execute]);

  return {
    exportUsers,
    loading,
    error,
    reset
  };
}

// Hook for admin statistics
export function useAdminStats() {
  const {
    data: stats,
    loading,
    error,
    execute,
    reset
  } = useApiState<{
    totalUsers: number;
    activeUsers: number;
    totalShares: number;
    totalPoints: number;
    topPlatform: string;
  } | null>(null);

  const loadStats = useCallback(async () => {
    return await adminService.getAdminStats();
  }, []);

  const refresh = useCallback(() => {
    return execute(loadStats);
  }, [execute, loadStats]);

  // Auto-load on mount
  useEffect(() => {
    refresh();
  }, []);

  return {
    stats,
    totalUsers: stats?.totalUsers || 0,
    activeUsers: stats?.activeUsers || 0,
    totalShares: stats?.totalShares || 0,
    totalPoints: stats?.totalPoints || 0,
    topPlatform: stats?.topPlatform || '',
    loading,
    error,
    refresh,
    reset
  };
}

// Hook for user search with debouncing
export function useUserSearch() {
  const searchApi = useDebouncedApi(
    async (query: string) => {
      const response = await adminService.getUsers({ 
        page: 1, 
        limit: 10, 
        search: query 
      });
      return response.users;
    },
    300
  );

  return {
    searchResults: searchApi.data || [],
    loading: searchApi.loading,
    error: searchApi.error,
    search: searchApi.execute
  };
}

// Hook for user status management
export function useUserStatus() {
  const { loading, error, execute, reset } = useAsyncOperation();

  const updateUserStatus = useCallback(async (
    userId: number, 
    status: 'active' | 'inactive'
  ) => {
    return await execute(() => adminService.updateUserStatus(userId, status));
  }, [execute]);

  return {
    updateUserStatus,
    loading,
    error,
    reset
  };
}

// Combined hook for admin panel
export function useAdminPanel() {
  const [activeTab, setActiveTab] = useState<'overview' | 'users' | 'email' | 'analytics' | 'campaigns' | 'shares' | 'feedback' | 'settings'>('overview');
  
  const dashboard = useAdminDashboard();
  const users = useAdminUsers();
  const bulkEmail = useBulkEmail();
  const userPromotion = useUserPromotion();
  const userExport = useUserExport();
  const stats = useAdminStats();

  const refreshAll = useCallback(() => {
    return Promise.all([
      dashboard.refresh(),
      users.refresh(),
      stats.refresh()
    ]);
  }, [dashboard.refresh, users.refresh, stats.refresh]);

  const switchTab = useCallback((tab: typeof activeTab) => {
    setActiveTab(tab);
    
    // Load data for specific tabs if not already loaded
    switch (tab) {
      case 'users':
        if (!users.users.length) {
          users.refresh();
        }
        break;
      case 'analytics':
        if (!stats.stats) {
          stats.refresh();
        }
        break;
    }
  }, [users, stats]);

  return {
    activeTab,
    setActiveTab: switchTab,
    dashboard,
    users,
    bulkEmail,
    userPromotion,
    userExport,
    stats,
    refreshAll,
    loading: dashboard.loading || users.loading || stats.loading,
    error: dashboard.error || users.error || stats.error
  };
}

// Hook for admin notifications/alerts
export function useAdminNotifications() {
  const [notifications, setNotifications] = useState<Array<{
    id: string;
    type: 'success' | 'error' | 'warning' | 'info';
    title: string;
    message: string;
    timestamp: Date;
  }>>([]);

  const addNotification = useCallback((notification: Omit<typeof notifications[0], 'id' | 'timestamp'>) => {
    const id = Date.now().toString();
    setNotifications(prev => [...prev, { 
      ...notification, 
      id, 
      timestamp: new Date() 
    }]);
    
    // Auto-remove after 10 seconds for non-error notifications
    if (notification.type !== 'error') {
      setTimeout(() => {
        setNotifications(prev => prev.filter(n => n.id !== id));
      }, 10000);
    }
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
