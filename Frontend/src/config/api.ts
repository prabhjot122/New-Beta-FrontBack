// API configuration and environment settings

export const API_CONFIG = {
  // Base API URL - will be set from environment variable or default to localhost
  BASE_URL: import.meta.env.VITE_API_URL || 'http://localhost:8000',

  // API timeout in milliseconds
  TIMEOUT: parseInt(import.meta.env.VITE_API_TIMEOUT || '10000'),

  // Number of retry attempts for failed requests
  RETRY_ATTEMPTS: parseInt(import.meta.env.VITE_API_RETRY_ATTEMPTS || '3'),

  // Mock mode flag - when true, uses mock data instead of real API calls
  MOCK_MODE: import.meta.env.VITE_MOCK_MODE === 'true',
  
  // API version
  VERSION: 'v1',
  
  // Request headers
  DEFAULT_HEADERS: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  
  // Authentication token key in localStorage
  AUTH_TOKEN_KEY: 'authToken',
  USER_DATA_KEY: 'userData',
  
  // Pagination defaults
  DEFAULT_PAGE_SIZE: 50,
  MAX_PAGE_SIZE: 100,
  
  // Cache settings
  CACHE_DURATION: 5 * 60 * 1000, // 5 minutes in milliseconds
  
  // File upload settings
  MAX_FILE_SIZE: 10 * 1024 * 1024, // 10MB
  ALLOWED_FILE_TYPES: ['image/jpeg', 'image/png', 'image/gif', 'application/pdf'],
  
  // Rate limiting
  RATE_LIMIT_REQUESTS: 100,
  RATE_LIMIT_WINDOW: 60 * 1000, // 1 minute
};

// API Endpoints
export const API_ENDPOINTS = {
  // Authentication
  AUTH: {
    LOGIN: '/auth/login',
    SIGNUP: '/auth/signup',
    LOGOUT: '/auth/logout',
    REFRESH: '/auth/refresh',
    ME: '/auth/me',
    FORGOT_PASSWORD: '/auth/forgot-password',
    RESET_PASSWORD: '/auth/reset-password',
  },
  
  // Users
  USERS: {
    PROFILE: '/users/profile',
    UPDATE_PROFILE: '/users/profile',
    USER_PROFILE: (userId: number) => `/users/${userId}/profile`,
    VIEW_ALL: '/users/view',
    EXPORT: '/users/export',
    CHANGE_PASSWORD: '/users/change-password',
    DELETE_ACCOUNT: '/users/delete-account',
  },
  
  // Shares
  SHARES: {
    RECORD: (platform: string) => `/shares/${platform}`,
    HISTORY: '/shares/history',
    ANALYTICS: '/shares/analytics',
    PLATFORMS: '/shares/platforms',
  },
  
  // Leaderboard
  LEADERBOARD: {
    PUBLIC: '/leaderboard',
    AROUND_ME: '/leaderboard/around-me',
    TOP_PERFORMERS: '/leaderboard/top-performers',
    USER_RANK: '/leaderboard/user-rank',
  },
  
  // Admin
  ADMIN: {
    LOGIN: '/admin/login',
    DASHBOARD: '/admin/dashboard',
    USERS: '/admin/users',
    USER_DETAILS: (userId: number) => `/admin/users/${userId}`,
    USER_STATUS: (userId: number) => `/admin/users/${userId}/status`,
    PROMOTE_USER: '/admin/promote',
    BULK_EMAIL: '/admin/send-bulk-email',
    EXPORT_USERS: '/admin/export',
    ANALYTICS: '/admin/analytics',
    SHARE_ANALYTICS: '/admin/analytics',
    SHARE_HISTORY: '/admin/share-history',
    PLATFORM_STATS: '/admin/platform-stats',
  },

  // Campaigns
  CAMPAIGNS: {
    SCHEDULE: '/campaigns/schedule',
    SEND: '/campaigns/send',
    STATUS: (campaignType: string) => `/campaigns/status/${campaignType}`,
    TEST_SAHIL: '/campaigns/test-sahil',
    NEW_USER_PREVIEW: '/campaigns/new-user-campaigns',
  },

  // Feedback
  FEEDBACK: {
    SUBMIT: '/feedback/submit',
    LIST: '/feedback',
    STATS: '/feedback/stats',
    EXPORT: '/feedback/export',
  },
  
  // Beta User Registration
  BETA: {
    SIGNUP: '/beta/signup',
    STATS: '/beta/stats',
    HEALTH: '/beta/health',
  },

  // System
  SYSTEM: {
    HEALTH: '/health',
    VERSION: '/version',
    STATUS: '/status',
  },
};

// Error messages
export const ERROR_MESSAGES = {
  NETWORK_ERROR: 'Network error. Please check your internet connection.',
  TIMEOUT_ERROR: 'Request timed out. Please try again.',
  UNAUTHORIZED: 'You are not authorized to perform this action.',
  FORBIDDEN: 'Access denied.',
  NOT_FOUND: 'The requested resource was not found.',
  SERVER_ERROR: 'Internal server error. Please try again later.',
  VALIDATION_ERROR: 'Please check your input and try again.',
  RATE_LIMIT_EXCEEDED: 'Too many requests. Please wait and try again.',
  FILE_TOO_LARGE: `File size exceeds ${API_CONFIG.MAX_FILE_SIZE / 1024 / 1024}MB limit.`,
  INVALID_FILE_TYPE: 'Invalid file type. Please upload a supported file format.',
  GENERIC_ERROR: 'An unexpected error occurred. Please try again.',
};

// Success messages
export const SUCCESS_MESSAGES = {
  LOGIN_SUCCESS: 'Successfully logged in!',
  LOGOUT_SUCCESS: 'Successfully logged out!',
  SIGNUP_SUCCESS: 'Account created successfully!',
  PROFILE_UPDATED: 'Profile updated successfully!',
  PASSWORD_CHANGED: 'Password changed successfully!',
  SHARE_RECORDED: 'Share recorded successfully!',
  EMAIL_SENT: 'Email sent successfully!',
  USER_PROMOTED: 'User promoted successfully!',
  DATA_EXPORTED: 'Data exported successfully!',
  SETTINGS_SAVED: 'Settings saved successfully!',
};

// HTTP Status Codes
export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  NO_CONTENT: 204,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  UNPROCESSABLE_ENTITY: 422,
  TOO_MANY_REQUESTS: 429,
  INTERNAL_SERVER_ERROR: 500,
  BAD_GATEWAY: 502,
  SERVICE_UNAVAILABLE: 503,
  GATEWAY_TIMEOUT: 504,
};

// Development helpers
export const isDevelopment = import.meta.env.DEV;
export const isProduction = import.meta.env.PROD;
export const isTest = import.meta.env.MODE === 'test';

// Feature flags
export const FEATURES = {
  ENABLE_ANALYTICS: import.meta.env.VITE_ENABLE_ANALYTICS !== 'false',
  ENABLE_NOTIFICATIONS: import.meta.env.VITE_ENABLE_NOTIFICATIONS !== 'false',
  ENABLE_DARK_MODE: import.meta.env.VITE_ENABLE_DARK_MODE === 'true',
  ENABLE_BETA_FEATURES: import.meta.env.VITE_ENABLE_BETA_FEATURES === 'true',
  ENABLE_OFFLINE_MODE: import.meta.env.VITE_ENABLE_OFFLINE_MODE === 'true',
};

// Validation rules
export const VALIDATION = {
  EMAIL_REGEX: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  PASSWORD_MIN_LENGTH: 8,
  NAME_MIN_LENGTH: 2,
  NAME_MAX_LENGTH: 50,
  BIO_MAX_LENGTH: 500,
  SEARCH_MIN_LENGTH: 2,
  SEARCH_DEBOUNCE_MS: 300,
};

// Local storage keys
export const STORAGE_KEYS = {
  AUTH_TOKEN: API_CONFIG.AUTH_TOKEN_KEY,
  USER_DATA: API_CONFIG.USER_DATA_KEY,
  THEME: 'theme',
  LANGUAGE: 'language',
  PREFERENCES: 'userPreferences',
  CACHE_PREFIX: 'lawvriksh_cache_',
};

export default API_CONFIG;
