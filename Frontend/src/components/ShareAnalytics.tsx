import React, { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { shareAnalyticsService } from '../services/shareAnalyticsService';
import { sharesService } from '../services/sharesService';
import { adminService } from '../services/adminService';
import { ShareAnalyticsEnhanced } from '../types/api';
import LoadingSpinner from './LoadingSpinner';
import ErrorMessage from './ErrorMessage';
import './ShareAnalytics.css';

const ShareAnalytics: React.FC = () => {
  const location = useLocation();
  const [analytics, setAnalytics] = useState<ShareAnalyticsEnhanced | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  // Simplified for admin panel - only overview needed

  // Check if we're in admin context
  const isAdminContext = location.pathname.includes('/admin');

  // Simplified for admin panel - removed unused filters

  useEffect(() => {
    loadAnalyticsData();
  }, []);

  // Removed history and platform tabs for admin panel

  const loadAnalyticsData = async () => {
    try {
      setLoading(true);
      setError(null);

      let analyticsData: ShareAnalyticsEnhanced;

      if (isAdminContext) {
        // Use admin service for system-wide analytics
        analyticsData = await adminService.getShareAnalytics();
      } else {
        // Use user service for personal analytics
        analyticsData = await sharesService.getEnhancedAnalytics();
      }

      setAnalytics(analyticsData);
    } catch (err) {
      console.error('Analytics loading error:', err);
      setError(err instanceof Error ? err.message : 'Failed to load analytics');
    } finally {
      setLoading(false);
    }
  };

  // Removed unused functions for simplified admin panel

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getEngagementMetrics = () => {
    if (!analytics || !analytics.platform_breakdown || !analytics.summary) return null;
    try {
      return shareAnalyticsService.calculateEngagementMetrics(analytics);
    } catch (error) {
      console.error('Error calculating engagement metrics:', error);
      return null;
    }
  };

  if (loading && !analytics) {
    return (
      <div className="share-analytics-loading">
        <LoadingSpinner />
      </div>
    );
  }

  const engagementMetrics = getEngagementMetrics();

  return (
    <div className="share-analytics-container">
      {/* Header */}
      <div className="share-analytics-header">
        <div className="share-analytics-header-content">
          <h3 className="share-analytics-title">Share Analytics Overview</h3>
        </div>

        {/* Simplified for admin panel - only overview tab */}
      </div>

      <div className="share-analytics-content">
        {error && <ErrorMessage message={error} />}

        {analytics && analytics.summary && (
          <div className="overview-section">
            {/* Summary Cards */}
            <div className="summary-cards">
              <div className="summary-card blue">
                <h4 className="summary-card-title">Total Shares</h4>
                <p className="summary-card-value">{analytics.summary.total_shares || 0}</p>
              </div>
              <div className="summary-card green">
                <h4 className="summary-card-title">Total Points</h4>
                <p className="summary-card-value">{analytics.summary.total_points || 0}</p>
              </div>
              <div className="summary-card purple">
                <h4 className="summary-card-title">Active Platforms</h4>
                <p className="summary-card-value">{analytics.summary.active_platforms || 0}</p>
              </div>
              <div className="summary-card orange">
                <h4 className="summary-card-title">Avg Points/Share</h4>
                <p className="summary-card-value">
                  {(analytics.summary.average_points_per_share || 0).toFixed(1)}
                </p>
              </div>
            </div>

            {/* Engagement Insights */}
            {engagementMetrics && (
              <div className="engagement-insights">
                <h4 className="engagement-insights-title">Engagement Insights</h4>
                <div className="engagement-insights-grid">
                  <div className="engagement-insight-item">
                    <span className="engagement-insight-label">Most Active Platform:</span>
                    <p className="engagement-insight-value">
                      {shareAnalyticsService.formatPlatformName(engagementMetrics.mostActivePlatform.name)}
                      ({engagementMetrics.mostActivePlatform.shares} shares)
                    </p>
                  </div>
                  <div className="engagement-insight-item">
                    <span className="engagement-insight-label">Highest Earning:</span>
                    <p className="engagement-insight-value">
                      {shareAnalyticsService.formatPlatformName(engagementMetrics.highestEarningPlatform.name)}
                      ({engagementMetrics.highestEarningPlatform.points} points)
                    </p>
                  </div>
                  <div className="engagement-insight-item">
                    <span className="engagement-insight-label">Most Efficient:</span>
                    <p className="engagement-insight-value">
                      {shareAnalyticsService.formatPlatformName(engagementMetrics.mostEfficientPlatform.platform)}
                      ({engagementMetrics.mostEfficientPlatform.efficiency.toFixed(1)} pts/share)
                    </p>
                  </div>
                </div>
              </div>
            )}

            {/* Platform Breakdown */}
            {analytics.platform_breakdown && (
              <div className="platform-breakdown-section">
                <h4 className="platform-breakdown-title">Platform Breakdown</h4>
                <div className="platform-breakdown-grid">
                  {Object.entries(analytics.platform_breakdown).map(([platform, data]) => (
                  <div key={platform} className="platform-breakdown-item">
                    <div className="platform-breakdown-header">
                      <div className="platform-breakdown-name-section">
                        <span className="platform-breakdown-icon">{shareAnalyticsService.getPlatformIcon(platform)}</span>
                        <h5 className="platform-breakdown-name">
                          {shareAnalyticsService.formatPlatformName(platform)}
                        </h5>
                      </div>
                      <span className="platform-breakdown-percentage">{data.percentage.toFixed(1)}%</span>
                    </div>

                    <div className="platform-breakdown-stats">
                      <div className="platform-breakdown-stat">
                        <span className="platform-breakdown-stat-label">Shares:</span>
                        <p className="platform-breakdown-stat-value">{data.shares}</p>
                      </div>
                      <div className="platform-breakdown-stat">
                        <span className="platform-breakdown-stat-label">Points:</span>
                        <p className="platform-breakdown-stat-value">{data.points}</p>
                      </div>
                      <div className="platform-breakdown-stat">
                        <span className="platform-breakdown-stat-label">First Share:</span>
                        <p className="platform-breakdown-stat-value">
                          {data.first_share_date ? formatDate(data.first_share_date) : 'N/A'}
                        </p>
                      </div>
                      <div className="platform-breakdown-stat">
                        <span className="platform-breakdown-stat-label">Last Share:</span>
                        <p className="platform-breakdown-stat-value">
                          {data.last_share_date ? formatDate(data.last_share_date) : 'N/A'}
                        </p>
                      </div>
                    </div>

                    {/* Progress bar */}
                    <div className="platform-breakdown-progress">
                      <div className="platform-breakdown-progress-bar">
                        <div
                          className="platform-breakdown-progress-fill"
                          style={{
                            width: `${data.percentage}%`,
                            backgroundColor: shareAnalyticsService.getPlatformColor(platform)
                          }}
                        ></div>
                      </div>
                    </div>
                  </div>
                  ))}
                </div>
              </div>
            )}

            {/* Timeline Chart */}
            {analytics.timeline.length > 0 && (
              <div className="timeline-section">
                <h4 className="timeline-title">Share Timeline</h4>
                <div className="timeline-chart">
                  <div className="timeline-grid">
                    {analytics.timeline.slice(-7).map((day, index) => (
                      <div key={index} className="timeline-day">
                        <div className="timeline-day-label">
                          {new Date(day.date).toLocaleDateString('en-US', { weekday: 'short' })}
                        </div>
                        <div className="timeline-day-data">
                          <div className="timeline-day-shares">{day.shares}</div>
                          <div className="timeline-day-points">{day.points} pts</div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </div>
        )}




      </div>
    </div>
  );
};

export default ShareAnalytics;
