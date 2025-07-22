// Admin service for administrative functions and user management

import { apiClient, withErrorHandling, MOCK_MODE, mockDelay } from './api';
import {
  AdminDashboardResponse,
  AdminUsersResponse,
  BulkEmailRequest,
  // PromoteRequest,
  // PaginationParams,
  ShareAnalyticsEnhanced,
  ShareHistoryResponse
} from '../types/api';
import { mockUsers, mockAnalytics } from './mockData';

class AdminService {
  /**
   * Get admin dashboard overview
   */
  async getDashboard(): Promise<AdminDashboardResponse> {
    if (MOCK_MODE) {
      await mockDelay();

      // Return mock analytics data
      return {
        overview: {
          total_users: mockAnalytics.totalUsers,
          active_users_24h: mockAnalytics.activeUsers24h,
          total_shares_today: mockAnalytics.totalSharesToday,
          points_distributed_today: mockAnalytics.pointsDistributedToday
        },
        platform_breakdown: mockAnalytics.platformBreakdown,
        growth_metrics: {
          new_users_7d: mockAnalytics.growthMetrics.newUsers7d,
          user_retention_rate: mockAnalytics.growthMetrics.userRetentionRate,
          average_session_duration: mockAnalytics.growthMetrics.averageSessionDuration
        }
      };
    }

    try {
      return await withErrorHandling(() =>
        apiClient.get<AdminDashboardResponse>('/admin/dashboard')
      );
    } catch (error) {
      console.error('Failed to fetch admin dashboard:', error);
      throw error;
    }
  }

  /**
   * Get admin share analytics (system-wide)
   */
  async getShareAnalytics(): Promise<ShareAnalyticsEnhanced> {
    if (MOCK_MODE) {
      await mockDelay();
      // Return mock analytics data in the expected format
      return {
        platform_breakdown: {
          facebook: { shares: 15, points: 45, percentage: 40.0 },
          twitter: { shares: 10, points: 10, percentage: 26.7 },
          linkedin: { shares: 8, points: 40, percentage: 21.3 },
          instagram: { shares: 5, points: 10, percentage: 13.3 }
        },
        timeline: [],
        summary: {
          total_shares: 38,
          total_points: 105,
          active_platforms: 4,
          average_points_per_share: 2.8
        }
      };
    }

    try {
      return await withErrorHandling(() =>
        apiClient.get<ShareAnalyticsEnhanced>('/admin/analytics')
      );
    } catch (error) {
      console.error('Failed to fetch admin analytics:', error);
      throw error;
    }
  }

  /**
   * Get admin share history (system-wide)
   */
  async getShareHistory(params: {
    page?: number;
    limit?: number;
    platform?: string;
  }): Promise<ShareHistoryResponse> {
    if (MOCK_MODE) {
      await mockDelay();
      // Return mock share history
      return {
        shares: [
          {
            share_id: 1,
            platform: 'facebook',
            points_earned: 3,
            timestamp: new Date().toISOString()
          },
          {
            share_id: 2,
            platform: 'twitter',
            points_earned: 1,
            timestamp: new Date(Date.now() - 3600000).toISOString()
          }
        ],
        pagination: {
          page: 1,
          limit: 10,
          total: 2,
          pages: 1
        }
      };
    }

    const queryParams = new URLSearchParams();
    if (params.page) queryParams.append('page', params.page.toString());
    if (params.limit) queryParams.append('limit', params.limit.toString());
    if (params.platform && params.platform !== 'all') queryParams.append('platform', params.platform);

    try {
      return await withErrorHandling(() =>
        apiClient.get<ShareHistoryResponse>(`/admin/share-history?${queryParams.toString()}`)
      );
    } catch (error) {
      console.error('Failed to fetch admin share history:', error);
      throw error;
    }
  }

  /**
   * Get admin platform statistics
   */
  async getPlatformStats(): Promise<any> {
    if (MOCK_MODE) {
      await mockDelay();
      // Return mock platform stats
      return {
        platform_stats: {
          facebook: { shares: 15, points: 45, percentage: 40.0, unique_users: 8 },
          twitter: { shares: 10, points: 10, percentage: 26.7, unique_users: 6 },
          linkedin: { shares: 8, points: 40, percentage: 21.3, unique_users: 5 },
          instagram: { shares: 5, points: 10, percentage: 13.3, unique_users: 3 }
        },
        summary: {
          total_shares: 38,
          total_points: 105,
          total_platforms: 4
        }
      };
    }

    try {
      return await withErrorHandling(() =>
        apiClient.get('/admin/platform-stats')
      );
    } catch (error) {
      console.error('Failed to fetch admin platform stats:', error);
      throw error;
    }
  }

  /**
   * Get users for admin management with pagination and filtering
   */
  async getUsers(params: {
    page?: number;
    limit?: number;
    search?: string;
    sort?: string;
  }): Promise<AdminUsersResponse> {
    if (MOCK_MODE) {
      await mockDelay();
      
      const { page = 1, limit = 50, search = '', sort = 'points' } = params;
      
      // Filter users by search query
      let filteredUsers = mockUsers;
      if (search.trim()) {
        const searchTerm = search.toLowerCase();
        filteredUsers = mockUsers.filter(user => 
          user.name.toLowerCase().includes(searchTerm) ||
          user.email.toLowerCase().includes(searchTerm)
        );
      }
      
      // Sort users
      const sortedUsers = [...filteredUsers].sort((a, b) => {
        switch (sort) {
          case 'points':
            return b.points - a.points;
          case 'name':
            return a.name.localeCompare(b.name);
          case 'email':
            return a.email.localeCompare(b.email);
          case 'date':
            return new Date(b.registrationDate).getTime() - new Date(a.registrationDate).getTime();
          default:
            return 0;
        }
      });
      
      // Apply pagination
      const startIndex = (page - 1) * limit;
      const endIndex = startIndex + limit;
      const paginatedUsers = sortedUsers.slice(startIndex, endIndex);
      
      // Convert to admin user format
      const adminUsers = paginatedUsers.map(user => ({
        user_id: user.id,
        name: user.name,
        email: user.email,
        points: user.points,
        rank: user.rank,
        shares_count: user.sharesCount,
        status: user.status,
        last_activity: user.lastActivity,
        created_at: user.registrationDate
      }));

      return {
        users: adminUsers,
        pagination: {
          page,
          limit,
          total: sortedUsers.length,
          pages: Math.ceil(sortedUsers.length / limit)
        }
      };
    }

    return withErrorHandling(() => 
      apiClient.get<AdminUsersResponse>('/admin/users', params)
    );
  }

  /**
   * Send bulk email to users
   */
  async sendBulkEmail(emailData: BulkEmailRequest): Promise<{ message: string; recipients: number }> {
    if (MOCK_MODE) {
      await mockDelay(1000); // Longer delay for email sending

      // Calculate eligible users
      const eligibleUsers = mockUsers.filter(user => user.points >= emailData.min_points);

      // Simulate email sending
      console.log('Mock bulk email sent:', {
        subject: emailData.subject,
        body: emailData.body,
        recipients: eligibleUsers.length,
        minPoints: emailData.min_points
      });

      return {
        message: `Bulk email sent successfully to ${eligibleUsers.length} users`,
        recipients: eligibleUsers.length
      };
    }

    try {
      const response = await withErrorHandling(() =>
        apiClient.post('/admin/send-bulk-email', emailData)
      );

      return response as { message: string; recipients: number };
    } catch (error) {
      console.error('Failed to send bulk email:', error);
      throw error;
    }
  }

  /**
   * Promote user to admin status
   */
  async promoteUser(userId: number): Promise<{ message: string; user: string }> {
    if (MOCK_MODE) {
      await mockDelay();
      
      const user = mockUsers.find(u => u.id === userId);
      if (!user) {
        throw new Error('User not found');
      }
      
      // Update user admin status (in real app, this would be persisted)
      user.isAdmin = true;
      
      return {
        message: `User ${user.name} promoted to admin successfully`,
        user: user.name
      };
    }

    const response = await withErrorHandling(() => 
      apiClient.post('/admin/promote', { user_id: userId })
    );

    return response as { message: string; user: string };
  }

  /**
   * Export users data with enhanced filtering
   */
  async exportUsers(format: 'csv' | 'json', filters?: {
    search?: string;
    minPoints?: number;
    status?: 'active' | 'inactive';
    dateRange?: {
      start: string;
      end: string;
    };
  }): Promise<Blob> {
    if (MOCK_MODE) {
      await mockDelay();

      // Filter users based on criteria
      let usersToExport = mockUsers;

      if (filters?.search) {
        const searchTerm = filters.search.toLowerCase();
        usersToExport = usersToExport.filter(user =>
          user.name.toLowerCase().includes(searchTerm) ||
          user.email.toLowerCase().includes(searchTerm)
        );
      }

      if (filters?.minPoints) {
        usersToExport = usersToExport.filter(user => user.points >= filters.minPoints!);
      }

      if (filters?.status) {
        usersToExport = usersToExport.filter(user => user.status === filters.status);
      }

      if (filters?.dateRange) {
        const startDate = new Date(filters.dateRange.start);
        const endDate = new Date(filters.dateRange.end);
        usersToExport = usersToExport.filter(user => {
          const userDate = new Date(user.registrationDate);
          return userDate >= startDate && userDate <= endDate;
        });
      }

      if (format === 'json') {
        const exportData = usersToExport.map(user => ({
          id: user.id,
          name: user.name,
          email: user.email,
          points: user.points,
          rank: user.rank,
          shares_count: user.sharesCount,
          status: user.status,
          registration_date: user.registrationDate,
          last_activity: user.lastActivity,
          is_admin: user.isAdmin
        }));
        const jsonData = JSON.stringify(exportData, null, 2);
        return new Blob([jsonData], { type: 'application/json' });
      } else {
        // CSV format
        const headers = ['ID', 'Name', 'Email', 'Points', 'Rank', 'Shares', 'Status', 'Registration Date', 'Last Activity', 'Is Admin'];
        const csvRows = [
          headers.join(','),
          ...usersToExport.map(user => [
            user.id,
            `"${user.name}"`,
            user.email,
            user.points,
            user.rank,
            user.sharesCount,
            user.status,
            user.registrationDate,
            user.lastActivity,
            user.isAdmin ? 'Yes' : 'No'
          ].join(','))
        ];

        const csvData = csvRows.join('\n');
        return new Blob([csvData], { type: 'text/csv' });
      }
    }

    const params = new URLSearchParams();
    params.append('format', format);
    if (filters?.search) params.append('search', filters.search);
    if (filters?.minPoints) params.append('min_points', filters.minPoints.toString());
    if (filters?.status) params.append('status', filters.status);
    if (filters?.dateRange) {
      params.append('start_date', filters.dateRange.start);
      params.append('end_date', filters.dateRange.end);
    }

    const response = await fetch(`${apiClient['baseURL']}/users/export?${params}`, {
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('authToken')}`
      }
    });

    if (!response.ok) {
      throw new Error('Export failed');
    }

    return response.blob();
  }

  /**
   * Get user details by ID
   */
  async getUserById(userId: number): Promise<any> {
    if (MOCK_MODE) {
      await mockDelay();
      
      const user = mockUsers.find(u => u.id === userId);
      if (!user) {
        throw new Error('User not found');
      }
      
      return {
        user_id: user.id,
        name: user.name,
        email: user.email,
        points: user.points,
        rank: user.rank,
        shares_count: user.sharesCount,
        status: user.status,
        last_activity: user.lastActivity,
        created_at: user.registrationDate,
        is_admin: user.isAdmin
      };
    }

    return withErrorHandling(() => 
      apiClient.get(`/admin/users/${userId}`)
    );
  }

  /**
   * Update user status (activate/deactivate)
   */
  async updateUserStatus(userId: number, status: 'active' | 'inactive'): Promise<{ message: string }> {
    if (MOCK_MODE) {
      await mockDelay();
      
      const user = mockUsers.find(u => u.id === userId);
      if (!user) {
        throw new Error('User not found');
      }
      
      user.status = status;
      
      return {
        message: `User ${user.name} ${status === 'active' ? 'activated' : 'deactivated'} successfully`
      };
    }

    return withErrorHandling(() => 
      apiClient.put(`/admin/users/${userId}/status`, { status })
    );
  }

  /**
   * Get admin statistics summary
   */
  async getAdminStats(): Promise<{
    totalUsers: number;
    activeUsers: number;
    totalShares: number;
    totalPoints: number;
    topPlatform: string;
  }> {
    if (MOCK_MODE) {
      await mockDelay(200);
      
      const activeUsers = mockUsers.filter(u => u.status === 'active').length;
      const totalShares = mockUsers.reduce((sum, u) => sum + u.sharesCount, 0);
      const totalPoints = mockUsers.reduce((sum, u) => sum + u.points, 0);
      
      // Find top platform
      const platformShares = Object.entries(mockAnalytics.platformBreakdown);
      const topPlatform = platformShares.reduce((top, [platform, data]) => 
        data.shares > (mockAnalytics.platformBreakdown[top]?.shares || 0) ? platform : top
      , 'linkedin');

      return {
        totalUsers: mockUsers.length,
        activeUsers,
        totalShares,
        totalPoints,
        topPlatform
      };
    }

    const dashboard = await this.getDashboard();
    
    return {
      totalUsers: dashboard.overview.total_users,
      activeUsers: dashboard.overview.active_users_24h,
      totalShares: dashboard.overview.total_shares_today,
      totalPoints: dashboard.overview.points_distributed_today,
      topPlatform: Object.entries(dashboard.platform_breakdown)
        .reduce((top, [platform, data]) => 
          data.shares > (dashboard.platform_breakdown[top[0]]?.shares || 0) ? [platform, data] : top
        , ['', { shares: 0, percentage: 0 }])[0]
    };
  }
}

// Export singleton instance
export const adminService = new AdminService();
export default adminService;
