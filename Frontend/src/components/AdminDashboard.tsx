import React from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { useAdminPanel } from '../hooks/useAdmin';
import LoadingSpinner from './LoadingSpinner';
import ErrorMessage from './ErrorMessage';
import CampaignManagement from './CampaignManagement';
import EnhancedUserManagement from './EnhancedUserManagement';
import ShareAnalytics from './ShareAnalytics';
import EnhancedBulkEmail from './EnhancedBulkEmail';
import ChangePassword from './ChangePassword';
import FeedbackManagement from './FeedbackManagement';
import './AdminDashboard.css';

const AdminDashboard: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const adminPanel = useAdminPanel();
  // const [bulkEmailData, setBulkEmailData] = useState({
  //   subject: '',
  //   body: '',
  //   minPoints: 0
  // });

  const handleLogout = () => {
    logout();
    navigate('/admin/login');
  };

  // const handleExport = async (format: 'csv' | 'json') => {
  //   try {
  //     await adminPanel.userExport.exportUsers(format);
  //   } catch (error) {
  //     console.error('Export failed:', error);
  //   }
  // };

  // const handleBulkEmail = async () => {
  //   try {
  //     const result = await adminPanel.bulkEmail.sendBulkEmail({
  //       subject: bulkEmailData.subject,
  //       body: bulkEmailData.body,
  //       min_points: bulkEmailData.minPoints
  //     });
  //     if (result) {
  //       alert(`Bulk email sent to ${result.recipients} users successfully!`);
  //       setBulkEmailData({ subject: '', body: '', minPoints: 0 });
  //     }
  //   } catch (error) {
  //     console.error('Bulk email failed:', error);
  //     alert('Failed to send bulk email. Please try again.');
  //   }
  // };

  // const handlePromoteUser = async (userId: number) => {
  //   try {
  //     const result = await adminPanel.userPromotion.promoteUser(userId);
  //     if (result) {
  //       alert(result.message);
  //       adminPanel.users.refresh(); // Refresh user list
  //     }
  //   } catch (error) {
  //     console.error('User promotion failed:', error);
  //     alert('Failed to promote user. Please try again.');
  //   }
  // };

  return (
    <div className="admin-dashboard">
      {/* Header */}
      <header className="admin-header">
        <div className="admin-header-content">
          <h1>LawVriksh Admin Panel</h1>
          <div className="admin-user-info">
            <span>Welcome, {user?.name}</span>
            <button onClick={handleLogout} className="logout-btn">Logout</button>
          </div>
        </div>
      </header>

      {/* Navigation Tabs */}
      <nav className="admin-nav">
        <button
          className={adminPanel.activeTab === 'overview' ? 'active' : ''}
          onClick={() => adminPanel.setActiveTab('overview')}
        >
          Overview
        </button>
        <button
          className={adminPanel.activeTab === 'users' ? 'active' : ''}
          onClick={() => adminPanel.setActiveTab('users')}
        >
          Enhanced Users
        </button>
        <button
          className={adminPanel.activeTab === 'email' ? 'active' : ''}
          onClick={() => adminPanel.setActiveTab('email')}
        >
          Enhanced Email
        </button>
        <button
          className={adminPanel.activeTab === 'analytics' ? 'active' : ''}
          onClick={() => adminPanel.setActiveTab('analytics')}
        >
          Share Analytics
        </button>
        <button
          className={adminPanel.activeTab === 'campaigns' ? 'active' : ''}
          onClick={() => adminPanel.setActiveTab('campaigns')}
        >
          Campaigns
        </button>
        <button
          className={adminPanel.activeTab === 'shares' ? 'active' : ''}
          onClick={() => adminPanel.setActiveTab('shares')}
        >
          Share Analytics
        </button>
        <button
          className={adminPanel.activeTab === 'feedback' ? 'active' : ''}
          onClick={() => adminPanel.setActiveTab('feedback')}
        >
          Feedback
        </button>
        <button
          className={adminPanel.activeTab === 'settings' ? 'active' : ''}
          onClick={() => adminPanel.setActiveTab('settings')}
        >
          Settings
        </button>
      </nav>

      {/* Main Content */}
      <main className="admin-main">
        {adminPanel.activeTab === 'overview' && (
          <div className="overview-section">
            <h2>Dashboard Overview</h2>
            {adminPanel.dashboard.loading ? (
              <LoadingSpinner size="large" message="Loading dashboard data..." />
            ) : adminPanel.dashboard.error ? (
              <ErrorMessage
                message={adminPanel.dashboard.error}
                title="Dashboard Error"
                onRetry={adminPanel.dashboard.refresh}
              />
            ) : adminPanel.dashboard.overview ? (
              <>
                <div className="stats-grid">
                  <div className="stat-card">
                    <h3>Total Users</h3>
                    <p className="stat-number">{adminPanel.dashboard.overview.total_users}</p>
                  </div>
                  <div className="stat-card">
                    <h3>Active Users (24h)</h3>
                    <p className="stat-number">{adminPanel.dashboard.overview.active_users_24h}</p>
                  </div>
                  <div className="stat-card">
                    <h3>Shares Today</h3>
                    <p className="stat-number">{adminPanel.dashboard.overview.total_shares_today}</p>
                  </div>
                  <div className="stat-card">
                    <h3>Points Distributed</h3>
                    <p className="stat-number">{adminPanel.dashboard.overview.points_distributed_today}</p>
                  </div>
                </div>

                <div className="platform-breakdown">
                  <h3>Platform Breakdown</h3>
                  <div className="platform-stats">
                    {Object.entries(adminPanel.dashboard.platformBreakdown).map(([platform, data]) => (
                      <div key={platform} className="platform-item">
                        <span className="platform-name">{platform.charAt(0).toUpperCase() + platform.slice(1)}</span>
                        <span className="platform-shares">{data.shares} shares</span>
                        <span className="platform-percentage">{data.percentage}%</span>
                      </div>
                    ))}
                  </div>
                </div>
              </>
            ) : (
              <ErrorMessage
                message="No dashboard data available"
                title="No Data"
                variant="info"
                onRetry={adminPanel.dashboard.refresh}
              />
            )}
          </div>
        )}

        {adminPanel.activeTab === 'users' && (
          <div className="users-section">
            <EnhancedUserManagement />
          </div>
        )}

        {adminPanel.activeTab === 'email' && (
          <div className="email-section">
            <EnhancedBulkEmail />
          </div>
        )}

        {adminPanel.activeTab === 'analytics' && (
          <div className="analytics-section">
            <ShareAnalytics />
          </div>
        )}

        {adminPanel.activeTab === 'campaigns' && (
          <div className="campaigns-section">
            <h2>Campaign Management</h2>
            <CampaignManagement />
          </div>
        )}

        {adminPanel.activeTab === 'shares' && (
          <div className="shares-section">
            <ShareAnalytics />
          </div>
        )}

        {adminPanel.activeTab === 'feedback' && (
          <div className="feedback-section">
            <FeedbackManagement />
          </div>
        )}

        {adminPanel.activeTab === 'settings' && (
          <div className="settings-section">
            <h2>Admin Settings</h2>
            <div className="settings-grid">
              <div className="settings-card">
                <h3>Account Security</h3>
                <ChangePassword />
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
};

export default AdminDashboard;
