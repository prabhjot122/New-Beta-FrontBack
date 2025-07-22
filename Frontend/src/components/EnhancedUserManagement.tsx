import React, { useState, useEffect, useCallback } from 'react';
import { adminService } from '../services/adminService';
import { AdminUser } from '../types/api';
import LoadingSpinner from './LoadingSpinner';
import ErrorMessage from './ErrorMessage';
import './EnhancedUserManagement.css';

interface FilterState {
  search: string;
  status: 'all' | 'active' | 'inactive';
  minPoints: number;
  sortBy: 'name' | 'email' | 'points' | 'date';
  sortOrder: 'asc' | 'desc';
  dateRange: {
    start: string;
    end: string;
  };
}

const EnhancedUserManagement: React.FC = () => {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 20,
    total: 0,
    pages: 0
  });

  const [filters, setFilters] = useState<FilterState>({
    search: '',
    status: 'all',
    minPoints: 0,
    sortBy: 'points',
    sortOrder: 'desc',
    dateRange: {
      start: '',
      end: ''
    }
  });

  const [selectedUsers, setSelectedUsers] = useState<Set<number>>(new Set());
  const [showExportModal, setShowExportModal] = useState(false);
  const [exporting, setExporting] = useState(false);
  const [selectedUser, setSelectedUser] = useState<AdminUser | null>(null);

  const loadUsers = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      const params = {
        page: pagination.page,
        limit: pagination.limit,
        search: filters.search,
        sort: filters.sortBy
      };

      const response = await adminService.getUsers(params);
      
      // Apply client-side filtering for mock mode
      let filteredUsers = response.users;
      
      if (filters.status !== 'all') {
        filteredUsers = filteredUsers.filter(user => user.status === filters.status);
      }
      
      if (filters.minPoints > 0) {
        filteredUsers = filteredUsers.filter(user => user.points >= filters.minPoints);
      }

      if (filters.dateRange.start && filters.dateRange.end) {
        const startDate = new Date(filters.dateRange.start);
        const endDate = new Date(filters.dateRange.end);
        filteredUsers = filteredUsers.filter(user => {
          const userDate = new Date(user.created_at);
          return userDate >= startDate && userDate <= endDate;
        });
      }

      // Apply sorting
      filteredUsers.sort((a, b) => {
        let aValue: any, bValue: any;
        
        switch (filters.sortBy) {
          case 'name':
            aValue = a.name.toLowerCase();
            bValue = b.name.toLowerCase();
            break;
          case 'email':
            aValue = a.email.toLowerCase();
            bValue = b.email.toLowerCase();
            break;
          case 'points':
            aValue = a.points;
            bValue = b.points;
            break;
          case 'date':
            aValue = new Date(a.created_at);
            bValue = new Date(b.created_at);
            break;
          default:
            aValue = a.points;
            bValue = b.points;
        }

        if (filters.sortOrder === 'asc') {
          return aValue > bValue ? 1 : -1;
        } else {
          return aValue < bValue ? 1 : -1;
        }
      });

      setUsers(filteredUsers);
      setPagination(prev => ({
        ...prev,
        total: response.pagination.total,
        pages: response.pagination.pages
      }));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load users');
    } finally {
      setLoading(false);
    }
  }, [pagination.page, pagination.limit, filters]);

  useEffect(() => {
    loadUsers();
  }, [loadUsers]);

  const handleFilterChange = (key: keyof FilterState, value: any) => {
    setFilters(prev => ({
      ...prev,
      [key]: value
    }));
    setPagination(prev => ({ ...prev, page: 1 })); // Reset to first page
  };

  const handleUserSelect = (userId: number) => {
    setSelectedUsers(prev => {
      const newSet = new Set(prev);
      if (newSet.has(userId)) {
        newSet.delete(userId);
      } else {
        newSet.add(userId);
      }
      return newSet;
    });
  };

  const handleSelectAll = () => {
    if (selectedUsers.size === users.length) {
      setSelectedUsers(new Set());
    } else {
      setSelectedUsers(new Set(users.map(user => user.user_id)));
    }
  };

  const handleExport = async (format: 'csv' | 'json') => {
    try {
      setExporting(true);
      
      const exportFilters = {
        search: filters.search || undefined,
        minPoints: filters.minPoints > 0 ? filters.minPoints : undefined,
        status: filters.status !== 'all' ? filters.status : undefined,
        dateRange: filters.dateRange.start && filters.dateRange.end ? filters.dateRange : undefined
      };

      const blob = await adminService.exportUsers(format, exportFilters);
      
      // Create download link
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `users_export_${new Date().toISOString().split('T')[0]}.${format}`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
      
      setShowExportModal(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Export failed');
    } finally {
      setExporting(false);
    }
  };

  const handleStatusToggle = async (userId: number, currentStatus: string) => {
    try {
      const newStatus = currentStatus === 'active' ? 'inactive' : 'active';
      await adminService.updateUserStatus(userId, newStatus as 'active' | 'inactive');
      
      // Update local state
      setUsers(prev => prev.map(user => 
        user.user_id === userId 
          ? { ...user, status: newStatus }
          : user
      ));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update user status');
    }
  };

  const handlePromoteUser = async (userId: number) => {
    try {
      await adminService.promoteUser(userId);
      
      // Update local state
      setUsers(prev => prev.map(user => 
        user.user_id === userId 
          ? { ...user, is_admin: true }
          : user
      ));
      
      alert('User promoted to admin successfully!');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to promote user');
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  if (loading && users.length === 0) {
    return (
      <div className="user-management-loading">
        <LoadingSpinner />
      </div>
    );
  }

  return (
    <div className="user-management-container">
      {/* Header */}
      <div className="user-management-header">
        <div className="user-management-header-content">
          <h3 className="user-management-title">Enhanced User Management</h3>
          <div className="user-management-actions">
            <button
              onClick={() => setShowExportModal(true)}
              className="user-management-button primary"
            >
              Export Users
            </button>
            <button
              onClick={loadUsers}
              className="user-management-button secondary"
            >
              Refresh
            </button>
          </div>
        </div>

        {/* Filters */}
        <div className="user-management-filters">
          <div className="user-management-filter-group">
            <label className="user-management-filter-label">Search</label>
            <input
              type="text"
              value={filters.search}
              onChange={(e) => handleFilterChange('search', e.target.value)}
              placeholder="Name or email..."
              className="user-management-input"
            />
          </div>

          <div className="user-management-filter-group">
            <label className="user-management-filter-label">Status</label>
            <select
              value={filters.status}
              onChange={(e) => handleFilterChange('status', e.target.value)}
              className="user-management-select"
            >
              <option value="all">All Users</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>

          <div className="user-management-filter-group">
            <label className="user-management-filter-label">Min Points</label>
            <input
              type="number"
              value={filters.minPoints}
              onChange={(e) => handleFilterChange('minPoints', parseInt(e.target.value) || 0)}
              min="0"
              className="user-management-input"
            />
          </div>

          <div className="user-management-filter-group">
            <label className="user-management-filter-label">Sort By</label>
            <select
              value={filters.sortBy}
              onChange={(e) => handleFilterChange('sortBy', e.target.value)}
              className="user-management-select"
            >
              <option value="points">Points</option>
              <option value="name">Name</option>
              <option value="email">Email</option>
              <option value="date">Registration Date</option>
            </select>
          </div>
        </div>

        <div className="user-management-filters-extended">
          <div className="user-management-filter-group">
            <label className="user-management-filter-label">Start Date</label>
            <input
              type="date"
              value={filters.dateRange.start}
              onChange={(e) => handleFilterChange('dateRange', { ...filters.dateRange, start: e.target.value })}
              className="user-management-input"
            />
          </div>

          <div className="user-management-filter-group">
            <label className="user-management-filter-label">End Date</label>
            <input
              type="date"
              value={filters.dateRange.end}
              onChange={(e) => handleFilterChange('dateRange', { ...filters.dateRange, end: e.target.value })}
              className="user-management-input"
            />
          </div>

          <div className="user-management-filter-actions">
            <button
              onClick={() => handleFilterChange('sortOrder', filters.sortOrder === 'asc' ? 'desc' : 'asc')}
              className="user-management-button secondary"
            >
              {filters.sortOrder === 'asc' ? '↑ Ascending' : '↓ Descending'}
            </button>
          </div>
        </div>
      </div>

      {error && (
        <div style={{ padding: '1rem' }}>
          <ErrorMessage message={error} />
        </div>
      )}

      {/* User List */}
      <div className="user-management-content">
        {selectedUsers.size > 0 && (
          <div className="user-management-selection-info">
            <p className="user-management-selection-text">
              {selectedUsers.size} user(s) selected
            </p>
          </div>
        )}

        <div className="user-management-table-wrapper">
          <table className="user-management-table">
            <thead>
              <tr>
                <th>
                  <input
                    type="checkbox"
                    checked={selectedUsers.size === users.length && users.length > 0}
                    onChange={handleSelectAll}
                    className="user-management-checkbox"
                  />
                </th>
                <th>User</th>
                <th>Points & Rank</th>
                <th>Status</th>
                <th>Registration</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr key={user.user_id}>
                  <td>
                    <input
                      type="checkbox"
                      checked={selectedUsers.has(user.user_id)}
                      onChange={() => handleUserSelect(user.user_id)}
                      className="user-management-checkbox"
                    />
                  </td>
                  <td>
                    <div className="user-cell">
                      <div className="user-avatar">
                        <div className="user-avatar-circle">
                          <span className="user-avatar-initial">
                            {user.name.charAt(0).toUpperCase()}
                          </span>
                        </div>
                      </div>
                      <div className="user-info">
                        <div className="user-name">{user.name}</div>
                        <div className="user-email">{user.email}</div>
                        {(user as any).is_admin && (
                          <span className="user-admin-badge">
                            Admin
                          </span>
                        )}
                      </div>
                    </div>
                  </td>
                  <td>
                    <div className="points-cell">
                      <div className="points-value">{user.points} points</div>
                      <div className="points-details">
                        Rank: {user.rank || 'N/A'} • {user.shares_count} shares
                      </div>
                    </div>
                  </td>
                  <td>
                    <span className={`status-badge ${user.status === 'active' ? 'active' : 'inactive'}`}>
                      {user.status}
                    </span>
                  </td>
                  <td className="date-cell">
                    {formatDate(user.created_at)}
                  </td>
                  <td className="actions-cell">
                    <button
                      onClick={() => setSelectedUser(user)}
                      className="action-link"
                    >
                      View
                    </button>
                    <button
                      onClick={() => handleStatusToggle(user.user_id, user.status)}
                      className="action-link warning"
                    >
                      {user.status === 'active' ? 'Deactivate' : 'Activate'}
                    </button>
                    {!(user as any).is_admin && (
                      <button
                        onClick={() => handlePromoteUser(user.user_id)}
                        className="action-link purple"
                      >
                        Promote
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="user-management-pagination">
          <div className="pagination-info">
            Showing {((pagination.page - 1) * pagination.limit) + 1} to {Math.min(pagination.page * pagination.limit, pagination.total)} of {pagination.total} users
          </div>
          <div className="pagination-controls">
            <button
              onClick={() => setPagination(prev => ({ ...prev, page: Math.max(1, prev.page - 1) }))}
              disabled={pagination.page === 1}
              className="pagination-button"
            >
              Previous
            </button>
            <span className="pagination-current">
              Page {pagination.page} of {pagination.pages}
            </span>
            <button
              onClick={() => setPagination(prev => ({ ...prev, page: Math.min(prev.pages, prev.page + 1) }))}
              disabled={pagination.page === pagination.pages}
              className="pagination-button"
            >
              Next
            </button>
          </div>
        </div>
      </div>

      {/* Export Modal */}
      {showExportModal && (
        <div className="modal-overlay">
          <div className="modal-container">
            <div className="modal-content">
              <h3 className="modal-title">Export Users</h3>
              <p className="modal-text">
                Export users with current filters applied. Choose your preferred format:
              </p>
              <div className="modal-actions">
                <button
                  onClick={() => handleExport('csv')}
                  disabled={exporting}
                  className="modal-button primary"
                >
                  {exporting ? 'Exporting...' : 'Export CSV'}
                </button>
                <button
                  onClick={() => handleExport('json')}
                  disabled={exporting}
                  className="modal-button secondary"
                >
                  {exporting ? 'Exporting...' : 'Export JSON'}
                </button>
              </div>
              <button
                onClick={() => setShowExportModal(false)}
                className="modal-close-button"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* User Detail Modal */}
      {selectedUser && (
        <div className="modal-overlay">
          <div className="modal-container">
            <div className="modal-content">
              <h3 className="modal-title">User Details</h3>
              <div className="user-detail-grid">
                <div className="user-detail-item">
                  <label className="user-detail-label">Name</label>
                  <p className="user-detail-value">{selectedUser.name}</p>
                </div>
                <div className="user-detail-item">
                  <label className="user-detail-label">Email</label>
                  <p className="user-detail-value">{selectedUser.email}</p>
                </div>
                <div className="user-detail-item">
                  <label className="user-detail-label">Points</label>
                  <p className="user-detail-value">{selectedUser.points}</p>
                </div>
                <div className="user-detail-item">
                  <label className="user-detail-label">Rank</label>
                  <p className="user-detail-value">{selectedUser.rank || 'N/A'}</p>
                </div>
                <div className="user-detail-item">
                  <label className="user-detail-label">Shares</label>
                  <p className="user-detail-value">{selectedUser.shares_count}</p>
                </div>
                <div className="user-detail-item">
                  <label className="user-detail-label">Status</label>
                  <p className="user-detail-value">{selectedUser.status}</p>
                </div>
                <div className="user-detail-item">
                  <label className="user-detail-label">Registration Date</label>
                  <p className="user-detail-value">{formatDate(selectedUser.created_at)}</p>
                </div>
                <div className="user-detail-item">
                  <label className="user-detail-label">Last Activity</label>
                  <p className="user-detail-value">
                    {selectedUser.last_activity ? formatDate(selectedUser.last_activity) : 'N/A'}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setSelectedUser(null)}
                className="modal-close-button"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default EnhancedUserManagement;
