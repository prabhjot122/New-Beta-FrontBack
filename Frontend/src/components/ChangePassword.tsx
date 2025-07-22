import React, { useState } from 'react';
import { authService } from '../services/authService';
import LoadingSpinner from './LoadingSpinner';
import ErrorMessage from './ErrorMessage';
import './ChangePassword.css';

interface ChangePasswordProps {
  onClose?: () => void;
  onSuccess?: () => void;
}

const ChangePassword: React.FC<ChangePasswordProps> = ({ onClose, onSuccess }) => {
  const [formData, setFormData] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: ''
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [showPasswords, setShowPasswords] = useState(false);
  const [passwordStrength, setPasswordStrength] = useState<any>(null);

  React.useEffect(() => {
    if (formData.newPassword) {
      const strength = authService.checkPasswordStrength(formData.newPassword);
      setPasswordStrength(strength);
    } else {
      setPasswordStrength(null);
    }
  }, [formData.newPassword]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.currentPassword) {
      setError('Please enter your current password');
      return;
    }

    if (!formData.newPassword) {
      setError('Please enter a new password');
      return;
    }

    if (formData.newPassword !== formData.confirmPassword) {
      setError('New passwords do not match');
      return;
    }

    if (passwordStrength && !passwordStrength.isValid) {
      setError('Please choose a stronger password');
      return;
    }

    try {
      setLoading(true);
      setError(null);
      
      const response = await authService.changePassword(
        formData.currentPassword,
        formData.newPassword
      );
      
      if (response.success) {
        setSuccess(true);
        setFormData({
          currentPassword: '',
          newPassword: '',
          confirmPassword: ''
        });
        
        if (onSuccess) {
          setTimeout(() => {
            onSuccess();
          }, 2000);
        }
      } else {
        setError(response.message || 'Failed to change password');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to change password');
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (field: keyof typeof formData, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    setError(null);
  };

  if (success) {
    return (
      <div className="change-password-success">
        <div className="change-password-success-content">
          <div className="change-password-success-icon">
            <svg className="h-6 w-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h3 className="change-password-success-title">Password Changed Successfully</h3>
          <p className="change-password-success-text">
            Your password has been updated successfully.
          </p>
          {onClose && (
            <button
              onClick={onClose}
              className="change-password-success-button"
            >
              Close
            </button>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="change-password-container">
      <div className="change-password-header">
        <div className="change-password-header-content">
          <h3 className="change-password-title">Change Password</h3>
          {onClose && (
            <button
              onClick={onClose}
              className="change-password-close"
            >
              <svg className="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          )}
        </div>
      </div>

      <form onSubmit={handleSubmit} className="change-password-form">
        {error && <ErrorMessage message={error} />}

        <div className="change-password-form-group">
          <label htmlFor="currentPassword" className="change-password-label">
            Current Password
          </label>
          <div className="change-password-input-wrapper">
            <input
              id="currentPassword"
              type={showPasswords ? 'text' : 'password'}
              value={formData.currentPassword}
              onChange={(e) => handleInputChange('currentPassword', e.target.value)}
              className="change-password-input"
              placeholder="Enter your current password"
              disabled={loading}
              required
            />
          </div>
        </div>

        <div className="change-password-form-group">
          <label htmlFor="newPassword" className="change-password-label">
            New Password
          </label>
          <div className="change-password-input-wrapper">
            <input
              id="newPassword"
              type={showPasswords ? 'text' : 'password'}
              value={formData.newPassword}
              onChange={(e) => handleInputChange('newPassword', e.target.value)}
              className="change-password-input"
              placeholder="Enter your new password"
              disabled={loading}
              required
            />
          </div>
          
          {/* Password Strength Indicator */}
          {passwordStrength && (
            <div className="change-password-strength">
              <div className="change-password-strength-bar-container">
                <div className="change-password-strength-bar">
                  <div
                    className={`change-password-strength-fill ${
                      passwordStrength.score <= 1 ? 'weak' :
                      passwordStrength.score <= 2 ? 'fair' :
                      passwordStrength.score <= 3 ? 'good' :
                      'strong'
                    }`}
                    style={{ width: `${(passwordStrength.score / 5) * 100}%` }}
                  ></div>
                </div>
                <span className={`change-password-strength-text ${
                  passwordStrength.score <= 1 ? 'weak' :
                  passwordStrength.score <= 2 ? 'fair' :
                  passwordStrength.score <= 3 ? 'good' :
                  'strong'
                }`}>
                  {passwordStrength.feedback[0] || 'Password strength'}
                </span>
              </div>
              {passwordStrength.feedback.length > 1 && (
                <div className="change-password-feedback">
                  {passwordStrength.feedback.slice(1).map((feedback: string, index: number) => (
                    <p key={index} className="change-password-feedback-item">
                      {feedback}
                    </p>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        <div className="change-password-form-group">
          <label htmlFor="confirmPassword" className="change-password-label">
            Confirm New Password
          </label>
          <div className="change-password-input-wrapper">
            <input
              id="confirmPassword"
              type={showPasswords ? 'text' : 'password'}
              value={formData.confirmPassword}
              onChange={(e) => handleInputChange('confirmPassword', e.target.value)}
              className="change-password-input"
              placeholder="Confirm your new password"
              disabled={loading}
              required
            />
          </div>
          {formData.confirmPassword && formData.newPassword !== formData.confirmPassword && (
            <p className="change-password-mismatch">Passwords do not match</p>
          )}
        </div>

        <div className="change-password-checkbox-group">
          <input
            type="checkbox"
            id="showPasswords"
            checked={showPasswords}
            onChange={(e) => setShowPasswords(e.target.checked)}
            className="change-password-checkbox"
          />
          <label htmlFor="showPasswords" className="change-password-checkbox-label">
            Show passwords
          </label>
        </div>

        <div className="change-password-actions">
          {onClose && (
            <button
              type="button"
              onClick={onClose}
              className="change-password-button cancel"
              disabled={loading}
            >
              Cancel
            </button>
          )}
          <button
            type="submit"
            disabled={
              loading ||
              !formData.currentPassword ||
              !formData.newPassword ||
              !formData.confirmPassword ||
              formData.newPassword !== formData.confirmPassword ||
              (passwordStrength && !passwordStrength.isValid)
            }
            className="change-password-button submit"
          >
            {loading ? (
              <div className="change-password-button-content">
                <LoadingSpinner size="small" />
                <span className="change-password-button-text">Changing...</span>
              </div>
            ) : (
              'Change Password'
            )}
          </button>
        </div>
      </form>
    </div>
  );
};

export default ChangePassword;
