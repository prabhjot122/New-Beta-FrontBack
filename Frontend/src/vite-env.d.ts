/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string
  readonly VITE_API_TIMEOUT: string
  readonly VITE_API_RETRY_ATTEMPTS: string
  readonly VITE_MOCK_MODE: string
  readonly VITE_ENABLE_ANALYTICS: string
  readonly VITE_ENABLE_NOTIFICATIONS: string
  readonly VITE_ENABLE_DARK_MODE: string
  readonly VITE_ENABLE_BETA_FEATURES: string
  readonly VITE_ENABLE_OFFLINE_MODE: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
