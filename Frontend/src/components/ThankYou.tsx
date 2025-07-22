import React, { useEffect, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import gsap from 'gsap';
import LoadingSpinner from './LoadingSpinner';
import { useLeaderboard, useUserLeaderboardStats, useAroundMe } from '../hooks/useLeaderboard';
import { sharesService } from '../services/sharesService';
import { authService } from '../services/authService';
import './ThankYou.css';

interface ThankYouState {
  userName: string;
}

export default function ThankYou() {
  const location = useLocation();
  const navigate = useNavigate();
  const state = location.state as ThankYouState;
  const { leaderboard, refresh: refreshLeaderboard } = useLeaderboard({ page: 1, limit: 10 });
  const { userStats, refresh: refreshUserStats } = useUserLeaderboardStats();
  const { surroundingUsers, userStats: aroundMeUserStats, refresh: refreshAroundMe } = useAroundMe();

  // State for managing right-side view
  const [rightSideView, setRightSideView] = useState<'around-me' | 'leaderboard'>('around-me');

  // State for tracking the most recent user rank and points (from share responses)
  const [currentUserRank, setCurrentUserRank] = useState<number | null>(null);
  const [currentUserPoints, setCurrentUserPoints] = useState<number | null>(null);

  const [shareStates, setShareStates] = useState({
    facebook: { loading: false, shared: false, error: null },
    twitter: { loading: false, shared: false, error: null },
    linkedin: { loading: false, shared: false, error: null },
    instagram: { loading: false, shared: false, error: null }
  });

  // Check if this is a demo route or if we have state
  const isDemoRoute = location.pathname === '/demo-thank-you';
  const userName = state?.userName || (isDemoRoute ? 'Demo User' : null);

  // If no user name is provided and not demo route, redirect to home
  useEffect(() => {
    if (!userName && !isDemoRoute) {
      navigate('/');
      return;
    }
  }, [userName, isDemoRoute, navigate]);

  // Initialize user stats on mount if authenticated
  useEffect(() => {
    if (authService.isAuthenticated()) {
      refreshUserStats();
      refreshAroundMe();
    }
  }, [refreshUserStats, refreshAroundMe]);

  // Update local state when userStats change (only if we don't have current data)
  useEffect(() => {
    if (userStats?.rank && !currentUserRank) {
      console.log(`📊 Initializing user rank from userStats: ${userStats.rank}`);
      setCurrentUserRank(userStats.rank);
    }
    if (userStats?.points && !currentUserPoints) {
      console.log(`💰 Initializing user points from userStats: ${userStats.points}`);
      setCurrentUserPoints(userStats.points);
    }
  }, [userStats, currentUserRank, currentUserPoints]);

  // Update local state when aroundMeUserStats change (only if we don't have current data)
  useEffect(() => {
    if (aroundMeUserStats?.rank && !currentUserRank) {
      console.log(`📊 Initializing user rank from aroundMeUserStats: ${aroundMeUserStats.rank}`);
      setCurrentUserRank(aroundMeUserStats.rank);
    }
    if (aroundMeUserStats?.points && !currentUserPoints) {
      console.log(`💰 Initializing user points from aroundMeUserStats: ${aroundMeUserStats.points}`);
      setCurrentUserPoints(aroundMeUserStats.points);
    }
  }, [aroundMeUserStats, currentUserRank, currentUserPoints]);

  // GSAP Timeline animations
  useEffect(() => {
    if (userName) {
      console.log('🎬 Starting GSAP animations for ThankYou page');

      // Create main timeline for coordinated animations
      const tl = gsap.timeline();

      // 1. Card and Leaderboard Animation (simultaneous) - fade-in from right
      tl.fromTo('.thankyou__social-media-post',
        { opacity: 0, x: 100 },
        { opacity: 1, x: 0, duration: 0.5, ease: 'power2.out' }
      )
      .fromTo('.thankyou-hero__leaderboard',
        { opacity: 0, x: 100 },
        { opacity: 1, x: 0, duration: 0.5, ease: 'power2.out' },
        "<" // Start at the same time as previous animation
      )

      // 2. Thank You Message Animation - fade-in
      .fromTo('.thankyou__title-glass, .thankyou__desc-glass, .thankyou__celebrate-message',
        { opacity: 0 },
        { opacity: 1, duration: 0.5, ease: 'power2.out', stagger: 0.1 }
      )

      // 3. Social Media Icons Animation - stagger fade-in
      .fromTo('.thankyou__social-icon-vertical',
        { opacity: 0 },
        { opacity: 1, duration: 0.5, ease: 'power2.out', stagger: 0.1 }
      )

      // 4. Leaderboard content items - FORCE VISIBLE
      .set('.leaderboard__item, .around-me__user-card, .around-me__surrounding-item', {
        opacity: 1,
        y: 0,
        visibility: 'visible',
        
      })
      .fromTo('.leaderboard__item, .around-me__user-card, .around-me__surrounding-item',
        { opacity: 0, y: 20 },
        { opacity: 1, y: 0, duration: 0.5, ease: 'power2.out', stagger: 0.1 }
      )

      // 5. Back to home button
      .fromTo('.thankyou__custom-back-btn',
        { opacity: 0, y: 20 },
        { opacity: 1, y: 0, duration: 0.5, ease: 'power2.out' }
      );

      console.log('🎬 GSAP animations completed');
    }
  }, [userName]);

  // Additional effect to ensure content is visible when data loads
  useEffect(() => {
    console.log('🔄 Data state changed:');
    console.log('  - leaderboard length:', leaderboard.length);
    console.log('  - surroundingUsers length:', surroundingUsers.length);
    console.log('  - userStats:', userStats);
    console.log('  - aroundMeUserStats:', aroundMeUserStats);

    // Force visibility of content when data is available
    if (leaderboard.length > 0 || surroundingUsers.length > 0 || userStats || aroundMeUserStats) {
      console.log('📊 Data available, forcing content visibility');

      // Use GSAP to ensure content is visible
      gsap.set('.leaderboard__item, .around-me__user-card, .around-me__surrounding-item', {
        opacity: 1,
        visibility: 'visible',
       
      });

      // Also ensure the leaderboard container is visible
      gsap.set('.leaderboard, .leaderboard__content, .around-me__stats', {
        opacity: 1,
        visibility: 'visible'
      });
    }
  }, [leaderboard, surroundingUsers, userStats, aroundMeUserStats]);

  const handleBackToHome = () => {
    navigate('/');
  };

  // Handle view switching with animations
  const handleViewLeaderboard = () => {
    gsap.to('.leaderboard__content', {
      opacity: 0,
      duration: 0.2,
      onComplete: () => {
        setRightSideView('leaderboard');
        gsap.to('.leaderboard__content', { opacity: 1, duration: 0.3 });
      }
    });
  };

  const handleViewAroundMe = () => {
    gsap.to('.leaderboard__content', {
      opacity: 0,
      duration: 0.2,
      onComplete: () => {
        setRightSideView('around-me');
        gsap.to('.leaderboard__content', { opacity: 1, duration: 0.3 });
      }
    });
  };



  // Handle social media sharing
  const handleShare = async (platform: 'facebook' | 'twitter' | 'linkedin' | 'instagram') => {
    console.log(`🔄 Share button clicked for platform: ${platform}`);

    // Update loading state
    setShareStates(prev => ({
      ...prev,
      [platform]: { ...prev[platform], loading: true, error: null }
    }));

    try {
      // Check authentication first
      const isAuth = authService.isAuthenticated();
      console.log(`🔐 User authenticated: ${isAuth}`);

      if (isAuth) {
        const token = localStorage.getItem('authToken');
        console.log(`🎫 Token exists: ${!!token}`);
        if (token) {
          console.log(`🎫 Token preview: ${token.substring(0, 20)}...`);
        }
      }

      // Create personalized share content
      const shareText = `� Congratulations to ${userName} for becoming a beta testing founding member at LawVriksh!

✨ Welcome aboard! We're thrilled to have you join our growing community of legal professionals and enthusiasts.

By registering with LawVriksh, you've taken the first step towards unlocking a wealth of legal knowledge, connecting with peers, and staying ahead in the ever-evolving legal landscape.

Join us at LawVriksh - the ultimate platform for legal professionals! 🏛️⚖️`;

      // Open share dialog with personalized content
      console.log(`🌐 Opening share dialog for ${platform}`);
      sharesService.openShareDialog(platform, shareText);

      // Record share with API
      if (isAuth) {
        console.log(`📡 Making API call to record share for platform: ${platform}`);
        const result = await sharesService.recordShare(platform);
        console.log(`✅ Share API response:`, result);

        // Update state with success
        setShareStates(prev => ({
          ...prev,
          [platform]: { loading: false, shared: true, error: null, points: result.points_earned }
        }));

        // Update current user rank and points immediately from share response
        if (result.new_rank !== undefined) {
          console.log(`📊 Updating user rank from ${currentUserRank} to ${result.new_rank}`);
          setCurrentUserRank(result.new_rank);
        }
        if (result.total_points !== undefined) {
          console.log(`💰 Updating user points to ${result.total_points}`);
          setCurrentUserPoints(result.total_points);
        }

        // Always refresh all data after any share attempt (even if 0 points)
        console.log('🔄 Refreshing leaderboard and user stats after share...');
        await Promise.all([
          refreshLeaderboard(),
          refreshUserStats(),
          refreshAroundMe()
        ]);
        console.log('✅ All data refreshed');

        // After refresh, update local state with the most recent data if it's more current
        // This ensures we have the latest rank even if the hooks return updated data
        setTimeout(() => {
          if (userStats?.rank && userStats.rank !== currentUserRank) {
            console.log(`📊 Updating rank from refreshed userStats: ${userStats.rank}`);
            setCurrentUserRank(userStats.rank);
          }
          if (userStats?.points && userStats.points !== currentUserPoints) {
            console.log(`💰 Updating points from refreshed userStats: ${userStats.points}`);
            setCurrentUserPoints(userStats.points);
          }
        }, 100); // Small delay to ensure hooks have updated

        // Show success message
        if (result.points_earned > 0) {
          console.log(`🎉 Earned ${result.points_earned} points for ${platform} share!`);
          alert(`Success! You earned ${result.points_earned} points for sharing on ${platform}!`);
        } else {
          console.log(`ℹ️ Already shared on ${platform}, no additional points earned.`);
          alert(`You&#39;ve already shared on ${platform}. No additional points earned.`);
        }
      } else {
        console.log('❌ User not authenticated, cannot record share');
        alert('Please log in to earn points for sharing!');
        // Just mark as shared without API call if not authenticated
        setShareStates(prev => ({
          ...prev,
          [platform]: { loading: false, shared: true, error: null }
        }));
      }
    } catch (error) {
      console.error(`❌ Error sharing on ${platform}:`, error);
      alert(`Error sharing on ${platform}: ${(error as Error).message}`);
      // Update state with error
      setShareStates(prev => ({
        ...prev,
        [platform]: { loading: false, shared: false, error: (error as Error).message || 'Failed to share' }
      }));
    }
  };

  const socialMediaLinks = [
    {
      name: 'Facebook',
      url: 'https://facebook.com/lawvriksh',
      color: '#1877F2',
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
          <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
        </svg>
      )
    },
    {
      name: 'Instagram',
      url: 'https://instagram.com/lawvriksh',
      color: '#E4405F',
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
        </svg>
      )
    },
    {
      name: 'LinkedIn',
      url: 'https://linkedin.com/company/lawvriksh',
      color: '#0A66C2',
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
          <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
        </svg>
      )
    },
    {
      name: 'X (Twitter)',
      url: 'https://twitter.com/lawvriksh',
      color: '#000000',
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
          <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
        </svg>
      )
    }
  ];

  if (!userName) {
    return null; // Will redirect to home
  }

  const leaderboardData = leaderboard.slice(0, 10); // Use top 10 from hook

  // Demo data for surrounding users when in demo mode
  const demoSurroundingUsers = isDemoRoute ? [
    { rank: 40, name: 'Sarah Johnson', points: 1320, is_current_user: false },
    { rank: 41, name: 'Michael Chen', points: 1280, is_current_user: false },
    { rank: 42, name: 'Demo User', points: 1250, is_current_user: true },
    { rank: 43, name: 'Emily Davis', points: 1220, is_current_user: false },
    { rank: 44, name: 'David Wilson', points: 1180, is_current_user: false }
  ] : [];

  const displaySurroundingUsers = surroundingUsers.length > 0 ? surroundingUsers : demoSurroundingUsers;

  // DEBUG: Log current data state
  console.log('🔍 ThankYou Component Render State:');
  console.log('  - userName:', userName);
  console.log('  - isDemoRoute:', isDemoRoute);
  console.log('  - rightSideView:', rightSideView);
  console.log('  - leaderboard data:', leaderboard.length, 'items');
  console.log('  - surroundingUsers:', surroundingUsers.length, 'items');
  console.log('  - displaySurroundingUsers:', displaySurroundingUsers.length, 'items');
  console.log('  - currentUserRank:', currentUserRank);
  console.log('  - currentUserPoints:', currentUserPoints);
  console.log('  - userStats:', userStats);
  console.log('  - aroundMeUserStats:', aroundMeUserStats);

  return (
    <div className="thankyou-hero">
      {/* Back to Home Button - Top Left */}
      <div className="thankyou__back-button-top-left">
        <button className="thankyou__custom-back-btn" onClick={handleBackToHome}>
          ← Back to Home
        </button>
      </div>

      <div className="thankyou-hero__left">
        <div className="thankyou-hero__card">
          {/* Social Media Post Style Card */}
          <div className="thankyou__social-media-post">
            {/* Post Header */}
            <div className="thankyou__post-header">
              <div className="thankyou__post-avatar">
                <div className="thankyou__brand-logo">
                  <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 2L13.09 8.26L20 9L13.09 9.74L12 16L10.91 9.74L4 9L10.91 8.26L12 2Z"/>
                  </svg>
                </div>
              </div>
              <div className="thankyou__post-info">
                <h3 className="thankyou__brand-name">LawVriksh</h3>
                <p className="thankyou__post-meta">Legal Community Platform • Just now</p>
              </div>
              <div className="thankyou__verified-badge">✓</div>
            </div>

            {/* Card Body - Two Column Layout */}
            <div className="thankyou__card-body">
              {/* Main Content Area (Left Side) */}
              <div className="thankyou__main-content">
                {/* Post Content - Original Message */}
            <div className="thankyou__post-content">
              <h1 className="thankyou__title-glass">
                Thank you {userName}!!
              </h1>
              <p className="thankyou__desc-glass">
                You have successfully enrolled in our program
              </p>
              <div className="thankyou__divider-glass"></div>
              <div className="thankyou__celebrate-message">
                <h2 className="thankyou__card-heading">
                  ✨Congratulations for becoming our beta testing founding member!
                  <br />
                  Welcome aboard!
                </h2>
                <p className="thankyou__card-description">
                  We're thrilled to have you join our growing community of legal professionals and enthusiasts. By registering with LawVriksh, you've taken the first step towards unlocking a wealth of legal knowledge, connecting with peers, and staying ahead in the ever-evolving legal landscape.
                </p>
              </div>
            </div>

            {/* Post Footer with engagement indicators */}
            <div className="thankyou__post-footer">
              <div className="thankyou__engagement-bar">
                <div className="thankyou__engagement-stats">
                  <span className="thankyou__engagement-item">
                    <span className="thankyou__engagement-icon">👏</span>
                    <span className="thankyou__engagement-count">247</span>
                  </span>
                  <span className="thankyou__engagement-item">
                    <span className="thankyou__engagement-icon">�</span>
                    <span className="thankyou__engagement-count">18</span>
                  </span>
                  <span className="thankyou__engagement-item">
                    <span className="thankyou__engagement-icon">�</span>
                    <span className="thankyou__engagement-count">42</span>
                  </span>
                </div>
                    <div className="thankyou__post-time-section">
                      <div className="thankyou__post-time">2 min ago</div>
                      <p className="thankyou__share-message-footer">
                        Share to improve your rank
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Social Media Sidebar (Right Side) */}
              <div className="thankyou__social-sidebar">
                {socialMediaLinks.map((social) => {
                  let platform: 'facebook' | 'twitter' | 'linkedin' | 'instagram';
                  if (social.name === 'X (Twitter)') {
                    platform = 'twitter';
                  } else {
                    platform = social.name.toLowerCase() as 'facebook' | 'twitter' | 'linkedin' | 'instagram';
                  }
                  const shareState = shareStates[platform] || { loading: false, shared: false, error: null };
                  return (
                    <button
                      key={social.name}
                      onClick={() => handleShare(platform)}
                      disabled={shareState.loading}
                      className={`thankyou__social-icon-vertical ${shareState.shared ? 'shared' : ''} ${shareState.loading ? 'loading' : ''}`}
                      style={{ '--social-color': social.color } as React.CSSProperties}
                      title={shareState.shared ? `Shared on ${social.name}!` : `Share on ${social.name}`}
                    >
                      {shareState.loading ? (
                        <LoadingSpinner size="small" transparent />
                      ) : (
                        <>
                          <span className="thankyou__social-svg">{social.icon}</span>
                          <span className="thankyou__social-name">{social.name}</span>
                          {shareState.shared && (
                            <span className="share-checkmark">✓</span>
                          )}
                        </>
                      )}
                    </button>
                  );
                })}
              </div>
            </div>
          </div>

        </div>
      </div>
      <div className="thankyou-hero__right">
        <div className="thankyou-hero__leaderboard">
          {rightSideView === 'around-me' ? (
            // Around Me Section (Default)
            <div className="leaderboard">
              <div className="leaderboard__header">
                <h2 className="leaderboard__title">My Stats</h2>
                <p className="leaderboard__subtitle">Your Performance</p>
                {/* DEBUG INFO */}
                <div style={{fontSize: '10px', color: '#666', marginTop: '5px'}}>
                  DEBUG: Users: {surroundingUsers.length} | Stats: {userStats ? 'Yes' : 'No'} | AroundMe: {aroundMeUserStats ? 'Yes' : 'No'}
                </div>
              </div>
              <div className="leaderboard__content">
                <div className="around-me__stats">
                  <div className="around-me__user-card">
                    <div className="around-me__user-info">
                      <h3 className="around-me__user-name">{userName}</h3>
                      <div className="around-me__user-stats">
                        <div className="around-me__stat">
                          <span className="around-me__stat-value">
                            {currentUserRank || userStats?.rank || aroundMeUserStats?.rank || (isDemoRoute ? '42' : 'N/A')}
                          </span>
                          <span className="around-me__stat-label">Current Rank</span>
                        </div>
                        <div className="around-me__stat">
                          <span className="around-me__stat-value">
                            {(currentUserPoints || userStats?.points || aroundMeUserStats?.points || (isDemoRoute ? 1250 : 0)).toLocaleString()}
                          </span>
                          <span className="around-me__stat-label">Total Points</span>
                        </div>
                        <div className="around-me__stat">
                          <span className="around-me__stat-value">
                            {Object.values(shareStates).filter(state => state.shared).length || (isDemoRoute ? 3 : 0)}
                          </span>
                          <span className="around-me__stat-label">Shares Completed</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  {displaySurroundingUsers.length > 0 && (
                    <div className="around-me__surrounding">
                      <h4 className="around-me__surrounding-title">Users Around You</h4>
                      <div className="around-me__surrounding-list">
                        {displaySurroundingUsers.slice(0, 5).map((user, index) => (
                          <div key={index} className={`around-me__surrounding-item ${user.is_current_user ? 'current-user' : ''}`}>
                            <div className="around-me__surrounding-rank">#{user.rank}</div>
                            <div className="around-me__surrounding-name">{user.name}</div>
                            <div className="around-me__surrounding-points">{user.points.toLocaleString()}</div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              </div>
              <div className="leaderboard__footer">
                <button
                  className="around-me__view-full-btn"
                  onClick={handleViewLeaderboard}
                >
                  View Full Leaderboard
                </button>
              </div>
            </div>
          ) : (
            // Full Leaderboard Section
            <div className="leaderboard">
              <div className="leaderboard__header">
                <h2 className="leaderboard__title">Leaderboard</h2>
                <p className="leaderboard__subtitle">Top Legal Professionals</p>
                {/* DEBUG INFO */}
                <div style={{fontSize: '10px', color: '#666', marginTop: '5px'}}>
                  DEBUG: Leaderboard: {leaderboard.length} items
                </div>
              </div>
              <div className="leaderboard__content">
                <div className="leaderboard__list">
                  {leaderboardData.map((entry) => (
                    <div key={entry.rank} className="leaderboard__item">
                      <div className="leaderboard__rank">
                        {entry.rank <= 3 ? (
                          <div className={`leaderboard__medal leaderboard__medal--${entry.rank === 1 ? 'gold' : entry.rank === 2 ? 'silver' : 'bronze'}`}>
                            <span className="leaderboard__medal-icon">
                              {entry.rank === 1 ? '👑' : entry.rank === 2 ? '🥈' : '🥉'}
                            </span>
                            <span className="leaderboard__rank-number">{entry.rank}</span>
                          </div>
                        ) : (
                          <div className="leaderboard__rank-badge">
                            <span className="leaderboard__rank-number">{entry.rank}</span>
                          </div>
                        )}
                      </div>
                      <div className="leaderboard__info">
                        <h3 className="leaderboard__name">{entry.name}</h3>
                        <div className="leaderboard__stats">
                          <div className="leaderboard__stat">
                            <span className="leaderboard__stat-value">{entry.points.toLocaleString()}</span>
                            <span className="leaderboard__stat-label">Points</span>
                          </div>
                          <div className="leaderboard__stat">
                            <span className="leaderboard__stat-value">{entry.shares_count}</span>
                            <span className="leaderboard__stat-label">Shares</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              <div className="leaderboard__footer">
                <button
                  className="around-me__back-btn"
                  onClick={handleViewAroundMe}
                >
                  ← Back to My Stats
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
