import React, { useState, useEffect } from 'react';
import { campaignService } from '../services/campaignService';
import { 
  CampaignScheduleResponse, 
  CampaignSendRequest, 
  NewUserCampaignsResponse 
} from '../types/api';
import LoadingSpinner from './LoadingSpinner';
import ErrorMessage from './ErrorMessage';
import './CampaignManagement.css';

const CampaignManagement: React.FC = () => {
  const [schedule, setSchedule] = useState<CampaignScheduleResponse | null>(null);
  const [newUserPreview, setNewUserPreview] = useState<NewUserCampaignsResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [sendingCampaign, setSendingCampaign] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'schedule' | 'send' | 'preview'>('schedule');

  // Form states
  const [selectedCampaign, setSelectedCampaign] = useState('welcome');
  const [sendType, setSendType] = useState<'bulk' | 'individual'>('bulk');
  const [userEmail, setUserEmail] = useState('');
  const [userName, setUserName] = useState('');

  useEffect(() => {
    loadCampaignData();
  }, []);

  const loadCampaignData = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const [scheduleData, previewData] = await Promise.all([
        campaignService.getCampaignSchedule(),
        campaignService.getNewUserCampaignsPreview()
      ]);
      
      setSchedule(scheduleData);
      setNewUserPreview(previewData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load campaign data');
    } finally {
      setLoading(false);
    }
  };

  const handleSendCampaign = async () => {
    if (!selectedCampaign) return;
    
    try {
      setSendingCampaign(selectedCampaign);
      setError(null);

      const request: CampaignSendRequest = {
        campaign_type: selectedCampaign,
        ...(sendType === 'individual' && {
          user_email: userEmail,
          user_name: userName
        })
      };

      const response = await campaignService.sendCampaign(request);
      
      if (response.success) {
        alert(`✅ ${response.message}`);
        // Reset form
        setUserEmail('');
        setUserName('');
      } else {
        throw new Error(response.message);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to send campaign');
    } finally {
      setSendingCampaign(null);
    }
  };

  const handleTestCampaign = async (campaignType: string) => {
    try {
      setSendingCampaign(campaignType);
      setError(null);
      
      const response = await campaignService.sendTestCampaign(campaignType);
      
      if (response.success) {
        alert(`✅ Test campaign sent: ${response.message}`);
      } else {
        throw new Error(response.message);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to send test campaign');
    } finally {
      setSendingCampaign(null);
    }
  };

  if (loading) {
    return (
      <div className="campaign-loading">
        <LoadingSpinner />
      </div>
    );
  }

  return (
    <div className="campaign-management">
      <div className="campaign-tabs">
        <nav>
          {[
            { key: 'schedule', label: 'Campaign Schedule' },
            { key: 'send', label: 'Send Campaign' },
            { key: 'preview', label: 'New User Preview' }
          ].map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key as any)}
              className={`campaign-tab ${activeTab === tab.key ? 'active' : ''}`}
            >
              {tab.label}
            </button>
          ))}
        </nav>
      </div>

      <div className="campaign-content">
        {error && <ErrorMessage message={error} />}

        {activeTab === 'schedule' && schedule && (
          <div className="campaign-schedule-section">
            <div className="campaign-schedule-header">
              <h3 className="campaign-schedule-title">Campaign Schedule Overview</h3>
              <button
                onClick={loadCampaignData}
                className="campaign-refresh-button"
              >
                Refresh
              </button>
            </div>

            <div className="campaign-schedule-grid">
              {Object.entries(schedule.campaigns).map(([type, campaign]) => {
                const isDue = campaignService.isCampaignDue(campaign.schedule);
                // const statusColor = campaignService.getStatusColor(campaign.status, isDue);

                return (
                  <div key={type} className="campaign-schedule-item">
                    <div className="campaign-schedule-item-header">
                      <div className="campaign-schedule-item-content">
                        <div className="campaign-schedule-item-title-section">
                          <h4 className="campaign-schedule-item-title">
                            {type.replace('_', ' ')}
                          </h4>
                          <span className={`campaign-status-badge ${campaign.status}`}>
                            {campaign.status}
                          </span>
                          {isDue && (
                            <span className="campaign-due-badge">
                              Due
                            </span>
                          )}
                        </div>
                        <p className="campaign-schedule-item-subject">{campaign.subject}</p>
                        <p className="campaign-schedule-item-schedule">
                          Schedule: {campaignService.formatSchedule(campaign.schedule)}
                        </p>
                      </div>
                      <button
                        onClick={() => handleTestCampaign(type)}
                        disabled={sendingCampaign === type}
                        className="campaign-test-button"
                      >
                        {sendingCampaign === type ? 'Sending...' : 'Test Send'}
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>

            {schedule.due_campaigns.length > 0 && (
              <div className="campaign-due-campaigns">
                <h4 className="campaign-due-campaigns-title">Due Campaigns</h4>
                <p className="campaign-due-campaigns-text">
                  The following campaigns are due to be sent: {schedule.due_campaigns.join(', ')}
                </p>
              </div>
            )}
          </div>
        )}

        {activeTab === 'send' && (
          <div className="campaign-send-section">
            <h3 className="campaign-send-title">Send Campaign Manually</h3>

            <div className="campaign-send-grid">
              <div className="campaign-send-form-group">
                <label className="campaign-send-label">
                  Campaign Type
                </label>
                <select
                  value={selectedCampaign}
                  onChange={(e) => setSelectedCampaign(e.target.value)}
                  className="campaign-send-select"
                >
                  {campaignService.getCampaignTypes().map((type) => (
                    <option key={type} value={type}>
                      {type.replace('_', ' ').toUpperCase()}
                    </option>
                  ))}
                </select>
              </div>

              <div className="campaign-send-form-group">
                <label className="campaign-send-label">
                  Send Type
                </label>
                <select
                  value={sendType}
                  onChange={(e) => setSendType(e.target.value as 'bulk' | 'individual')}
                  className="campaign-send-select"
                >
                  <option value="bulk">Bulk (All Users)</option>
                  <option value="individual">Individual User</option>
                </select>
              </div>
            </div>

            {sendType === 'individual' && (
              <div className="campaign-send-grid">
                <div className="campaign-send-form-group">
                  <label className="campaign-send-label">
                    User Email
                  </label>
                  <input
                    type="email"
                    value={userEmail}
                    onChange={(e) => setUserEmail(e.target.value)}
                    placeholder="user@example.com"
                    className="campaign-send-input"
                  />
                </div>

                <div className="campaign-send-form-group">
                  <label className="campaign-send-label">
                    User Name
                  </label>
                  <input
                    type="text"
                    value={userName}
                    onChange={(e) => setUserName(e.target.value)}
                    placeholder="John Doe"
                    className="campaign-send-input"
                  />
                </div>
              </div>
            )}

            <button
              onClick={handleSendCampaign}
              disabled={
                sendingCampaign !== null ||
                (sendType === 'individual' && (!userEmail || !userName))
              }
              className="campaign-send-button"
            >
              {sendingCampaign ? 'Sending...' : `Send ${sendType === 'bulk' ? 'Bulk' : 'Individual'} Campaign`}
            </button>
          </div>
        )}

        {activeTab === 'preview' && newUserPreview && (
          <div className="campaign-preview-section">
            <h3 className="campaign-preview-title">New User Campaign Preview</h3>

            <div className="campaign-preview-grid">
              <div className="campaign-preview-card instant">
                <h4 className="campaign-preview-card-title">Instant Email</h4>
                <p className="campaign-preview-card-note">
                  <strong>{newUserPreview.instant_email.subject}</strong>
                </p>
                <p className="campaign-preview-card-note">
                  {newUserPreview.instant_email.note}
                </p>
              </div>

              <div className="campaign-preview-card future">
                <h4 className="campaign-preview-card-title">
                  Future Campaigns ({newUserPreview.future_campaigns.count})
                </h4>
                <p className="campaign-preview-card-note">
                  {newUserPreview.future_campaigns.note}
                </p>
                <div className="campaign-preview-campaigns-grid">
                  {newUserPreview.future_campaigns.campaigns.map((campaign) => (
                    <div key={campaign.campaign_type} className="campaign-preview-campaign-item">
                      <div className="campaign-preview-campaign-header">
                        <div className="campaign-preview-campaign-content">
                          <p className="campaign-preview-campaign-subject">{campaign.subject}</p>
                          <p className="campaign-preview-campaign-schedule">
                            {campaignService.formatSchedule(campaign.schedule)}
                          </p>
                        </div>
                        <span className="campaign-preview-campaign-badge">
                          {campaign.days_from_now} days
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {newUserPreview.past_campaigns.count > 0 && (
                <div className="campaign-preview-card past">
                  <h4 className="campaign-preview-card-title">
                    Past Campaigns ({newUserPreview.past_campaigns.count})
                  </h4>
                  <p className="campaign-preview-card-note">
                    {newUserPreview.past_campaigns.note}
                  </p>
                  <p className="campaign-preview-past-text">
                    {newUserPreview.past_campaigns.campaigns.join(', ')}
                  </p>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default CampaignManagement;
