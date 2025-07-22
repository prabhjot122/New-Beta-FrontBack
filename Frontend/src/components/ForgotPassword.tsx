import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { authService } from '../services/authService';
import LoadingSpinner from './LoadingSpinner';
import ErrorMessage from './ErrorMessage';
import './ForgotPassword.css';

const ForgotPassword: React.FC = () => {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!email) {
      setError('Please enter your email address');
      return;
    }

    try {
      setLoading(true);
      setError(null);
      
      const response = await authService.forgotPassword(email);
      
      if (response.success) {
        setSuccess(true);
      } else {
        setError(response.message || 'Failed to send reset email');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to send reset email');
    } finally {
      setLoading(false);
    }
  };

  if (success) {
    return (
      <div className="forgot-password-container">
        <div className="forgot-password-card">
          <div className="forgot-password-success">
            <div className="forgot-password-success-icon">
              <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <h2 className="forgot-password-success-title">Check your email</h2>
            <p className="forgot-password-success-text">
              We've sent password reset instructions to <strong>{email}</strong>
            </p>
          </div>

          <div className="forgot-password-info-box">
            <div className="forgot-password-info-header">
              <div className="forgot-password-info-icon">
                <svg fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="forgot-password-info-content">
                <h3>What's next?</h3>
                <ul className="forgot-password-info-list">
                  <li>Check your email inbox (and spam folder)</li>
                  <li>Click the reset link in the email</li>
                  <li>Create a new password</li>
                </ul>
              </div>
            </div>
          </div>

          <div className="forgot-password-actions">
            <p>
              Didn't receive the email?{' '}
              <button
                onClick={() => {
                  setSuccess(false);
                  setEmail('');
                }}
                className="forgot-password-retry-button"
              >
                Try again
              </button>
            </p>
            <p>
              <Link to="/admin/login" className="forgot-password-link">
                Back to login
              </Link>
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="forgot-password-container">
      <div className="forgot-password-card">
        <div className="forgot-password-header">
          <div className="forgot-password-icon">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
            </svg>
          </div>
          <h2 className="forgot-password-title">
            Forgot your password?
          </h2>
          <p className="forgot-password-subtitle">
            No worries! Enter your email address and we'll send you a link to reset your password.
          </p>
        </div>

        <form className="forgot-password-form" onSubmit={handleSubmit}>
          {error && <ErrorMessage message={error} />}

          <div className="forgot-password-field">
            <label htmlFor="email" className="forgot-password-label">
              Email address
            </label>
            <input
              id="email"
              name="email"
              type="email"
              autoComplete="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="forgot-password-input"
              placeholder="Enter your email address"
            />
          </div>

          <div className="forgot-password-field">
            <button
              type="submit"
              disabled={loading}
              className="forgot-password-button"
            >
              {loading ? (
                <LoadingSpinner size="small" />
              ) : (
                'Send reset instructions'
              )}
            </button>
          </div>

          <div className="forgot-password-links">
            <Link
              to="/admin/login"
              className="forgot-password-link"
            >
              Back to login
            </Link>
          </div>
        </form>
      </div>
    </div>
  );
};

export default ForgotPassword;
