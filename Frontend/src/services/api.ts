// Base API service configuration and utilities

import { ApiResponse, ApiRequestConfig } from '../types/api';

// API Configuration
const API_CONFIG = {
  BASE_URL: import.meta.env.VITE_API_URL || 'http://localhost:8000',
  TIMEOUT: 10000,
  RETRY_ATTEMPTS: 3,
};

// API Client class for making HTTP requests
class ApiClient {
  private baseURL: string;
  private timeout: number;

  constructor(baseURL: string = API_CONFIG.BASE_URL, timeout: number = API_CONFIG.TIMEOUT) {
    this.baseURL = baseURL;
    this.timeout = timeout;
  }

  private getAuthHeaders(): Record<string, string> {
    const token = localStorage.getItem('authToken');
    return token ? { Authorization: `Bearer ${token}` } : {};
  }

  private async makeRequest<T>(config: ApiRequestConfig): Promise<ApiResponse<T>> {
    const { method, url, data, params, headers = {} } = config;
    
    // Build full URL
    const fullUrl = new URL(url, this.baseURL);
    
    // Add query parameters
    if (params) {
      Object.keys(params).forEach(key => {
        if (params[key] !== undefined && params[key] !== null) {
          fullUrl.searchParams.append(key, params[key].toString());
        }
      });
    }

    // Prepare request options
    const requestOptions: RequestInit = {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...this.getAuthHeaders(),
        ...headers,
      },
      signal: AbortSignal.timeout(this.timeout),
    };

    // Add body for POST/PUT requests
    if (data && (method === 'POST' || method === 'PUT')) {
      requestOptions.body = JSON.stringify(data);
    }

    try {
      const response = await fetch(fullUrl.toString(), requestOptions);
      
      // Handle different response types
      let responseData;
      const contentType = response.headers.get('content-type');
      
      if (contentType?.includes('application/json')) {
        responseData = await response.json();
      } else if (contentType?.includes('text/')) {
        responseData = await response.text();
      } else {
        responseData = await response.blob();
      }

      if (!response.ok) {
        // Extract error message from different possible response formats
        let errorMessage = `HTTP ${response.status}`;

        if (responseData) {
          // Handle structured error response from backend error handlers
          if (responseData.error && responseData.error.message) {
            errorMessage = responseData.error.message;
          }
          // Handle direct error responses (legacy format)
          else if (responseData.detail) {
            errorMessage = responseData.detail;
          }
          else if (responseData.message) {
            errorMessage = responseData.message;
          }
          // Handle string responses
          else if (typeof responseData === 'string') {
            errorMessage = responseData;
          }
        }

        throw new Error(errorMessage);
      }

      return {
        data: responseData,
        status: response.status,
      };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      
      // Handle network errors, timeouts, etc.
      throw new ApiError(
        error instanceof Error ? error.message : 'Network error occurred',
        0,
        error
      );
    }
  }

  async get<T>(url: string, params?: any, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return this.makeRequest<T>({ method: 'GET', url, params, headers });
  }

  async post<T>(url: string, data?: any, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return this.makeRequest<T>({ method: 'POST', url, data, headers });
  }

  async put<T>(url: string, data?: any, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return this.makeRequest<T>({ method: 'PUT', url, data, headers });
  }

  async delete<T>(url: string, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return this.makeRequest<T>({ method: 'DELETE', url, headers });
  }
}

// Custom API Error class
class ApiError extends Error {
  public status: number;
  public details?: any;

  constructor(message: string, status: number, details?: any) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.details = details;
  }
}

// Create singleton API client instance
export const apiClient = new ApiClient();

// Utility functions for API responses
export const handleApiError = (error: unknown): ApiError => {
  if (error instanceof ApiError) {
    return error;
  }
  
  if (error instanceof Error) {
    return new ApiError(error.message, 0);
  }
  
  return new ApiError('Unknown error occurred', 0);
};

export const isApiError = (error: unknown): error is ApiError => {
  return error instanceof ApiError;
};

// Response wrapper for consistent error handling
export const withErrorHandling = async <T>(
  apiCall: () => Promise<ApiResponse<T>>
): Promise<T> => {
  try {
    const response = await apiCall();
    return response.data as T;
  } catch (error) {
    throw handleApiError(error);
  }
};

// Mock mode flag for development
export const MOCK_MODE = import.meta.env.VITE_MOCK_MODE === 'true';

// Mock delay utility for simulating network latency
export const mockDelay = (ms: number = 500): Promise<void> => {
  return new Promise(resolve => setTimeout(resolve, ms));
};

export { ApiError };
