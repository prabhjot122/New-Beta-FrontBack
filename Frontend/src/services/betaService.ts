/**
 * Beta User Registration Service
 * =============================
 * Handles beta user registration for the LawVriksh platform.
 * This service is specifically for the beta joining page where users
 * enter only their name and email.
 */

import { API_CONFIG, API_ENDPOINTS } from '../config/api';
import { apiClient } from './api';

// Types for beta user registration
export interface BetaUserCreate {
  name: string;
  email: string;
}

export interface BetaUserResponse {
  user_id: number;
  name: string;
  email: string;
  created_at: string;
  is_beta_user: boolean;
  message: string;
}

export interface BetaStats {
  total_beta_users: number;
  users_last_24h: number;
  users_last_week: number;
  status: string;
}

// Mock data for development
const MOCK_BETA_RESPONSE: BetaUserResponse = {
  user_id: 1001,
  name: 'Beta User',
  email: 'beta@example.com',
  created_at: new Date().toISOString(),
  is_beta_user: true,
  message: 'Welcome to LawVriksh Beta! Check your email for login credentials.'
};

const MOCK_BETA_STATS: BetaStats = {
  total_beta_users: 150,
  users_last_24h: 12,
  users_last_week: 45,
  status: 'active'
};

// Utility functions
const mockDelay = (ms: number = 1000): Promise<void> => {
  return new Promise(resolve => setTimeout(resolve, ms));
};

const withErrorHandling = async <T>(apiCall: () => Promise<T>): Promise<T> => {
  try {
    return await apiCall();
  } catch (error: any) {
    console.error('Beta API Error:', error);
    
    // Handle different types of errors
    if (error.response) {
      // Server responded with error status
      const message = error.response.data?.detail || error.response.data?.message || 'Server error occurred';
      throw new Error(message);
    } else if (error.request) {
      // Request was made but no response received
      throw new Error('Unable to connect to server. Please check your internet connection.');
    } else {
      // Something else happened
      throw new Error(error.message || 'An unexpected error occurred');
    }
  }
};

/**
 * Beta User Registration Service
 */
class BetaService {
  /**
   * Register a beta user with name and email only
   */
  async registerBetaUser(userData: BetaUserCreate): Promise<BetaUserResponse> {
    console.log('🚀 Beta registration attempt:', { name: userData.name, email: userData.email });
    
    // Mock mode for development
    if (API_CONFIG.MOCK_MODE) {
      console.log('📝 Using mock mode for beta registration');
      await mockDelay(1500);
      
      // Simulate email validation
      if (!userData.email.includes('@')) {
        throw new Error('Please enter a valid email address');
      }
      
      // Simulate name validation
      if (userData.name.trim().length < 2) {
        throw new Error('Please enter your full name');
      }
      
      // Simulate existing user check (5% chance)
      if (Math.random() < 0.05) {
        throw new Error('Email already registered. If you\'re already a member, please use the login page.');
      }
      
      return {
        ...MOCK_BETA_RESPONSE,
        name: userData.name,
        email: userData.email,
        user_id: Math.floor(Math.random() * 9000) + 1000
      };
    }
    
    // Real API call
    const response = await withErrorHandling(() =>
      apiClient.post<BetaUserResponse>(API_ENDPOINTS.BETA.SIGNUP, userData)
    );
    
    console.log('✅ Beta registration successful:', response.email);
    return response;
  }
  
  /**
   * Get beta user statistics
   */
  async getBetaStats(): Promise<BetaStats> {
    console.log('📊 Fetching beta statistics...');
    
    // Mock mode for development
    if (API_CONFIG.MOCK_MODE) {
      await mockDelay(500);
      return MOCK_BETA_STATS;
    }
    
    // Real API call
    const response = await withErrorHandling(() =>
      apiClient.get<BetaStats>(API_ENDPOINTS.BETA.STATS)
    );
    
    console.log('✅ Beta stats retrieved:', response);
    return response;
  }
  
  /**
   * Check beta service health
   */
  async checkBetaHealth(): Promise<{ status: string; service: string; timestamp: string }> {
    console.log('🔍 Checking beta service health...');
    
    // Mock mode for development
    if (API_CONFIG.MOCK_MODE) {
      await mockDelay(200);
      return {
        status: 'healthy',
        service: 'beta_registration',
        timestamp: new Date().toISOString()
      };
    }
    
    // Real API call
    const response = await withErrorHandling(() =>
      apiClient.get<{ status: string; service: string; timestamp: string }>(API_ENDPOINTS.BETA.HEALTH)
    );
    
    console.log('✅ Beta service health:', response.status);
    return response;
  }
  
  /**
   * Validate beta user input
   */
  validateBetaUserInput(userData: BetaUserCreate): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];
    
    // Validate name
    if (!userData.name || userData.name.trim().length < 2) {
      errors.push('Please enter your full name (at least 2 characters)');
    }
    
    if (userData.name && userData.name.trim().length > 100) {
      errors.push('Name must be less than 100 characters');
    }
    
    // Validate email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!userData.email || !emailRegex.test(userData.email)) {
      errors.push('Please enter a valid email address');
    }
    
    if (userData.email && userData.email.length > 254) {
      errors.push('Email address is too long');
    }
    
    return {
      isValid: errors.length === 0,
      errors
    };
  }
  
  /**
   * Format user name for display
   */
  formatUserName(name: string): string {
    return name
      .trim()
      .split(' ')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
      .join(' ');
  }
  
  /**
   * Generate share message for beta user
   */
  generateBetaShareMessage(userName: string): string {
    const formattedName = this.formatUserName(userName);
    
    return `🎉 Congratulations to ${formattedName} for becoming a beta testing founding member at LawVriksh!

✨ Welcome aboard! We're thrilled to have you join our growing community of legal professionals and enthusiasts.

By registering with LawVriksh, you've taken the first step towards unlocking a wealth of legal knowledge, connecting with peers, and staying ahead in the ever-evolving legal landscape.

🚀 As a beta member, you'll get:
• Early access to all features
• Direct input on product development
• Founding member status
• Priority support

Join the legal revolution at https://lawvriksh.com

#LawVriksh #LegalTech #BetaMember #LegalProfessionals #Innovation`;
  }
}

// Export singleton instance
export const betaService = new BetaService();

// Export types
export type { BetaUserCreate, BetaUserResponse, BetaStats };
