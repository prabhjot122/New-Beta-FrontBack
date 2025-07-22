import React, { useState, useEffect } from 'react';
import { feedbackService, FeedbackResponse, FeedbackExportFilters } from '../services/feedbackService';
import LoadingSpinner from './LoadingSpinner';
import ErrorMessage from './ErrorMessage';
import './FeedbackManagement.css';

interface FeedbackStats {
  total_responses: number;
  responses_by_hurdle: Record<string, number>;
  responses_by_motivation: Record<string, number>;
  responses_by_fear: Record<string, number>;
  responses_by_time_consuming_part: Record<string, number>;
  recent_responses: number;
  responses_last_7_days: number;
  responses_last_30_days: number;
  first_response?: string;
  latest_response?: string;
}

const FeedbackManagement: React.FC = () => {
  const [feedback, setFeedback] = useState<FeedbackResponse[]>([]);
  const [stats, setStats] = useState<FeedbackStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [exporting, setExporting] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [filters, setFilters] = useState<{
    search: string;
    biggestHurdle: string;
    primaryMotivation: string;
    dateRange: { start: string; end: string } | null;
  }>({
    search: '',
    biggestHurdle: '',
    primaryMotivation: '',
    dateRange: null
  });

  const pageSize = 20;

  useEffect(() => {
    loadFeedbackData();
    loadStats();
  }, [currentPage, filters]);

  const loadFeedbackData = async () => {
    try {
      setLoading(true);
      setError(null);

      const filterParams = {
        search: filters.search || undefined,
        biggest_hurdle: filters.biggestHurdle || undefined,
        primary_motivation: filters.primaryMotivation || undefined,
        dateRange: filters.dateRange || undefined
      };

      const response = await feedbackService.getFeedbackList(currentPage, pageSize, filterParams);
      setFeedback(response.feedback);
      setTotalPages(response.pagination.totalPages);
    } catch (err: any) {
      setError(err.message || 'Failed to load feedback data');
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      const statsData = await feedbackService.getFeedbackStats();
      setStats(statsData);
    } catch (err: any) {
      console.error('Failed to load feedback stats:', err);
    }
  };

  const handleExport = async () => {
    try {
      setExporting(true);

      const exportFilters: FeedbackExportFilters = {
        search: filters.search || undefined,
        biggest_hurdle: filters.biggestHurdle || undefined,
        primary_motivation: filters.primaryMotivation || undefined,
        dateRange: filters.dateRange || undefined
      };

      await feedbackService.downloadFeedbackExport('json', exportFilters);
    } catch (err: any) {
      setError(err.message || 'Failed to export feedback data');
    } finally {
      setExporting(false);
    }
  };

  const handleFilterChange = (key: string, value: any) => {
    setFilters(prev => ({ ...prev, [key]: value }));
    setCurrentPage(1); // Reset to first page when filters change
  };

  const clearFilters = () => {
    setFilters({
      search: '',
      biggestHurdle: '',
      primaryMotivation: '',
      dateRange: null
    });
    setCurrentPage(1);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getHurdleLabel = (value: string) => {
    const labels: Record<string, string> = {
      'A': 'Time commitment',
      'B': 'Simplifying topics',
      'C': 'Audience reach',
      'D': 'Ethics/compliance',
      'E': 'Other'
    };
    return labels[value] || value;
  };

  const getMotivationLabel = (value: string) => {
    const labels: Record<string, string> = {
      'A': 'Brand building',
      'B': 'Client attraction',
      'C': 'Revenue stream',
      'D': 'Education/contribution'
    };
    return labels[value] || value;
  };

  if (loading && !feedback.length) {
    return <LoadingSpinner size="large" message="Loading feedback data..." />;
  }

  return (
    <div className="feedback-management">
      <div className="feedback-header">
        <h2>Feedback Management</h2>
        <div className="feedback-actions">
          <button
            onClick={handleExport}
            disabled={exporting}
            className="export-btn json-btn"
          >
            {exporting ? 'Exporting...' : 'Export JSON'}
          </button>
        </div>
      </div>

      {error && (
        <ErrorMessage
          message={error}
          title="Error"
          onRetry={loadFeedbackData}
        />
      )}

      {/* Statistics Overview */}
      {stats && (
        <div className="feedback-stats">
          <h3>Feedback Statistics</h3>
          <div className="stats-grid">
            <div className="stat-card">
              <h4>Total Responses</h4>
              <p className="stat-number">{stats?.total_responses || 0}</p>
            </div>
            <div className="stat-card">
              <h4>Last 7 Days</h4>
              <p className="stat-number">{stats?.responses_last_7_days || 0}</p>
            </div>
            <div className="stat-card">
              <h4>Last 30 Days</h4>
              <p className="stat-number">{stats?.responses_last_30_days || 0}</p>
            </div>
          </div>

          <div className="breakdown-section">
            <div className="breakdown-item">
              <h4>Biggest Hurdles</h4>
              <div className="breakdown-list">
                {stats?.responses_by_hurdle ? Object.entries(stats.responses_by_hurdle).map(([key, count]) => (
                  <div key={key} className="breakdown-row">
                    <span>{getHurdleLabel(key)}</span>
                    <span>{count}</span>
                  </div>
                )) : <div>No data available</div>}
              </div>
            </div>

            <div className="breakdown-item">
              <h4>Primary Motivations</h4>
              <div className="breakdown-list">
                {stats?.responses_by_motivation ? Object.entries(stats.responses_by_motivation).map(([key, count]) => (
                  <div key={key} className="breakdown-row">
                    <span>{getMotivationLabel(key)}</span>
                    <span>{count}</span>
                  </div>
                )) : <div>No data available</div>}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="feedback-filters">
        <h3>Filters</h3>
        <div className="filters-grid">
          <div className="filter-group">
            <label>Search</label>
            <input
              type="text"
              value={filters.search}
              onChange={(e) => handleFilterChange('search', e.target.value)}
              placeholder="Search in responses..."
              className="filter-input"
            />
          </div>

          <div className="filter-group">
            <label>Biggest Hurdle</label>
            <select
              value={filters.biggestHurdle}
              onChange={(e) => handleFilterChange('biggestHurdle', e.target.value)}
              className="filter-select"
            >
              <option value="">All</option>
              <option value="A">Time commitment</option>
              <option value="B">Simplifying topics</option>
              <option value="C">Audience reach</option>
              <option value="D">Ethics/compliance</option>
              <option value="E">Other</option>
            </select>
          </div>

          <div className="filter-group">
            <label>Primary Motivation</label>
            <select
              value={filters.primaryMotivation}
              onChange={(e) => handleFilterChange('primaryMotivation', e.target.value)}
              className="filter-select"
            >
              <option value="">All</option>
              <option value="A">Brand building</option>
              <option value="B">Client attraction</option>
              <option value="C">Revenue stream</option>
              <option value="D">Education/contribution</option>
            </select>
          </div>

          <div className="filter-group">
            <button onClick={clearFilters} className="clear-filters-btn">
              Clear Filters
            </button>
          </div>
        </div>
      </div>

      {/* Feedback List */}
      <div className="feedback-list">
        <h3>Feedback Responses ({feedback.length} of {stats?.total_responses || 0})</h3>
        
        {loading ? (
          <LoadingSpinner message="Loading feedback..." />
        ) : feedback.length === 0 ? (
          <div className="no-feedback">
            <p>No feedback responses found.</p>
          </div>
        ) : (
          <div className="feedback-table">
            {feedback.map((item) => (
              <div key={item.id} className="feedback-item">
                <div className="feedback-item-header">
                  <div className="feedback-meta">
                    <span className="feedback-id">#{item.id}</span>
                    <span className="feedback-date">{formatDate(item.submitted_at)}</span>
                    {item.user_name && (
                      <span className="feedback-user">{item.user_name}</span>
                    )}
                  </div>
                </div>
                
                <div className="feedback-content">
                  <div className="feedback-choices">
                    <div className="choice-item">
                      <strong>Biggest Hurdle:</strong> {getHurdleLabel(item.biggest_hurdle)}
                      {item.biggest_hurdle_other && ` (${item.biggest_hurdle_other})`}
                    </div>
                    <div className="choice-item">
                      <strong>Primary Motivation:</strong> {getMotivationLabel(item.primary_motivation || '')}
                    </div>
                  </div>
                  
                  <div className="feedback-answers">
                    <div className="answer-item">
                      <strong>Monetization Considerations:</strong>
                      <p>{item.monetization_considerations}</p>
                    </div>
                    <div className="answer-item">
                      <strong>Professional Legacy:</strong>
                      <p>{item.professional_legacy}</p>
                    </div>
                    <div className="answer-item">
                      <strong>Platform Impact:</strong>
                      <p>{item.platform_impact}</p>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="pagination">
            <button
              onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
              disabled={currentPage === 1}
              className="pagination-btn"
            >
              Previous
            </button>
            
            <span className="pagination-info">
              Page {currentPage} of {totalPages}
            </span>
            
            <button
              onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))}
              disabled={currentPage === totalPages}
              className="pagination-btn"
            >
              Next
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default FeedbackManagement;
