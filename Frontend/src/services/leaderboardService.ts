// Leaderboard service for rankings and user statistics

import { apiClient, withErrorHandling, MOCK_MODE, mockDelay } from './api';
import { 
  LeaderboardResponse, 
  AroundMeResponse, 
  TopPerformersResponse,
  PaginationParams 
} from '../types/api';
import { mockUsers } from './mockData';

class LeaderboardService {
  /**
   * Get public leaderboard with pagination
   */
  async getLeaderboard(params: PaginationParams): Promise<LeaderboardResponse> {
    if (MOCK_MODE) {
      await mockDelay();

      const { page = 1, limit = 50 } = params;

      // Sort users by points (descending) and assign ranks
      const sortedUsers = [...mockUsers]
        .sort((a, b) => b.points - a.points)
        .map((user, index) => ({
          rank: index + 1,
          user_id: user.id,
          name: user.name,
          points: user.points,
          shares_count: user.sharesCount
        }));

      // Apply pagination
      const startIndex = (page - 1) * limit;
      const endIndex = startIndex + limit;
      const paginatedUsers = sortedUsers.slice(startIndex, endIndex);

      return {
        leaderboard: paginatedUsers,
        pagination: {
          page,
          limit,
          total: sortedUsers.length,
          pages: Math.ceil(sortedUsers.length / limit)
        },
        metadata: {
          total_users: sortedUsers.length,
          your_rank: undefined, // No user context for public endpoint
          your_points: 0
        }
      };
    }

    try {
      return await withErrorHandling(() =>
        apiClient.get<LeaderboardResponse>('/leaderboard', params)
      );
    } catch (error) {
      // Return empty leaderboard on error
      return {
        leaderboard: [],
        pagination: {
          page: params.page || 1,
          limit: params.limit || 50,
          total: 0,
          pages: 0
        },
        metadata: {
          total_users: 0,
          your_rank: undefined,
          your_points: 0
        }
      };
    }
  }

  /**
   * Get leaderboard around current user's position
   */
  async getAroundMe(range: number = 5): Promise<AroundMeResponse> {
    if (MOCK_MODE) {
      await mockDelay();

      const userData = localStorage.getItem('userData');
      if (!userData) {
        throw new Error('User not authenticated');
      }

      const currentUser = JSON.parse(userData);

      // Sort all users by points
      const sortedUsers = [...mockUsers]
        .sort((a, b) => b.points - a.points)
        .map((user, index) => ({
          ...user,
          rank: index + 1
        }));

      // Find current user's rank (mock: assign a random rank)
      const userRank = Math.floor(Math.random() * 50) + 200; // Random rank between 200-250
      const userIndex = userRank - 1;

      // Get surrounding users
      const startIndex = Math.max(0, userIndex - range);
      const endIndex = Math.min(sortedUsers.length, userIndex + range + 1);

      const surroundingUsers = sortedUsers.slice(startIndex, endIndex).map((user, index) => ({
        rank: startIndex + index + 1,
        name: user.name,
        points: user.points,
        is_current_user: user.id === currentUser.user_id
      }));

      // Calculate stats
      const pointsToNextRank = userIndex > 0 ?
        sortedUsers[userIndex - 1].points - currentUser.total_points : 0;

      const percentile = 100.0 * (1 - (userRank - 1) / sortedUsers.length);

      return {
        surrounding_users: surroundingUsers,
        your_stats: {
          rank: userRank,
          points: currentUser.total_points,
          points_to_next_rank: pointsToNextRank,
          percentile: Math.round(percentile * 10) / 10
        }
      };
    }

    try {
      return await withErrorHandling(() =>
        apiClient.get<AroundMeResponse>('/leaderboard/around-me', { range })
      );
    } catch (error) {
      throw error;
    }
  }

  /**
   * Get top performers for a specific period
   */
  async getTopPerformers(
    period: 'daily' | 'weekly' | 'monthly' | 'all-time' = 'weekly',
    limit: number = 10
  ): Promise<TopPerformersResponse> {
    if (MOCK_MODE) {
      await mockDelay();
      
      // Get top users
      const topUsers = [...mockUsers]
        .sort((a, b) => b.points - a.points)
        .slice(0, limit)
        .map((user, index) => ({
          rank: index + 1,
          user_id: user.id,
          name: user.name,
          points_gained: user.points, // For now, same as total points
          total_points: user.points,
          growth_rate: `${Math.floor(Math.random() * 50) + 10}%` // Mock growth rate
        }));

      const totalPoints = topUsers.reduce((sum, user) => sum + user.total_points, 0);
      
      // Mock period dates
      const endDate = new Date();
      const startDate = new Date();
      
      switch (period) {
        case 'daily':
          startDate.setDate(endDate.getDate() - 1);
          break;
        case 'weekly':
          startDate.setDate(endDate.getDate() - 7);
          break;
        case 'monthly':
          startDate.setMonth(endDate.getMonth() - 1);
          break;
        case 'all-time':
          startDate.setFullYear(2020); // Arbitrary start date
          break;
      }

      return {
        period,
        top_performers: topUsers,
        period_stats: {
          start_date: startDate.toISOString().split('T')[0],
          end_date: endDate.toISOString().split('T')[0],
          total_points_awarded: totalPoints,
          active_users: topUsers.length
        }
      };
    }

    return withErrorHandling(() => 
      apiClient.get<TopPerformersResponse>('/leaderboard/top-performers', { period, limit })
    );
  }

  /**
   * Get current user's rank
   */
  async getUserRank(): Promise<number | null> {
    if (MOCK_MODE) {
      await mockDelay(200);
      
      const userData = localStorage.getItem('userData');
      if (!userData) {
        return null;
      }

      // Return mock rank
      return Math.floor(Math.random() * 50) + 200;
    }

    try {
      const response = await this.getAroundMe(0);
      return response.your_stats.rank || null;
    } catch {
      return null;
    }
  }

  /**
   * Get user's position relative to others
   */
  async getUserStats(): Promise<AroundMeResponse['your_stats'] | null> {
    if (MOCK_MODE) {
      const userData = localStorage.getItem('userData');
      if (!userData) {
        return null;
      }

      const currentUser = JSON.parse(userData);
      const rank = await this.getUserRank();
      
      return {
        rank: rank ?? undefined,
        points: currentUser.total_points,
        points_to_next_rank: Math.floor(Math.random() * 500) + 100,
        percentile: Math.floor(Math.random() * 40) + 60 // 60-100%
      };
    }

    try {
      const response = await this.getAroundMe(0);
      return response.your_stats;
    } catch {
      return null;
    }
  }

  /**
   * Get leaderboard summary for dashboard
   */
  async getLeaderboardSummary(): Promise<{
    totalUsers: number;
    topUser: { name: string; points: number } | null;
    userRank: number | null;
    userPercentile: number | null;
  }> {
    if (MOCK_MODE) {
      await mockDelay(200);
      
      const topUsers = [...mockUsers].sort((a, b) => b.points - a.points);
      const userStats = await this.getUserStats();
      
      return {
        totalUsers: mockUsers.length,
        topUser: topUsers.length > 0 ? {
          name: topUsers[0].name,
          points: topUsers[0].points
        } : null,
        userRank: userStats?.rank || null,
        userPercentile: userStats?.percentile || null
      };
    }

    try {
      const [leaderboard, userStats] = await Promise.all([
        this.getLeaderboard({ page: 1, limit: 1 }),
        this.getUserStats()
      ]);

      return {
        totalUsers: leaderboard.metadata.total_users,
        topUser: leaderboard.leaderboard.length > 0 ? {
          name: leaderboard.leaderboard[0].name,
          points: leaderboard.leaderboard[0].points
        } : null,
        userRank: userStats?.rank || null,
        userPercentile: userStats?.percentile || null
      };
    } catch {
      return {
        totalUsers: 0,
        topUser: null,
        userRank: null,
        userPercentile: null
      };
    }
  }
}

// Export singleton instance
export const leaderboardService = new LeaderboardService();
export default leaderboardService;
