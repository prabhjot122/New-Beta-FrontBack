// API Response Types and Interfaces matching backend schemas

// Base API Response
export interface ApiResponse<T = any> {
  data?: T;
  message?: string;
  error?: string;
  status: number;
}

// Pagination
export interface PaginationParams {
  page: number;
  limit: number;
  _t?: number; // Cache-busting timestamp
}

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  pages: number;
}

// User Types (matching backend user.py schema)
export interface UserCreate {
  name: string;
  email: string;
  password: string;
}

export interface UserLogin {
  email: string;
  password: string;
}

export interface UserResponse {
  user_id: number;
  name: string;
  email: string;
  created_at: string;
  total_points: number;
  shares_count: number;
  current_rank?: number;
  is_admin: boolean;
}

export interface UserProfileUpdate {
  name?: string;
  bio?: string;
}

// Authentication Types (matching backend token.py schema)
export interface Token {
  access_token: string;
  token_type: string;
  expires_in: number;
}

// Share Types (matching backend share.py schema)
export type PlatformType = 'facebook' | 'twitter' | 'linkedin' | 'instagram' | 'whatsapp';

export interface ShareResponse {
  share_id?: number;
  user_id: number;
  platform: string;
  points_earned: number;
  total_points: number;
  new_rank?: number;
  timestamp: string;
  message: string;
}

export interface ShareHistoryItem {
  share_id: number;
  platform: string;
  points_earned: number;
  timestamp: string;
}

export interface ShareHistoryResponse {
  shares: ShareHistoryItem[];
  pagination: PaginationMeta;
}

export interface ShareAnalyticsResponse {
  total_shares: number;
  points_breakdown: {
    [platform: string]: {
      shares: number;
      points: number;
    };
  };
  recent_activity?: Array<{
    platform: string;
    points: string;
    timestamp: string;
  }>;
}

// Leaderboard Types (matching backend leaderboard.py schema)
export interface LeaderboardUser {
  rank: number;
  user_id: number;
  name: string;
  points: number;
  shares_count: number;
}

export interface LeaderboardResponse {
  leaderboard: LeaderboardUser[];
  pagination: PaginationMeta;
  metadata: {
    total_users: number;
    your_rank?: number;
    your_points: number;
  };
}

export interface AroundMeUser {
  rank: number;
  name: string;
  points: number;
  is_current_user: boolean;
}

export interface AroundMeResponse {
  surrounding_users: AroundMeUser[];
  your_stats: {
    rank?: number;
    points: number;
    points_to_next_rank: number;
    percentile: number;
  };
}

export interface TopPerformer {
  rank: number;
  user_id: number;
  name: string;
  points_gained: number;
  total_points: number;
  growth_rate: string;
}

export interface TopPerformersResponse {
  period: string;
  top_performers: TopPerformer[];
  period_stats: {
    start_date: string;
    end_date: string;
    total_points_awarded: number;
    active_users: number;
  };
}

// Admin Types (matching backend admin.py schema)
export interface AdminUser {
  user_id: number;
  name: string;
  email: string;
  points: number;
  rank?: number;
  shares_count: number;
  status: 'active' | 'inactive';
  last_activity: string;
  created_at: string;
}

export interface AdminUsersResponse {
  users: AdminUser[];
  pagination: PaginationMeta;
}

export interface AdminDashboardResponse {
  overview: {
    total_users: number;
    active_users_24h: number;
    total_shares_today: number;
    points_distributed_today: number;
  };
  platform_breakdown: {
    [platform: string]: {
      shares: number;
      percentage: number;
    };
  };
  growth_metrics: {
    new_users_7d: number;
    user_retention_rate: number;
    average_session_duration: number;
  };
}

export interface BulkEmailRequest {
  subject: string;
  body: string;
  min_points: number;
}

export interface PromoteRequest {
  user_id: number;
}

// Campaign Management Types (matching backend campaigns.py schema)
export interface CampaignInfo {
  campaign_type: string;
  subject: string;
  schedule: string;
  status: string;
  is_due: boolean;
  current_time: string;
}

export interface CampaignScheduleResponse {
  campaigns: {
    [campaign_type: string]: {
      subject: string;
      schedule: string;
      status: string;
    };
  };
  current_time: string;
  due_campaigns: string[];
}

export interface CampaignSendRequest {
  campaign_type: string;
  user_email?: string;
  user_name?: string;
}

export interface CampaignSendResponse {
  success: boolean;
  message: string;
  task_id?: string;
  details?: {
    campaign_type: string;
    recipient?: string;
    send_type: 'individual' | 'bulk';
  };
}

export interface NewUserCampaignsResponse {
  instant_email: {
    campaign_type: string;
    subject: string;
    will_be_sent: boolean;
    note: string;
  };
  future_campaigns: {
    count: number;
    campaigns: Array<{
      campaign_type: string;
      subject: string;
      schedule: string;
      days_from_now: number;
    }>;
    note: string;
  };
  past_campaigns: {
    count: number;
    campaigns: string[];
    note: string;
  };
  current_time: string;
}

// Enhanced Authentication Types
export interface ForgotPasswordRequest {
  email: string;
}

export interface ResetPasswordRequest {
  token: string;
  new_password: string;
}

export interface PasswordResetResponse {
  message: string;
  success: boolean;
}

// Enhanced Share Analytics Types
export interface ShareAnalyticsEnhanced {
  platform_breakdown: {
    [platform: string]: {
      shares: number;
      points: number;
      percentage: number;
      first_share_date?: string;
      last_share_date?: string;
    };
  };
  timeline: {
    date: string;
    shares: number;
    points: number;
  }[];
  summary: {
    total_shares: number;
    total_points: number;
    active_platforms: number;
    average_points_per_share: number;
  };
}

export interface ShareHistoryEnhanced extends ShareHistoryResponse {
  summary: {
    total_shares: number;
    total_points_earned: number;
    platforms_used: string[];
  };
}

// Enhanced Admin Types
export interface AdminUserEnhanced extends AdminUser {
  is_admin?: boolean;
}

export interface UserExportRequest {
  format: 'csv' | 'json';
  filters?: {
    search?: string;
    minPoints?: number;
  };
}

export interface UserStatusUpdateRequest {
  status: 'active' | 'inactive';
}

// API Error Types
export interface ApiError {
  message: string;
  status: number;
  details?: any;
}

// Request/Response wrapper types
export interface ApiRequestConfig {
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';
  url: string;
  data?: any;
  params?: any;
  headers?: Record<string, string>;
}

// Loading states
export interface LoadingState {
  isLoading: boolean;
  error?: string;
}

// Combined state types for components
export interface UserState extends LoadingState {
  user: UserResponse | null;
  isAuthenticated: boolean;
}

export interface LeaderboardState extends LoadingState {
  leaderboard: LeaderboardUser[];
  aroundMe: AroundMeUser[];
  userStats: AroundMeResponse['your_stats'] | null;
  pagination: PaginationMeta | null;
}

export interface AdminState extends LoadingState {
  dashboard: AdminDashboardResponse | null;
  users: AdminUser[];
  usersPagination: PaginationMeta | null;
}
