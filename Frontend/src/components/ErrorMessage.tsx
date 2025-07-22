import React from 'react';
import './ErrorMessage.css';

interface ErrorMessageProps {
  message: string;
  title?: string;
  onRetry?: () => void;
  className?: string;
  variant?: 'error' | 'warning' | 'info';
}

const ErrorMessage: React.FC<ErrorMessageProps> = ({ 
  message, 
  title = 'Error',
  onRetry,
  className = '',
  variant = 'error'
}) => {
  const getIcon = () => {
    switch (variant) {
      case 'warning':
        return '⚠️';
      case 'info':
        return 'ℹ️';
      default:
        return '❌';
    }
  };

  return (
    <div className={`error-message ${variant} ${className}`}>
      <div className="error-content">
        <div className="error-icon">{getIcon()}</div>
        <div className="error-text">
          <h3 className="error-title">{title}</h3>
          <p className="error-description">{message}</p>
        </div>
      </div>
      {onRetry && (
        <button onClick={onRetry} className="error-retry-btn">
          Try Again
        </button>
      )}
    </div>
  );
};

export default ErrorMessage;
