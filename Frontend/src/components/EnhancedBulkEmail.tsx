import React, { useState, useEffect } from 'react';
import { adminService } from '../services/adminService';
import LoadingSpinner from './LoadingSpinner';
import ErrorMessage from './ErrorMessage';
import './EnhancedBulkEmail.css';

interface BulkEmailFilters {
  minPoints: number;
  status: 'all' | 'active' | 'inactive';
  registrationDateRange: {
    start: string;
    end: string;
  };
  includeAdmins: boolean;
}

const EnhancedBulkEmail: React.FC = () => {
  const [emailData, setEmailData] = useState({
    subject: '',
    body: ''
  });

  const [filters, setFilters] = useState<BulkEmailFilters>({
    minPoints: 0,
    status: 'all',
    registrationDateRange: {
      start: '',
      end: ''
    },
    includeAdmins: false
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [previewMode, setPreviewMode] = useState(false);
  const [estimatedRecipients, setEstimatedRecipients] = useState<number | null>(null);

  // Email templates
  const [selectedTemplate, setSelectedTemplate] = useState('');
  const emailTemplates = {
    welcome: {
      subject: 'Welcome to LawVriksh!',
      body: 'Dear {name},\n\nWelcome to LawVriksh! We\'re excited to have you on board.\n\nBest regards,\nThe LawVriksh Team'
    },
    update: {
      subject: 'Important Update from LawVriksh',
      body: 'Dear {name},\n\nWe have an important update to share with you.\n\n[Your update content here]\n\nBest regards,\nThe LawVriksh Team'
    },
    promotion: {
      subject: 'Special Promotion for LawVriksh Members',
      body: 'Dear {name},\n\nWe have a special promotion just for you!\n\n[Promotion details here]\n\nBest regards,\nThe LawVriksh Team'
    }
  };

  useEffect(() => {
    // Estimate recipients when filters change
    estimateRecipients();
  }, [filters]);

  const estimateRecipients = async () => {
    try {
      // This would normally call an API endpoint to get recipient count
      // For now, we'll use a mock calculation
      let count = 100; // Base user count
      
      if (filters.status === 'active') count = Math.floor(count * 0.8);
      if (filters.status === 'inactive') count = Math.floor(count * 0.2);
      if (filters.minPoints > 0) count = Math.floor(count * 0.6);
      if (!filters.includeAdmins) count = Math.floor(count * 0.95);
      
      setEstimatedRecipients(count);
    } catch (err) {
      console.error('Failed to estimate recipients:', err);
    }
  };

  const handleTemplateSelect = (templateKey: string) => {
    if (templateKey && emailTemplates[templateKey as keyof typeof emailTemplates]) {
      const template = emailTemplates[templateKey as keyof typeof emailTemplates];
      setEmailData({
        subject: template.subject,
        body: template.body
      });
      setSelectedTemplate(templateKey);
    }
  };

  const handleSendEmail = async () => {
    if (!emailData.subject || !emailData.body) {
      setError('Please fill in both subject and body');
      return;
    }

    try {
      setLoading(true);
      setError(null);
      setSuccess(null);

      const bulkEmailRequest = {
        subject: emailData.subject,
        body: emailData.body,
        min_points: filters.minPoints
      };

      const result = await adminService.sendBulkEmail(bulkEmailRequest);
      
      if (result) {
        setSuccess(`Email sent successfully to ${result.recipients} recipients!`);
        // Reset form
        setEmailData({ subject: '', body: '' });
        setSelectedTemplate('');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to send bulk email');
    } finally {
      setLoading(false);
    }
  };

  const handlePreview = () => {
    setPreviewMode(true);
  };

  const formatEmailBody = (body: string) => {
    // Replace placeholders with sample data for preview
    return body
      .replace(/{name}/g, 'John Doe')
      .replace(/{email}/g, 'john.doe@example.com')
      .replace(/{points}/g, '25');
  };

  return (
    <div className="bulk-email-container">
      <div className="bulk-email-header">
        <h3 className="bulk-email-title">Enhanced Bulk Email Campaign</h3>
        <p className="bulk-email-subtitle">
          Send targeted emails to users based on various criteria
        </p>
      </div>

      <div className="bulk-email-content">
        {error && <ErrorMessage message={error} />}
        {success && (
          <div className="bulk-email-success">
            <div className="bulk-email-success-content">
              <div className="bulk-email-success-icon">
                <svg className="h-5 w-5 text-green-400" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="bulk-email-success-text">
                <p className="bulk-email-success-message">{success}</p>
              </div>
            </div>
          </div>
        )}

        {/* Email Templates */}
        <div className="bulk-email-templates">
          <label className="bulk-email-label">
            Email Templates (Optional)
          </label>
          <select
            value={selectedTemplate}
            onChange={(e) => handleTemplateSelect(e.target.value)}
            className="bulk-email-select"
          >
            <option value="">Select a template...</option>
            <option value="welcome">Welcome Email</option>
            <option value="update">Important Update</option>
            <option value="promotion">Special Promotion</option>
          </select>
        </div>

        {/* Email Content */}
        <div className="bulk-email-grid">
          <div className="bulk-email-form-section">
            <div className="bulk-email-form-group">
              <label className="bulk-email-label">
                Subject Line
              </label>
              <input
                type="text"
                value={emailData.subject}
                onChange={(e) => setEmailData(prev => ({ ...prev, subject: e.target.value }))}
                placeholder="Enter email subject"
                className="bulk-email-input"
                disabled={loading}
              />
            </div>

            <div className="bulk-email-form-group">
              <label className="bulk-email-label">
                Email Body
              </label>
              <textarea
                value={emailData.body}
                onChange={(e) => setEmailData(prev => ({ ...prev, body: e.target.value }))}
                placeholder="Enter email content. Use {name}, {email}, {points} as placeholders."
                rows={8}
                className="bulk-email-textarea"
                disabled={loading}
              />
              <p className="bulk-email-placeholder-hint">
                Available placeholders: {'{name}'}, {'{email}'}, {'{points}'}
              </p>
            </div>
          </div>

          {/* Recipient Filters */}
          <div className="bulk-email-filters">
            <h4 className="bulk-email-filters-title">Recipient Filters</h4>

            <div className="bulk-email-form-group">
              <label className="bulk-email-label">
                Minimum Points
              </label>
              <input
                type="number"
                value={filters.minPoints}
                onChange={(e) => setFilters(prev => ({ ...prev, minPoints: parseInt(e.target.value) || 0 }))}
                min="0"
                className="bulk-email-input"
              />
            </div>

            <div className="bulk-email-form-group">
              <label className="bulk-email-label">
                User Status
              </label>
              <select
                value={filters.status}
                onChange={(e) => setFilters(prev => ({ ...prev, status: e.target.value as any }))}
                className="bulk-email-select"
              >
                <option value="all">All Users</option>
                <option value="active">Active Users Only</option>
                <option value="inactive">Inactive Users Only</option>
              </select>
            </div>

            <div className="bulk-email-form-group">
              <label className="bulk-email-label">
                Registration Date Range
              </label>
              <div className="bulk-email-date-grid">
                <input
                  type="date"
                  value={filters.registrationDateRange.start}
                  onChange={(e) => setFilters(prev => ({
                    ...prev,
                    registrationDateRange: { ...prev.registrationDateRange, start: e.target.value }
                  }))}
                  className="bulk-email-input"
                />
                <input
                  type="date"
                  value={filters.registrationDateRange.end}
                  onChange={(e) => setFilters(prev => ({
                    ...prev,
                    registrationDateRange: { ...prev.registrationDateRange, end: e.target.value }
                  }))}
                  className="bulk-email-input"
                />
              </div>
            </div>

            <div className="bulk-email-checkbox-group">
              <input
                type="checkbox"
                id="includeAdmins"
                checked={filters.includeAdmins}
                onChange={(e) => setFilters(prev => ({ ...prev, includeAdmins: e.target.checked }))}
                className="bulk-email-checkbox"
              />
              <label htmlFor="includeAdmins" className="bulk-email-checkbox-label">
                Include admin users
              </label>
            </div>

            {/* Estimated Recipients */}
            {estimatedRecipients !== null && (
              <div className="bulk-email-recipients-info">
                <p className="bulk-email-recipients-text">
                  <span className="bulk-email-recipients-count">Estimated Recipients:</span> {estimatedRecipients} users
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Actions */}
        <div className="bulk-email-actions">
          <button
            onClick={handlePreview}
            disabled={!emailData.subject || !emailData.body}
            className="bulk-email-button preview"
          >
            Preview Email
          </button>
          <button
            onClick={handleSendEmail}
            disabled={loading || !emailData.subject || !emailData.body}
            className="bulk-email-button send"
          >
            {loading ? (
              <div className="bulk-email-button-content">
                <LoadingSpinner size="small" />
                <span className="bulk-email-button-text">Sending...</span>
              </div>
            ) : (
              'Send Bulk Email'
            )}
          </button>
        </div>

        {/* Preview Modal */}
        {previewMode && (
          <div className="bulk-email-modal-overlay">
            <div className="bulk-email-modal-container">
              <div className="bulk-email-modal-content">
                <h3 className="bulk-email-modal-title">Email Preview</h3>

                <div className="bulk-email-preview-container">
                  <div className="bulk-email-preview-subject">
                    <strong className="bulk-email-preview-subject-label">Subject:</strong>
                    <p className="bulk-email-preview-subject-text">{emailData.subject}</p>
                  </div>

                  <div>
                    <strong className="bulk-email-preview-body-label">Body:</strong>
                    <div className="bulk-email-preview-body">
                      {formatEmailBody(emailData.body)}
                    </div>
                  </div>
                </div>

                <div className="bulk-email-modal-actions">
                  <button
                    onClick={() => setPreviewMode(false)}
                    className="bulk-email-modal-button cancel"
                  >
                    Close Preview
                  </button>
                  <button
                    onClick={() => {
                      setPreviewMode(false);
                      handleSendEmail();
                    }}
                    disabled={loading}
                    className="bulk-email-modal-button send"
                  >
                    Send Email
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default EnhancedBulkEmail;
