// Campaign management service for handling email campaigns

import { apiClient, withErrorHandling, MOCK_MODE, mockDelay } from './api';
import { 
  CampaignScheduleResponse, 
  CampaignSendRequest, 
  CampaignSendResponse, 
  CampaignInfo,
  NewUserCampaignsResponse 
} from '../types/api';

class CampaignService {
  // Mock campaign data for development
  private readonly MOCK_CAMPAIGNS = {
    welcome: {
      subject: "✨ Welcome Aboard, LawVriksh Founding Member!",
      schedule: "instant",
      status: "active"
    },
    search_engine: {
      subject: "🔍 Your Search Engine is Ready!",
      schedule: "2025-07-26T14:00:00+05:30",
      status: "scheduled"
    },
    portfolio_builder: {
      subject: "📁 Portfolio Builder Complete!",
      schedule: "2025-07-30T10:30:00+05:30", 
      status: "scheduled"
    },
    platform_complete: {
      subject: "🚀 LawVriksh Platform Launch!",
      schedule: "2025-08-03T09:00:00+05:30",
      status: "scheduled"
    }
  };

  /**
   * Get campaign schedule overview
   */
  async getCampaignSchedule(): Promise<CampaignScheduleResponse> {
    if (MOCK_MODE) {
      await mockDelay();
      
      const currentTime = new Date().toISOString();
      const dueCampaigns = Object.entries(this.MOCK_CAMPAIGNS)
        .filter(([_, campaign]) => {
          if (campaign.schedule === 'instant') return false;
          return new Date(campaign.schedule) <= new Date();
        })
        .map(([type, _]) => type);

      return {
        campaigns: this.MOCK_CAMPAIGNS,
        current_time: currentTime,
        due_campaigns: dueCampaigns
      };
    }

    return withErrorHandling(() => 
      apiClient.get<CampaignScheduleResponse>('/campaigns/schedule')
    );
  }

  /**
   * Send campaign manually
   */
  async sendCampaign(request: CampaignSendRequest): Promise<CampaignSendResponse> {
    if (MOCK_MODE) {
      await mockDelay(1000); // Longer delay for sending
      
      const campaign = this.MOCK_CAMPAIGNS[request.campaign_type as keyof typeof this.MOCK_CAMPAIGNS];
      if (!campaign) {
        throw new Error(`Invalid campaign type: ${request.campaign_type}`);
      }

      const mockTaskId = 'mock-task-' + Date.now();
      
      if (request.user_email && request.user_name) {
        return {
          success: true,
          message: `Campaign '${request.campaign_type}' queued for ${request.user_email}`,
          task_id: mockTaskId,
          details: {
            campaign_type: request.campaign_type,
            recipient: request.user_email,
            send_type: 'individual'
          }
        };
      } else {
        return {
          success: true,
          message: `Bulk campaign '${request.campaign_type}' queued for all users`,
          task_id: mockTaskId,
          details: {
            campaign_type: request.campaign_type,
            send_type: 'bulk'
          }
        };
      }
    }

    return withErrorHandling(() => 
      apiClient.post<CampaignSendResponse>('/campaigns/send', request)
    );
  }

  /**
   * Get campaign status
   */
  async getCampaignStatus(campaignType: string): Promise<CampaignInfo> {
    if (MOCK_MODE) {
      await mockDelay();
      
      const campaign = this.MOCK_CAMPAIGNS[campaignType as keyof typeof this.MOCK_CAMPAIGNS];
      if (!campaign) {
        throw new Error(`Invalid campaign type: ${campaignType}`);
      }

      const currentTime = new Date();
      const scheduleTime = campaign.schedule === 'instant' ? currentTime : new Date(campaign.schedule);
      const isDue = campaign.schedule === 'instant' || currentTime >= scheduleTime;

      return {
        campaign_type: campaignType,
        subject: campaign.subject,
        schedule: campaign.schedule,
        status: campaign.status,
        is_due: isDue,
        current_time: currentTime.toISOString()
      };
    }

    return withErrorHandling(() => 
      apiClient.get<CampaignInfo>(`/campaigns/status/${campaignType}`)
    );
  }

  /**
   * Send test campaign to Sahil
   */
  async sendTestCampaign(campaignType: string = 'welcome'): Promise<CampaignSendResponse> {
    if (MOCK_MODE) {
      await mockDelay(800);
      
      const campaign = this.MOCK_CAMPAIGNS[campaignType as keyof typeof this.MOCK_CAMPAIGNS];
      if (!campaign) {
        throw new Error(`Invalid campaign type: ${campaignType}`);
      }

      return {
        success: true,
        message: `Test campaign '${campaignType}' sent to Sahil Saurav`,
        task_id: 'mock-test-task-' + Date.now(),
        details: {
          campaign_type: campaignType,
          recipient: 'sahilsaurav2507@gmail.com',
          send_type: 'individual'
        }
      };
    }

    return withErrorHandling(() => 
      apiClient.post<CampaignSendResponse>('/campaigns/test-sahil', { campaign_type: campaignType })
    );
  }

  /**
   * Preview campaigns for new users
   */
  async getNewUserCampaignsPreview(): Promise<NewUserCampaignsResponse> {
    if (MOCK_MODE) {
      await mockDelay();
      
      const currentTime = new Date();
      const futureCampaigns = Object.entries(this.MOCK_CAMPAIGNS)
        .filter(([type, campaign]) => {
          if (type === 'welcome' || campaign.schedule === 'instant') return false;
          return new Date(campaign.schedule) > currentTime;
        })
        .map(([type, campaign]) => {
          const scheduleDate = new Date(campaign.schedule);
          const daysFromNow = Math.ceil((scheduleDate.getTime() - currentTime.getTime()) / (1000 * 60 * 60 * 24));
          
          return {
            campaign_type: type,
            subject: campaign.subject,
            schedule: campaign.schedule,
            days_from_now: daysFromNow
          };
        });

      const pastCampaigns = Object.entries(this.MOCK_CAMPAIGNS)
        .filter(([type, campaign]) => {
          if (type === 'welcome' || campaign.schedule === 'instant') return false;
          return new Date(campaign.schedule) <= currentTime;
        })
        .map(([type, _]) => type);

      return {
        instant_email: {
          campaign_type: 'welcome',
          subject: this.MOCK_CAMPAIGNS.welcome.subject,
          will_be_sent: true,
          note: 'Always sent immediately on registration'
        },
        future_campaigns: {
          count: futureCampaigns.length,
          campaigns: futureCampaigns,
          note: 'These will be sent automatically on scheduled dates'
        },
        past_campaigns: {
          count: pastCampaigns.length,
          campaigns: pastCampaigns,
          note: 'These will NOT be sent to new users (backdated)'
        },
        current_time: currentTime.toISOString()
      };
    }

    return withErrorHandling(() =>
      apiClient.get<NewUserCampaignsResponse>('/campaigns/new-user-campaigns')
    );
  }

  /**
   * Get available campaign types
   */
  getCampaignTypes(): string[] {
    return Object.keys(this.MOCK_CAMPAIGNS);
  }

  /**
   * Format campaign schedule for display
   */
  formatSchedule(schedule: string): string {
    if (schedule === 'instant') {
      return 'Instant (on registration)';
    }
    
    try {
      const date = new Date(schedule);
      return date.toLocaleString('en-IN', {
        timeZone: 'Asia/Kolkata',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true
      }) + ' IST';
    } catch {
      return schedule;
    }
  }

  /**
   * Check if campaign is due
   */
  isCampaignDue(schedule: string): boolean {
    if (schedule === 'instant') return true;
    
    try {
      return new Date(schedule) <= new Date();
    } catch {
      return false;
    }
  }

  /**
   * Get campaign status badge color
   */
  getStatusColor(status: string, isDue: boolean): string {
    switch (status) {
      case 'active':
        return isDue ? 'bg-green-100 text-green-800' : 'bg-blue-100 text-blue-800';
      case 'scheduled':
        return isDue ? 'bg-orange-100 text-orange-800' : 'bg-gray-100 text-gray-800';
      case 'completed':
        return 'bg-green-100 text-green-800';
      case 'failed':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  }
}

// Export singleton instance
export const campaignService = new CampaignService();
export default campaignService;
