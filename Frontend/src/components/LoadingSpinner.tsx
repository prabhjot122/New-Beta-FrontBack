import React from 'react';
import './LoadingSpinner.css';

interface LoadingSpinnerProps {
  size?: 'small' | 'medium' | 'large';
  message?: string;
  className?: string;
  overlay?: boolean;
  fullPage?: boolean;
  transparent?: boolean;
}

const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({
  size = 'medium',
  message,
  className = '',
  overlay = false,
  fullPage = false,
  transparent = false
}) => {
  const spinnerClasses = [
    'loading-spinner',
    size,
    className,
    overlay ? 'overlay' : '',
    fullPage ? 'fullpage' : '',
    transparent ? 'transparent' : '',
  ].filter(Boolean).join(' ');

  return (
    <div className={spinnerClasses}>
      <div className="spinner">
        <div className="spinner-ring"></div>
        <div className="spinner-ring"></div>
        <div className="spinner-ring"></div>
      </div>
      {message && <p className="loading-message">{message}</p>}
    </div>
  );
};

export default LoadingSpinner;
