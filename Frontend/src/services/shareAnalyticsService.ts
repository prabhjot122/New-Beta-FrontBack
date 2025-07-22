// Enhanced share analytics and history service

import { apiClient, withErrorHandling, MOCK_MODE, mockDelay } from './api';
import {
  ShareHistoryEnhanced,
  ShareAnalyticsEnhanced,
  ShareHistoryItem,
  // PaginationParams
} from '../types/api';

class ShareAnalyticsService {
  // Mock share data for development
  private readonly MOCK_SHARE_HISTORY: ShareHistoryItem[] = [
    {
      share_id: 1,
      platform: 'linkedin',
      points_earned: 5,
      timestamp: '2024-01-15T10:30:00Z'
    },
    {
      share_id: 2,
      platform: 'facebook',
      points_earned: 3,
      timestamp: '2024-01-14T15:45:00Z'
    },
    {
      share_id: 3,
      platform: 'twitter',
      points_earned: 1,
      timestamp: '2024-01-13T09:20:00Z'
    },
    {
      share_id: 4,
      platform: 'instagram',
      points_earned: 2,
      timestamp: '2024-01-12T14:15:00Z'
    },
    {
      share_id: 5,
      platform: 'linkedin',
      points_earned: 0, // Duplicate share
      timestamp: '2024-01-11T11:30:00Z'
    }
  ];

  private readonly MOCK_ANALYTICS: ShareAnalyticsEnhanced = {
    platform_breakdown: {
      linkedin: {
        shares: 2,
        points: 5,
        percentage: 45.5,
        first_share_date: '2024-01-11T11:30:00Z',
        last_share_date: '2024-01-15T10:30:00Z'
      },
      facebook: {
        shares: 1,
        points: 3,
        percentage: 27.3,
        first_share_date: '2024-01-14T15:45:00Z',
        last_share_date: '2024-01-14T15:45:00Z'
      },
      twitter: {
        shares: 1,
        points: 1,
        percentage: 9.1,
        first_share_date: '2024-01-13T09:20:00Z',
        last_share_date: '2024-01-13T09:20:00Z'
      },
      instagram: {
        shares: 1,
        points: 2,
        percentage: 18.2,
        first_share_date: '2024-01-12T14:15:00Z',
        last_share_date: '2024-01-12T14:15:00Z'
      }
    },
    timeline: [
      { date: '2024-01-11', shares: 1, points: 0 },
      { date: '2024-01-12', shares: 1, points: 2 },
      { date: '2024-01-13', shares: 1, points: 1 },
      { date: '2024-01-14', shares: 1, points: 3 },
      { date: '2024-01-15', shares: 1, points: 5 }
    ],
    summary: {
      total_shares: 5,
      total_points: 11,
      active_platforms: 4,
      average_points_per_share: 2.2
    }
  };

  /**
   * Get user share history with pagination
   */
  async getShareHistory(params: {
    page?: number;
    limit?: number;
    platform?: string;
    dateRange?: {
      start: string;
      end: string;
    };
  } = {}): Promise<ShareHistoryEnhanced> {
    if (MOCK_MODE) {
      await mockDelay();
      
      const { page = 1, limit = 20, platform, dateRange } = params;
      
      // Filter shares
      let filteredShares = [...this.MOCK_SHARE_HISTORY];
      
      if (platform) {
        filteredShares = filteredShares.filter(share => share.platform === platform);
      }
      
      if (dateRange) {
        const startDate = new Date(dateRange.start);
        const endDate = new Date(dateRange.end);
        filteredShares = filteredShares.filter(share => {
          const shareDate = new Date(share.timestamp);
          return shareDate >= startDate && shareDate <= endDate;
        });
      }
      
      // Sort by timestamp (newest first)
      filteredShares.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
      
      // Apply pagination
      const startIndex = (page - 1) * limit;
      const endIndex = startIndex + limit;
      const paginatedShares = filteredShares.slice(startIndex, endIndex);
      
      // Calculate summary
      const totalPointsEarned = filteredShares.reduce((sum, share) => sum + share.points_earned, 0);
      const platformsUsed = [...new Set(filteredShares.map(share => share.platform))];
      
      return {
        shares: paginatedShares,
        pagination: {
          page,
          limit,
          total: filteredShares.length,
          pages: Math.ceil(filteredShares.length / limit)
        },
        summary: {
          total_shares: filteredShares.length,
          total_points_earned: totalPointsEarned,
          platforms_used: platformsUsed
        }
      };
    }

    const queryParams = new URLSearchParams();
    if (params.page) queryParams.append('page', params.page.toString());
    if (params.limit) queryParams.append('limit', params.limit.toString());
    if (params.platform) queryParams.append('platform', params.platform);
    if (params.dateRange) {
      queryParams.append('start_date', params.dateRange.start);
      queryParams.append('end_date', params.dateRange.end);
    }

    return withErrorHandling(() =>
      apiClient.get<ShareHistoryEnhanced>(`/shares/history?${queryParams}`)
    );
  }

  /**
   * Get enhanced share analytics
   */
  async getShareAnalytics(params: {
    period?: 'week' | 'month' | 'quarter' | 'year' | 'all';
    platform?: string;
  } = {}): Promise<ShareAnalyticsEnhanced> {
    if (MOCK_MODE) {
      await mockDelay();
      
      // Filter analytics based on parameters
      let analytics = { ...this.MOCK_ANALYTICS };
      
      if (params.platform) {
        // Filter to specific platform
        const platformData = analytics.platform_breakdown[params.platform];
        if (platformData) {
          analytics.platform_breakdown = { [params.platform]: platformData };
          analytics.summary = {
            total_shares: platformData.shares,
            total_points: platformData.points,
            active_platforms: 1,
            average_points_per_share: platformData.points / platformData.shares
          };
        }
      }
      
      return analytics;
    }

    const queryParams = new URLSearchParams();
    if (params.period) queryParams.append('period', params.period);
    if (params.platform) queryParams.append('platform', params.platform);

    return withErrorHandling(() => 
      apiClient.get<ShareAnalyticsEnhanced>(`/shares/analytics?${queryParams}`)
    );
  }

  /**
   * Get available platforms
   */
  async getAvailablePlatforms(): Promise<string[]> {
    if (MOCK_MODE) {
      await mockDelay(200);
      return ['facebook', 'twitter', 'linkedin', 'instagram', 'whatsapp'];
    }

    return withErrorHandling(() => 
      apiClient.get<string[]>('/shares/platforms')
    );
  }

  /**
   * Get platform statistics for admin
   */
  async getPlatformStatistics(): Promise<{
    [platform: string]: {
      total_shares: number;
      total_points: number;
      unique_users: number;
      average_points_per_user: number;
    };
  }> {
    if (MOCK_MODE) {
      await mockDelay();
      
      return {
        linkedin: {
          total_shares: 150,
          total_points: 750,
          unique_users: 120,
          average_points_per_user: 6.25
        },
        facebook: {
          total_shares: 200,
          total_points: 600,
          unique_users: 180,
          average_points_per_user: 3.33
        },
        twitter: {
          total_shares: 300,
          total_points: 300,
          unique_users: 250,
          average_points_per_user: 1.2
        },
        instagram: {
          total_shares: 100,
          total_points: 200,
          unique_users: 90,
          average_points_per_user: 2.22
        },
        whatsapp: {
          total_shares: 50,
          total_points: 0, // No points for WhatsApp
          unique_users: 45,
          average_points_per_user: 0
        }
      };
    }

    return withErrorHandling(() => 
      apiClient.get('/admin/platform-statistics')
    );
  }

  /**
   * Get share trends over time
   */
  async getShareTrends(params: {
    period: 'daily' | 'weekly' | 'monthly';
    days?: number;
  }): Promise<{
    labels: string[];
    datasets: {
      platform: string;
      data: number[];
      color: string;
    }[];
  }> {
    if (MOCK_MODE) {
      await mockDelay();
      
      const { period, days = 30 } = params;
      
      // Generate mock trend data
      const labels: string[] = [];
      const now = new Date();
      
      for (let i = days - 1; i >= 0; i--) {
        const date = new Date(now);
        date.setDate(date.getDate() - i);
        
        if (period === 'daily') {
          labels.push(date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }));
        } else if (period === 'weekly') {
          labels.push(`Week ${Math.ceil(date.getDate() / 7)}`);
        } else {
          labels.push(date.toLocaleDateString('en-US', { month: 'short' }));
        }
      }
      
      const platforms = ['linkedin', 'facebook', 'twitter', 'instagram'];
      const colors = ['#0077B5', '#1877F2', '#1DA1F2', '#E4405F'];
      
      const datasets = platforms.map((platform, index) => ({
        platform,
        data: labels.map(() => Math.floor(Math.random() * 20) + 1),
        color: colors[index]
      }));
      
      return { labels, datasets };
    }

    const queryParams = new URLSearchParams();
    queryParams.append('period', params.period);
    if (params.days) queryParams.append('days', params.days.toString());

    return withErrorHandling(() => 
      apiClient.get(`/shares/trends?${queryParams}`)
    );
  }

  /**
   * Format platform name for display
   */
  formatPlatformName(platform: string): string {
    const platformNames: { [key: string]: string } = {
      facebook: 'Facebook',
      twitter: 'Twitter',
      linkedin: 'LinkedIn',
      instagram: 'Instagram',
      whatsapp: 'WhatsApp'
    };
    
    return platformNames[platform] || platform.charAt(0).toUpperCase() + platform.slice(1);
  }

  /**
   * Get platform color for charts
   */
  getPlatformColor(platform: string): string {
    const platformColors: { [key: string]: string } = {
      facebook: '#1877F2',
      twitter: '#1DA1F2',
      linkedin: '#0077B5',
      instagram: '#E4405F',
      whatsapp: '#25D366'
    };
    
    return platformColors[platform] || '#6B7280';
  }

  /**
   * Get platform icon
   */
  getPlatformIcon(platform: string): string {
    const platformIcons: { [key: string]: string } = {
      facebook: '📘',
      twitter: '🐦',
      linkedin: '💼',
      instagram: '📷',
      whatsapp: '💬'
    };
    
    return platformIcons[platform] || '📱';
  }

  /**
   * Calculate engagement metrics
   */
  calculateEngagementMetrics(analytics: ShareAnalyticsEnhanced) {
    const { platform_breakdown, summary } = analytics;

    // Check if required data exists
    if (!platform_breakdown || !summary) {
      return {
        mostActivePlatform: { name: '', shares: 0 },
        highestEarningPlatform: { name: '', points: 0 },
        mostEfficientPlatform: { platform: '', efficiency: 0 },
        totalEngagement: 0,
        averagePointsPerShare: 0
      };
    }

    const platformEntries = Object.entries(platform_breakdown);

    // If no platform data, return empty metrics
    if (platformEntries.length === 0) {
      return {
        mostActivePlatform: { name: '', shares: 0 },
        highestEarningPlatform: { name: '', points: 0 },
        mostEfficientPlatform: { platform: '', efficiency: 0 },
        totalEngagement: summary.total_shares || 0,
        averagePointsPerShare: summary.average_points_per_share || 0
      };
    }

    // Find most active platform
    const mostActivePlatform = platformEntries
      .reduce((max, [platform, data]) =>
        data.shares > (platform_breakdown[max[0]]?.shares || 0) ? [platform, data] : max
      , ['', { shares: 0, points: 0, percentage: 0 }]);

    // Find highest earning platform
    const highestEarningPlatform = platformEntries
      .reduce((max, [platform, data]) =>
        data.points > (platform_breakdown[max[0]]?.points || 0) ? [platform, data] : max
      , ['', { shares: 0, points: 0, percentage: 0 }]);

    // Calculate efficiency (points per share)
    const platformEfficiency = platformEntries
      .map(([platform, data]) => ({
        platform,
        efficiency: data.shares > 0 ? data.points / data.shares : 0
      }))
      .sort((a, b) => b.efficiency - a.efficiency);

    return {
      mostActivePlatform: {
        name: mostActivePlatform[0],
        shares: mostActivePlatform[1].shares
      },
      highestEarningPlatform: {
        name: highestEarningPlatform[0],
        points: highestEarningPlatform[1].points
      },
      mostEfficientPlatform: platformEfficiency[0] || { platform: '', efficiency: 0 },
      totalEngagement: summary.total_shares || 0,
      averagePointsPerShare: summary.average_points_per_share || 0
    };
  }
}

// Export singleton instance
export const shareAnalyticsService = new ShareAnalyticsService();
export default shareAnalyticsService;
