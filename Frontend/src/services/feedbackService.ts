import { apiClient } from './api';

export interface FeedbackSubmission {
  // User information
  email: string;
  name: string;

  // Multiple choice questions
  biggest_hurdle: string;
  biggest_hurdle_other?: string;
  primary_motivation?: string;
  time_consuming_part?: string;
  professional_fear: string;

  // Short answer questions
  monetization_considerations?: string;
  professional_legacy?: string;
  platform_impact: string;
}

export interface FeedbackResponse {
  id: number;
  user_id?: number;
  email: string;
  name: string;
  biggest_hurdle: string;
  biggest_hurdle_other?: string;
  primary_motivation?: string;
  time_consuming_part?: string;
  professional_fear: string;
  monetization_considerations?: string;
  professional_legacy?: string;
  platform_impact: string;
  submitted_at: string;
  ip_address?: string;
  user_name?: string;
  user_email?: string;
}

export interface FeedbackListResponse {
  feedback: FeedbackResponse[];
  pagination: {
    page: number;
    pageSize: number;
    total: number;
    totalPages: number;
  };
}

export interface FeedbackExportFilters {
  search?: string;
  dateRange?: {
    start: string;
    end: string;
  };
  biggest_hurdle?: string;
  primary_motivation?: string;
}

class FeedbackService {
  /**
   * Submit feedback survey response
   */
  async submitFeedback(feedbackData: FeedbackSubmission): Promise<{ success: boolean; message: string }> {
    try {
      const response = await apiClient.post('/feedback/submit', feedbackData);
      
      if (response.status === 200 || response.status === 201) {
        return {
          success: true,
          message: (response.data as any)?.message || 'Feedback submitted successfully'
        };
      }

      throw new Error('Unexpected response status');
    } catch (error: any) {
      console.error('Failed to submit feedback:', error);
      
      if (error.response?.status === 400) {
        throw new Error(error.response.data?.detail || 'Invalid feedback data');
      } else if (error.response?.status === 429) {
        throw new Error('Too many submissions. Please try again later.');
      } else if (error.response?.status >= 500) {
        throw new Error('Server error. Please try again later.');
      }
      
      throw new Error('Failed to submit feedback. Please check your connection and try again.');
    }
  }

  /**
   * Get all feedback responses (admin only)
   */
  async getFeedbackList(
    page: number = 1,
    pageSize: number = 50,
    filters?: {
      search?: string;
      biggestHurdle?: string;
      primaryMotivation?: string;
      dateRange?: { start: string; end: string };
    }
  ): Promise<FeedbackListResponse> {
    try {
      const params = new URLSearchParams({
        page: page.toString(),
        page_size: pageSize.toString(),
      });

      if (filters?.search) {
        params.append('search', filters.search);
      }
      if (filters?.biggestHurdle) {
        params.append('biggest_hurdle', filters.biggestHurdle);
      }
      if (filters?.primaryMotivation) {
        params.append('primary_motivation', filters.primaryMotivation);
      }
      if (filters?.dateRange) {
        params.append('start_date', filters.dateRange.start);
        params.append('end_date', filters.dateRange.end);
      }

      const response = await apiClient.get(`/feedback?${params}`);
      return response.data as FeedbackListResponse;
    } catch (error: any) {
      console.error('Failed to fetch feedback list:', error);
      
      if (error.response?.status === 403) {
        throw new Error('Admin access required');
      } else if (error.response?.status === 401) {
        throw new Error('Authentication required');
      }
      
      throw new Error('Failed to fetch feedback data');
    }
  }

  /**
   * Get feedback statistics (admin only)
   */
  async getFeedbackStats(): Promise<{
    total_responses: number;
    responses_by_hurdle: Record<string, number>;
    responses_by_motivation: Record<string, number>;
    responses_by_fear: Record<string, number>;
    responses_by_time_consuming_part: Record<string, number>;
    recent_responses: number;
    responses_last_7_days: number;
    responses_last_30_days: number;
    first_response?: string;
    latest_response?: string;
  }> {
    try {
      const response = await apiClient.get('/feedback/stats');
      return response.data as any;
    } catch (error: any) {
      console.error('Failed to fetch feedback stats:', error);
      
      if (error.response?.status === 403) {
        throw new Error('Admin access required');
      } else if (error.response?.status === 401) {
        throw new Error('Authentication required');
      }
      
      throw new Error('Failed to fetch feedback statistics');
    }
  }

  /**
   * Export feedback data in JSON format (admin only)
   */
  async exportFeedback(
    format: 'json' = 'json',
    filters?: FeedbackExportFilters
  ): Promise<Blob> {
    try {
      const params = new URLSearchParams({
        format,
      });

      if (filters?.search) {
        params.append('search', filters.search);
      }
      if (filters?.biggest_hurdle) {
        params.append('biggest_hurdle', filters.biggest_hurdle);
      }
      if (filters?.primary_motivation) {
        params.append('primary_motivation', filters.primary_motivation);
      }
      if (filters?.dateRange) {
        params.append('start_date', filters.dateRange.start);
        params.append('end_date', filters.dateRange.end);
      }

      const response = await fetch(`http://localhost:8000/feedback/export?${params}`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
        },
      });

      if (!response.ok) {
        if (response.status === 403) {
          throw new Error('Admin access required');
        } else if (response.status === 401) {
          throw new Error('Authentication required');
        }
        throw new Error('Export failed');
      }

      return response.blob();
    } catch (error: any) {
      console.error('Failed to export feedback:', error);
      throw error;
    }
  }

  /**
   * Download exported feedback data in JSON format
   */
  async downloadFeedbackExport(
    format: 'json' = 'json',
    filters?: FeedbackExportFilters
  ): Promise<void> {
    try {
      const blob = await this.exportFeedback(format, filters);

      // Create download link
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `feedback_responses_${new Date().toISOString().split('T')[0]}.${format}`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (error: any) {
      console.error('Failed to download feedback export:', error);
      throw error;
    }
  }

  /**
   * Validate feedback form data
   */
  validateFeedbackData(data: FeedbackSubmission): { isValid: boolean; errors: Record<string, string> } {
    const errors: Record<string, string> = {};

    // Validate multiple choice questions
    if (!data.biggest_hurdle) {
      errors.biggestHurdle = 'Please select your biggest hurdle';
    }
    if (data.biggest_hurdle === 'E' && !data.biggest_hurdle_other?.trim()) {
      errors.biggestHurdleOther = 'Please specify your answer';
    }
    if (!data.primary_motivation) {
      errors.primaryMotivation = 'Please select your primary motivation';
    }
    if (!data.time_consuming_part) {
      errors.timeConsumingPart = 'Please select the most time-consuming part';
    }
    if (!data.professional_fear) {
      errors.professionalFear = 'Please select your biggest professional fear';
    }

    // Validate short answer questions
    const validateShortAnswer = (text: string, fieldName: string, displayName: string) => {
      if (!text?.trim()) {
        errors[fieldName] = `Please provide your answer for ${displayName}`;
        return;
      }

      if (text.trim().length < 10) {
        errors[fieldName] = `Please provide a more detailed answer for ${displayName}`;
      }
    };

    if (data.monetization_considerations) {
      validateShortAnswer(data.monetization_considerations, 'monetizationConsiderations', 'monetization considerations');
    }
    if (data.professional_legacy) {
      validateShortAnswer(data.professional_legacy, 'professionalLegacy', 'professional legacy');
    }
    validateShortAnswer(data.platform_impact, 'platformImpact', 'platform impact');

    return {
      isValid: Object.keys(errors).length === 0,
      errors
    };
  }
}

export const feedbackService = new FeedbackService();
export default feedbackService;
