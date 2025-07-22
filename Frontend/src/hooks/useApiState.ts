import { useState, useCallback } from 'react';

export interface ApiState<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
}

export interface UseApiStateReturn<T> {
  state: ApiState<T>;
  execute: (apiCall: () => Promise<T>) => Promise<T | null>;
  reset: () => void;
  setData: (data: T) => void;
  setError: (error: string) => void;
  setLoading: (loading: boolean) => void;
}

/**
 * Custom hook for managing API call states (loading, error, data)
 */
export function useApiState<T = any>(initialData: T | null = null): UseApiStateReturn<T> {
  const [state, setState] = useState<ApiState<T>>({
    data: initialData,
    loading: false,
    error: null,
  });

  const execute = useCallback(async (apiCall: () => Promise<T>): Promise<T | null> => {
    setState(prev => ({ ...prev, loading: true, error: null }));
    
    try {
      const result = await apiCall();
      setState(prev => ({ ...prev, data: result, loading: false, error: null }));
      return result;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'An unexpected error occurred';
      setState(prev => ({ ...prev, loading: false, error: errorMessage }));
      return null;
    }
  }, []);

  const reset = useCallback(() => {
    setState({
      data: initialData,
      loading: false,
      error: null,
    });
  }, [initialData]);

  const setData = useCallback((data: T) => {
    setState(prev => ({ ...prev, data, error: null }));
  }, []);

  const setError = useCallback((error: string) => {
    setState(prev => ({ ...prev, error, loading: false }));
  }, []);

  const setLoading = useCallback((loading: boolean) => {
    setState(prev => ({ ...prev, loading }));
  }, []);

  return {
    state,
    execute,
    reset,
    setData,
    setError,
    setLoading,
  };
}

/**
 * Hook for managing multiple API states
 */
export function useMultipleApiStates<T extends Record<string, any>>(): {
  states: { [K in keyof T]: ApiState<T[K]> };
  execute: <K extends keyof T>(key: K, apiCall: () => Promise<T[K]>) => Promise<T[K] | null>;
  reset: (key?: keyof T) => void;
  setData: <K extends keyof T>(key: K, data: T[K]) => void;
  setError: (key: keyof T, error: string) => void;
  setLoading: (key: keyof T, loading: boolean) => void;
} {
  const [states, setStates] = useState<{ [K in keyof T]: ApiState<T[K]> }>({} as any);

  const execute = useCallback(async <K extends keyof T>(
    key: K,
    apiCall: () => Promise<T[K]>
  ): Promise<T[K] | null> => {
    setStates(prev => ({
      ...prev,
      [key]: { ...prev[key], loading: true, error: null }
    }));

    try {
      const result = await apiCall();
      setStates(prev => ({
        ...prev,
        [key]: { data: result, loading: false, error: null }
      }));
      return result;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'An unexpected error occurred';
      setStates(prev => ({
        ...prev,
        [key]: { ...prev[key], loading: false, error: errorMessage }
      }));
      return null;
    }
  }, []);

  const reset = useCallback((key?: keyof T) => {
    if (key) {
      setStates(prev => ({
        ...prev,
        [key]: { data: null, loading: false, error: null }
      }));
    } else {
      setStates({} as any);
    }
  }, []);

  const setData = useCallback(<K extends keyof T>(key: K, data: T[K]) => {
    setStates(prev => ({
      ...prev,
      [key]: { ...prev[key], data, error: null }
    }));
  }, []);

  const setError = useCallback((key: keyof T, error: string) => {
    setStates(prev => ({
      ...prev,
      [key]: { ...prev[key], error, loading: false }
    }));
  }, []);

  const setLoading = useCallback((key: keyof T, loading: boolean) => {
    setStates(prev => ({
      ...prev,
      [key]: { ...prev[key], loading }
    }));
  }, []);

  return {
    states,
    execute,
    reset,
    setData,
    setError,
    setLoading,
  };
}

/**
 * Hook for handling form submissions with API calls
 */
export function useApiForm<T, R = any>(
  submitFn: (data: T) => Promise<R>,
  onSuccess?: (result: R) => void,
  onError?: (error: string) => void
) {
  const { state, execute } = useApiState<R>();

  const handleSubmit = useCallback(async (data: T) => {
    const result = await execute(() => submitFn(data));
    
    if (result) {
      onSuccess?.(result);
    } else if (state.error) {
      onError?.(state.error);
    }
    
    return result;
  }, [execute, submitFn, onSuccess, onError, state.error]);

  return {
    ...state,
    handleSubmit,
  };
}

export default useApiState;
