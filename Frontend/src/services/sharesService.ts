// Shares service for handling social media sharing and analytics

import { apiClient, withErrorHandling, MOCK_MODE, mockDelay } from './api';
import {
  PlatformType,
  ShareResponse,
  ShareHistoryResponse,
  ShareAnalyticsResponse,
  ShareAnalyticsEnhanced,
  PaginationParams
} from '../types/api';

class SharesService {
  // Mock data for shares
  private mockShares: Array<{
    id: number;
    platform: PlatformType;
    points_earned: number;
    timestamp: string;
  }> = [];

  private mockUserShares: Set<PlatformType> = new Set();

  /**
   * Record a share event on specified platform
   */
  async recordShare(platform: PlatformType): Promise<ShareResponse> {
    if (MOCK_MODE) {
      await mockDelay();

      const userData = localStorage.getItem('userData');
      if (!userData) {
        throw new Error('User not authenticated');
      }

      const user = JSON.parse(userData);
      const shareId = this.mockShares.length + 1;
      const timestamp = new Date().toISOString();

      // Check if user already shared on this platform
      const alreadyShared = this.mockUserShares.has(platform);
      const pointsEarned = alreadyShared ? 0 : 50; // 50 points for first share per platform

      if (!alreadyShared) {
        this.mockUserShares.add(platform);

        // Update user points
        user.total_points += pointsEarned;
        user.shares_count += 1;
        localStorage.setItem('userData', JSON.stringify(user));

        // Add to mock shares history
        this.mockShares.push({
          id: shareId,
          platform,
          points_earned: pointsEarned,
          timestamp
        });
      }

      return {
        share_id: alreadyShared ? undefined : shareId,
        user_id: user.user_id,
        platform,
        points_earned: pointsEarned,
        total_points: user.total_points,
        new_rank: undefined, // Would be calculated by backend
        timestamp,
        message: alreadyShared
          ? 'You have already shared on this platform. No additional points awarded.'
          : `Share recorded successfully! You earned ${pointsEarned} points.`
      };
    }

    try {
      const response = await withErrorHandling(() =>
        apiClient.post<ShareResponse>(`/shares/${platform}`)
      );

      // Update local user data with new points and shares count
      const userData = localStorage.getItem('userData');
      if (userData && response.total_points) {
        const user = JSON.parse(userData);
        user.total_points = response.total_points;
        if (response.points_earned > 0) {
          user.shares_count = (user.shares_count || 0) + 1;
        }
        localStorage.setItem('userData', JSON.stringify(user));
      }

      return response;
    } catch (error) {
      console.error('Failed to record share:', error);
      throw error;
    }
  }

  /**
   * Get user's share history with pagination
   */
  async getShareHistory(
    params: PaginationParams & { platform?: PlatformType }
  ): Promise<ShareHistoryResponse> {
    if (MOCK_MODE) {
      await mockDelay();

      const { page = 1, limit = 20, platform } = params;

      // Filter by platform if specified
      let filteredShares = this.mockShares;
      if (platform) {
        filteredShares = this.mockShares.filter(share => share.platform === platform);
      }

      // Apply pagination
      const startIndex = (page - 1) * limit;
      const endIndex = startIndex + limit;
      const paginatedShares = filteredShares.slice(startIndex, endIndex);

      return {
        shares: paginatedShares.map(share => ({
          share_id: share.id,
          platform: share.platform,
          points_earned: share.points_earned,
          timestamp: share.timestamp
        })),
        pagination: {
          page,
          limit,
          total: filteredShares.length,
          pages: Math.ceil(filteredShares.length / limit)
        }
      };
    }

    try {
      return await withErrorHandling(() =>
        apiClient.get<ShareHistoryResponse>('/shares/history', params)
      );
    } catch (error) {
      console.error('Failed to fetch share history:', error);
      // Return empty history on error
      return {
        shares: [],
        pagination: {
          page: params.page || 1,
          limit: params.limit || 20,
          total: 0,
          pages: 0
        }
      };
    }
  }

  /**
   * Get user's sharing analytics
   */
  async getShareAnalytics(): Promise<ShareAnalyticsResponse> {
    if (MOCK_MODE) {
      await mockDelay();

      // Calculate analytics from mock data
      const platformBreakdown: { [key: string]: { shares: number; points: number } } = {};

      // Initialize all platforms
      const platforms: PlatformType[] = ['facebook', 'twitter', 'linkedin', 'instagram', 'whatsapp'];
      platforms.forEach(platform => {
        platformBreakdown[platform] = { shares: 0, points: 0 };
      });

      // Calculate from mock shares
      this.mockShares.forEach(share => {
        if (platformBreakdown[share.platform]) {
          platformBreakdown[share.platform].shares += 1;
          platformBreakdown[share.platform].points += share.points_earned;
        }
      });

      // Get recent activity (last 5 shares)
      const recentShares = this.mockShares
        .slice(-5)
        .reverse()
        .map(share => ({
          platform: share.platform,
          points: share.points_earned.toString(),
          timestamp: share.timestamp
        }));

      return {
        total_shares: this.mockShares.length,
        points_breakdown: platformBreakdown,
        recent_activity: recentShares
      };
    }

    return withErrorHandling(() =>
      apiClient.get<ShareAnalyticsResponse>('/shares/analytics')
    );
  }

  /**
   * Get enhanced sharing analytics with detailed breakdown
   */
  async getEnhancedAnalytics(): Promise<ShareAnalyticsEnhanced> {
    return withErrorHandling(() =>
      apiClient.get<ShareAnalyticsEnhanced>('/shares/analytics/enhanced')
    );
  }

  /**
   * Get available sharing platforms
   */
  getAvailablePlatforms(): PlatformType[] {
    return ['facebook', 'twitter', 'linkedin', 'instagram', 'whatsapp'];
  }

  /**
   * Get platform-specific sharing URL
   */
  getShareUrl(platform: PlatformType, content?: string): string {
    const baseUrl = window.location.origin;
    const text = content || 'Check out LawVriksh - the ultimate platform for legal professionals!';
    const url = `${baseUrl}?ref=share`;
    
    const shareUrls = {
      facebook: `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(url)}`,
      twitter: `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(url)}`,
      linkedin: `https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(url)}`,
      instagram: `https://www.instagram.com/`, // Instagram doesn't support direct URL sharing
      whatsapp: `https://wa.me/?text=${encodeURIComponent(`${text} ${url}`)}`
    };
    
    return shareUrls[platform];
  }



  /**
   * Check if user has shared on specific platform
   */
  hasSharedOnPlatform(platform: PlatformType): boolean {
    if (MOCK_MODE) {
      return this.mockUserShares.has(platform);
    }
    
    // This would typically be determined by the backend
    // For now, return false to allow sharing
    return false;
  }

  /**
   * Get points earned for sharing on platform
   */
  getPointsForPlatform(platform: PlatformType): number {
    // Standard points per platform (first share only)
    const platformPoints = {
      facebook: 50,
      twitter: 50,
      linkedin: 75, // Higher points for professional platform
      instagram: 40,
      whatsapp: 30
    };

    return platformPoints[platform] || 50;
  }

  /**
   * Open native share dialog for the specified platform
   */
  openShareDialog(platform: PlatformType, message: string): void {
    const encodedMessage = encodeURIComponent(message);
    const url = encodeURIComponent(window.location.origin);

    let shareUrl = '';

    switch (platform) {
      case 'facebook':
        shareUrl = `https://www.facebook.com/sharer/sharer.php?u=${url}&quote=${encodedMessage}`;
        break;
      case 'twitter':
        shareUrl = `https://twitter.com/intent/tweet?text=${encodedMessage}&url=${url}`;
        break;
      case 'linkedin':
        shareUrl = `https://www.linkedin.com/sharing/share-offsite/?url=${url}&summary=${encodedMessage}`;
        break;
      case 'whatsapp':
        shareUrl = `https://wa.me/?text=${encodedMessage}%20${url}`;
        break;
      case 'instagram':
        // Instagram doesn't support direct sharing via URL, so we'll copy to clipboard
        navigator.clipboard.writeText(`${message} ${window.location.origin}`).then(() => {
          alert('Message copied to clipboard! You can now paste it on Instagram.');
        }).catch(() => {
          alert('Please copy this message and share on Instagram: ' + message);
        });
        return;
      default:
        console.warn(`Unsupported platform: ${platform}`);
        return;
    }

    // Open share dialog in a new window
    const width = 600;
    const height = 400;
    const left = (window.innerWidth - width) / 2;
    const top = (window.innerHeight - height) / 2;

    window.open(
      shareUrl,
      'share-dialog',
      `width=${width},height=${height},left=${left},top=${top},resizable=yes,scrollbars=yes`
    );
  }
}

// Export singleton instance
export const sharesService = new SharesService();
export default sharesService;
