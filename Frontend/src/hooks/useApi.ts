// Custom hooks for API state management

import { useState, useEffect, useCallback } from 'react';
import { ApiError } from '../services/api';

// Generic API hook for handling loading states and errors
export function useApiState<T>(initialData: T) {
  const [data, setData] = useState<T>(initialData);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const execute = useCallback(async (apiCall: () => Promise<T>) => {
    setLoading(true);
    setError(null);
    
    try {
      const result = await apiCall();
      setData(result);
      return result;
    } catch (err) {
      const errorMessage = err instanceof ApiError ? err.message : 'An error occurred';
      setError(errorMessage);
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const reset = useCallback(() => {
    setData(initialData);
    setError(null);
    setLoading(false);
  }, [initialData]);

  return {
    data,
    loading,
    error,
    execute,
    reset,
    setData,
    setError
  };
}

// Hook for paginated data
export function usePaginatedApi<T>(initialData: T[], initialPagination: any) {
  const [data, setData] = useState<T[]>(initialData);
  const [pagination, setPagination] = useState(initialPagination);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const execute = useCallback(async (
    apiCall: () => Promise<{ data: T[]; pagination: any }>
  ) => {
    setLoading(true);
    setError(null);
    
    try {
      const result = await apiCall();
      setData(result.data);
      setPagination(result.pagination);
      return result;
    } catch (err) {
      const errorMessage = err instanceof ApiError ? err.message : 'An error occurred';
      setError(errorMessage);
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const loadMore = useCallback(async (
    apiCall: () => Promise<{ data: T[]; pagination: any }>
  ) => {
    if (loading) return;
    
    setLoading(true);
    setError(null);
    
    try {
      const result = await apiCall();
      setData(prev => [...prev, ...result.data]);
      setPagination(result.pagination);
      return result;
    } catch (err) {
      const errorMessage = err instanceof ApiError ? err.message : 'An error occurred';
      setError(errorMessage);
      throw err;
    } finally {
      setLoading(false);
    }
  }, [loading]);

  const reset = useCallback(() => {
    setData(initialData);
    setPagination(initialPagination);
    setError(null);
    setLoading(false);
  }, [initialData, initialPagination]);

  return {
    data,
    pagination,
    loading,
    error,
    execute,
    loadMore,
    reset,
    setData,
    setPagination
  };
}

// Hook for handling async operations with loading states
export function useAsyncOperation() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const execute = useCallback(async <T>(operation: () => Promise<T>): Promise<T | null> => {
    setLoading(true);
    setError(null);
    
    try {
      const result = await operation();
      return result;
    } catch (err) {
      const errorMessage = err instanceof ApiError ? err.message : 'An error occurred';
      setError(errorMessage);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  const reset = useCallback(() => {
    setError(null);
    setLoading(false);
  }, []);

  return {
    loading,
    error,
    execute,
    reset
  };
}

// Hook for debounced API calls (useful for search)
export function useDebouncedApi<T>(
  apiCall: (query: string) => Promise<T>,
  delay: number = 300
) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const execute = useCallback(
    debounce(async (query: string) => {
      if (!query.trim()) {
        setData(null);
        return;
      }

      setLoading(true);
      setError(null);
      
      try {
        const result = await apiCall(query);
        setData(result);
      } catch (err) {
        const errorMessage = err instanceof ApiError ? err.message : 'Search failed';
        setError(errorMessage);
      } finally {
        setLoading(false);
      }
    }, delay),
    [apiCall, delay]
  );

  return {
    data,
    loading,
    error,
    execute
  };
}

// Debounce utility function
function debounce<T extends (...args: any[]) => any>(
  func: T,
  delay: number
): (...args: Parameters<T>) => void {
  let timeoutId: NodeJS.Timeout;
  
  return (...args: Parameters<T>) => {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => func(...args), delay);
  };
}

// Hook for handling form submissions with API calls
export function useFormSubmission<T>() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const submit = useCallback(async (apiCall: () => Promise<T>): Promise<T | null> => {
    setLoading(true);
    setError(null);
    setSuccess(false);
    
    try {
      const result = await apiCall();
      setSuccess(true);
      return result;
    } catch (err) {
      const errorMessage = err instanceof ApiError ? err.message : 'Submission failed';
      setError(errorMessage);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  const reset = useCallback(() => {
    setError(null);
    setLoading(false);
    setSuccess(false);
  }, []);

  return {
    loading,
    error,
    success,
    submit,
    reset
  };
}

// Hook for periodic data refresh
export function usePeriodicRefresh<T>(
  apiCall: () => Promise<T>,
  interval: number = 30000, // 30 seconds default
  enabled: boolean = true
) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);

  const refresh = useCallback(async () => {
    if (loading) return;
    
    setLoading(true);
    setError(null);
    
    try {
      const result = await apiCall();
      setData(result);
      setLastUpdated(new Date());
    } catch (err) {
      const errorMessage = err instanceof ApiError ? err.message : 'Refresh failed';
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  }, [apiCall, loading]);

  useEffect(() => {
    if (!enabled) return;

    // Initial load
    refresh();

    // Set up periodic refresh
    const intervalId = setInterval(refresh, interval);

    return () => clearInterval(intervalId);
  }, [refresh, interval, enabled]);

  return {
    data,
    loading,
    error,
    lastUpdated,
    refresh
  };
}
