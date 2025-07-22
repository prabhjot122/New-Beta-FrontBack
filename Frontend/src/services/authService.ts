// Authentication service for handling login, signup, and user management

import { apiClient, withErrorHandling, MOCK_MODE, mockDelay } from './api';
import {
  UserCreate,
  UserLogin,
  UserResponse,
  Token,
  UserProfileUpdate,
  ForgotPasswordRequest,
  ResetPasswordRequest,
  PasswordResetResponse
} from '../types/api';

class AuthService {
  // Mock admin credentials for development
  private readonly MOCK_ADMIN = {
    email: 'admin@lawvriksh.com',
    password: 'admin123',
    user: {
      user_id: 1,
      name: 'Admin User',
      email: 'admin@lawvriksh.com',
      created_at: new Date().toISOString(),
      total_points: 0,
      shares_count: 0,
      current_rank: null,
      is_admin: true
    }
  };

  /**
   * User signup/registration
   */
  async signup(userData: UserCreate): Promise<UserResponse> {
    if (MOCK_MODE) {
      await mockDelay();

      // Mock validation
      if (userData.email === this.MOCK_ADMIN.email) {
        throw new Error('Email already registered');
      }

      // Return mock user response
      return {
        user_id: Math.floor(Math.random() * 1000) + 2,
        name: userData.name,
        email: userData.email,
        created_at: new Date().toISOString(),
        total_points: 0,
        shares_count: 0,
        current_rank: undefined,
        is_admin: false
      };
    }

    const response = await withErrorHandling(() =>
      apiClient.post<UserResponse>('/auth/signup', userData)
    );

    // Store user data on successful signup (but note: no auth token yet)
    if (response.user_id) {
      localStorage.setItem('userData', JSON.stringify(response));
      console.log('✅ User data stored after signup:', response);
    }

    return response;
  }

  /**
   * User login
   */
  async login(credentials: UserLogin): Promise<Token> {
    if (MOCK_MODE) {
      await mockDelay();

      // Mock authentication
      if (credentials.email === this.MOCK_ADMIN.email &&
          credentials.password === this.MOCK_ADMIN.password) {
        const mockToken = 'mock-jwt-token-' + Date.now();

        // Store token and user data
        localStorage.setItem('authToken', mockToken);
        localStorage.setItem('userData', JSON.stringify(this.MOCK_ADMIN.user));

        return {
          access_token: mockToken,
          token_type: 'bearer',
          expires_in: 3600
        };
      }

      throw new Error('Invalid email or password');
    }

    const response = await withErrorHandling(() =>
      apiClient.post<Token>('/auth/login', credentials)
    );

    // Store token on successful login
    if (response.access_token) {
      localStorage.setItem('authToken', response.access_token);

      // Get user data after successful login
      try {
        const userData = await this.getCurrentUser();
        localStorage.setItem('userData', JSON.stringify(userData));
      } catch (error) {
        console.warn('Failed to fetch user data after login:', error);
      }
    }

    return response;
  }

  /**
   * Get current user information
   */
  async getCurrentUser(): Promise<UserResponse> {
    if (MOCK_MODE) {
      await mockDelay(200);
      
      const userData = localStorage.getItem('userData');
      if (userData) {
        return JSON.parse(userData);
      }
      
      throw new Error('User not authenticated');
    }

    return withErrorHandling(() => 
      apiClient.get<UserResponse>('/auth/me')
    );
  }

  /**
   * Update user profile
   */
  async updateProfile(profileData: UserProfileUpdate): Promise<UserResponse> {
    if (MOCK_MODE) {
      await mockDelay();
      
      const userData = localStorage.getItem('userData');
      if (!userData) {
        throw new Error('User not authenticated');
      }
      
      const currentUser = JSON.parse(userData);
      const updatedUser = { ...currentUser, ...profileData };
      
      localStorage.setItem('userData', JSON.stringify(updatedUser));
      return updatedUser;
    }

    return withErrorHandling(() => 
      apiClient.put<UserResponse>('/users/profile', profileData)
    );
  }

  /**
   * Logout user
   */
  logout(): void {
    localStorage.removeItem('authToken');
    localStorage.removeItem('userData');
  }

  /**
   * Check if user is authenticated
   */
  isAuthenticated(): boolean {
    const token = localStorage.getItem('authToken');
    const userData = localStorage.getItem('userData');
    return !!(token && userData);
  }

  /**
   * Check if current user is admin
   */
  isAdmin(): boolean {
    const userData = localStorage.getItem('userData');
    if (!userData) return false;
    
    try {
      const user = JSON.parse(userData);
      return user.is_admin === true;
    } catch {
      return false;
    }
  }

  /**
   * Get stored user data
   */
  getStoredUser(): UserResponse | null {
    const userData = localStorage.getItem('userData');
    if (!userData) return null;
    
    try {
      return JSON.parse(userData);
    } catch {
      return null;
    }
  }

  /**
   * Refresh authentication token
   */
  async refreshToken(): Promise<Token> {
    if (MOCK_MODE) {
      await mockDelay();
      
      if (!this.isAuthenticated()) {
        throw new Error('User not authenticated');
      }
      
      const newToken = 'mock-jwt-token-' + Date.now();
      localStorage.setItem('authToken', newToken);
      
      return {
        access_token: newToken,
        token_type: 'bearer',
        expires_in: 3600
      };
    }

    return withErrorHandling(() => 
      apiClient.post<Token>('/auth/refresh')
    );
  }

  /**
   * Validate token and get user info
   */
  async validateToken(): Promise<UserResponse | null> {
    if (!this.isAuthenticated()) {
      return null;
    }

    try {
      return await this.getCurrentUser();
    } catch (error) {
      // Token is invalid, clear stored data
      this.logout();
      return null;
    }
  }

  /**
   * Request password reset
   */
  async forgotPassword(email: string): Promise<PasswordResetResponse> {
    if (MOCK_MODE) {
      await mockDelay(1000);

      // Mock validation
      if (!email || !email.includes('@')) {
        throw new Error('Please enter a valid email address');
      }

      return {
        message: 'Password reset instructions have been sent to your email address.',
        success: true
      };
    }

    const request: ForgotPasswordRequest = { email };
    return withErrorHandling(() =>
      apiClient.post<PasswordResetResponse>('/auth/forgot-password', request)
    );
  }

  /**
   * Reset password with token
   */
  async resetPassword(token: string, newPassword: string): Promise<PasswordResetResponse> {
    if (MOCK_MODE) {
      await mockDelay(1000);

      // Mock validation
      if (!token) {
        throw new Error('Invalid or expired reset token');
      }

      if (!newPassword || newPassword.length < 6) {
        throw new Error('Password must be at least 6 characters long');
      }

      return {
        message: 'Your password has been successfully reset. You can now log in with your new password.',
        success: true
      };
    }

    const request: ResetPasswordRequest = { token, new_password: newPassword };
    return withErrorHandling(() =>
      apiClient.post<PasswordResetResponse>('/auth/reset-password', request)
    );
  }

  /**
   * Change password for authenticated user
   */
  async changePassword(currentPassword: string, newPassword: string): Promise<PasswordResetResponse> {
    if (MOCK_MODE) {
      await mockDelay(800);

      // Mock validation
      if (!this.isAuthenticated()) {
        throw new Error('User not authenticated');
      }

      if (!currentPassword) {
        throw new Error('Current password is required');
      }

      if (!newPassword || newPassword.length < 6) {
        throw new Error('New password must be at least 6 characters long');
      }

      return {
        message: 'Password changed successfully',
        success: true
      };
    }

    return withErrorHandling(() =>
      apiClient.post<PasswordResetResponse>('/users/change-password', {
        current_password: currentPassword,
        new_password: newPassword
      })
    );
  }

  /**
   * Delete user account
   */
  async deleteAccount(password: string): Promise<{ message: string }> {
    if (MOCK_MODE) {
      await mockDelay(1000);

      if (!this.isAuthenticated()) {
        throw new Error('User not authenticated');
      }

      if (!password) {
        throw new Error('Password confirmation is required');
      }

      // Clear stored data
      this.logout();

      return {
        message: 'Account deleted successfully'
      };
    }

    const response = await withErrorHandling(() =>
      apiClient.delete<{ message: string }>('/users/delete-account', { password })
    );

    // Clear stored data after successful deletion
    this.logout();

    return response;
  }

  /**
   * Check password strength
   */
  checkPasswordStrength(password: string): {
    score: number;
    feedback: string[];
    isValid: boolean;
  } {
    const feedback: string[] = [];
    let score = 0;

    if (password.length < 6) {
      feedback.push('Password must be at least 6 characters long');
    } else {
      score += 1;
    }

    if (password.length >= 8) {
      score += 1;
    }

    if (/[a-z]/.test(password) && /[A-Z]/.test(password)) {
      score += 1;
    } else {
      feedback.push('Include both uppercase and lowercase letters');
    }

    if (/\d/.test(password)) {
      score += 1;
    } else {
      feedback.push('Include at least one number');
    }

    if (/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
      score += 1;
    } else {
      feedback.push('Include at least one special character');
    }

    const strengthLabels = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong'];
    const strengthLabel = strengthLabels[Math.min(score, 4)];

    if (score >= 3) {
      feedback.unshift(`Password strength: ${strengthLabel}`);
    }

    return {
      score,
      feedback,
      isValid: score >= 2 && password.length >= 6
    };
  }



  /**
   * Auto-refresh token before expiration
   */
  startTokenRefresh(): void {
    // Refresh token every 50 minutes (assuming 1-hour expiration)
    const refreshInterval = 50 * 60 * 1000;

    setInterval(async () => {
      if (this.isAuthenticated()) {
        try {
          await this.refreshToken();
        } catch (error) {
          console.warn('Token refresh failed:', error);
          // Don't logout automatically, let the user continue until next API call fails
        }
      }
    }, refreshInterval);
  }
}

// Export singleton instance
export const authService = new AuthService();
export default authService;
