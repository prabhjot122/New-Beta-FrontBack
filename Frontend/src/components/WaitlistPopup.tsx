import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import gsap from 'gsap';
import Button from './Button';
// import LoadingSpinner from './LoadingSpinner';
import ErrorMessage from './ErrorMessage';
import { authService } from '../services/authService';
import { useApiState } from '../hooks/useApiState';
import './WaitlistPopup.css';

interface WaitlistPopupProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function WaitlistPopup({ isOpen, onClose }: WaitlistPopupProps) {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    name: '',
    email: ''
  });
  const { state: signupState, execute: executeSignup } = useApiState();
  const [_isSubmitted, setIsSubmitted] = useState(false);

  useEffect(() => {
    if (isOpen) {
      // Animate popup in
      gsap.set('.waitlist-popup', { display: 'flex' });
      gsap.fromTo('.waitlist-popup__overlay', 
        { opacity: 0 },
        { opacity: 1, duration: 0.3, ease: 'power2.out' }
      );
      gsap.fromTo('.waitlist-popup__content',
        { scale: 0.8, opacity: 0, y: 50 },
        { scale: 1, opacity: 1, y: 0, duration: 0.4, ease: 'back.out(1.7)', delay: 0.1 }
      );
      
      // Animate form elements
      gsap.fromTo('.waitlist-popup__title',
        { opacity: 0, y: 30 },
        { opacity: 1, y: 0, duration: 0.5, delay: 0.3 }
      );
      gsap.fromTo('.waitlist-popup__description',
        { opacity: 0, y: 20 },
        { opacity: 1, y: 0, duration: 0.5, delay: 0.4 }
      );
      gsap.fromTo('.waitlist-popup__form-group',
        { opacity: 0, y: 20 },
        { opacity: 1, y: 0, duration: 0.4, delay: 0.5, stagger: 0.1 }
      );
      gsap.fromTo('.waitlist-popup__form-button',
        { opacity: 0, scale: 0.9 },
        { opacity: 1, scale: 1, duration: 0.4, delay: 0.7, ease: 'back.out(1.7)' }
      );
    } else {
      // Animate popup out
      gsap.to('.waitlist-popup__content',
        { scale: 0.8, opacity: 0, y: 50, duration: 0.3, ease: 'power2.in' }
      );
      gsap.to('.waitlist-popup__overlay',
        { 
          opacity: 0, 
          duration: 0.3, 
          delay: 0.1,
          onComplete: () => {
            gsap.set('.waitlist-popup', { display: 'none' });
          }
        }
      );
    }
  }, [isOpen]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    try {
      const tempPassword = 'temp-password-' + Date.now(); // Temporary password for waitlist

      // Step 1: Sign up the user
      const result = await executeSignup(() =>
        authService.signup({
          name: formData.name,
          email: formData.email,
          password: tempPassword
        })
      );

      if (result) {
        console.log('✅ Signup successful, now logging in user...');

        // Step 2: Automatically log in the user after successful signup
        try {
          const loginResult = await authService.login({
            email: formData.email,
            password: tempPassword
          });
          console.log('✅ Auto-login successful after signup');
          console.log('🎫 Login result:', loginResult);

          // Verify authentication
          const isAuthenticated = authService.isAuthenticated();
          console.log('🔐 User authenticated after login:', isAuthenticated);

          if (!isAuthenticated) {
            console.error('❌ User not authenticated despite successful login');
          }
        } catch (loginError) {
          console.error('❌ Auto-login failed after signup:', loginError);
          // Continue anyway, user can manually log in later
        }

        setIsSubmitted(true);

        // Show success animation
        gsap.fromTo('.waitlist-popup__success',
          { scale: 0, opacity: 0 },
          { scale: 1, opacity: 1, duration: 0.5, ease: 'back.out(1.7)' }
        );

        // Redirect to thank you page after success animation
        setTimeout(() => {
          onClose();
          setIsSubmitted(false);
          const userName = formData.name || 'User';
          setFormData({ name: '', email: '' });

          // Navigate to thank you page with user's name
          navigate('/thank-you', {
            state: { userName: userName }
          });
        }, 10);
      }
    } catch (error) {
      console.error('Signup failed:', error);
      // Error is handled by the useApiState hook
    }
  };

  const handleOverlayClick = (e: React.MouseEvent | React.TouchEvent) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };

  const handleCloseClick = (e: React.MouseEvent | React.TouchEvent) => {
    e.preventDefault();
    e.stopPropagation();
    onClose();
  };

  // Handle escape key press
  useEffect(() => {
    const handleEscapeKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };

    if (isOpen) {
      document.addEventListener('keydown', handleEscapeKey);
      // Prevent body scroll when popup is open
      document.body.style.overflow = 'hidden';
    }

    return () => {
      document.removeEventListener('keydown', handleEscapeKey);
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div
      className="waitlist-popup"
      onClick={handleOverlayClick}
      onTouchEnd={handleOverlayClick}
    >
      <div className="waitlist-popup__overlay" />
      <div className="waitlist-popup__content">

          <>
            <button
              className="waitlist-popup__close"
              onClick={handleCloseClick}
              onTouchEnd={handleCloseClick}
              aria-label="Close popup"
              type="button"
            >
              ×
            </button>
            
            <div className="waitlist-popup__header">
              <h2 className="waitlist-popup__title">Join the Waitlist</h2>
              <p className="waitlist-popup__description">
                Be among the first to experience LawVriksh's AI-powered platform for legal professionals.
                Get early access and exclusive updates. <strong>Limited seats available</strong> – secure your spot
                in our exclusive beta program and join the select few shaping the future of legal technology.
              </p>
            </div>

            <form className="waitlist-popup__form" onSubmit={handleSubmit}>
              <div className="waitlist-popup__form-group">
                <label htmlFor="name" className="waitlist-popup__label">Full Name</label>
                <input
                  type="text"
                  id="name"
                  name="name"
                  value={formData.name}
                  onChange={handleInputChange}
                  className="waitlist-popup__input"
                  required
                  placeholder="Enter your full name"
                />
              </div>

              <div className="waitlist-popup__form-group">
                <label htmlFor="email" className="waitlist-popup__label">Email Address</label>
                <input
                  type="email"
                  id="email"
                  name="email"
                  value={formData.email}
                  onChange={handleInputChange}
                  className="waitlist-popup__input"
                  required
                  placeholder="Enter your email address"
                />
              </div>

              <div className="waitlist-popup__form-button">
                <Button
                  type="submit"
                  disabled={signupState.loading}
                  size="large"
                >
                  {signupState.loading ? 'Joining...' : 'Join Waitlist'}
                </Button>
              </div>

              {signupState.error && (
                <ErrorMessage message={signupState.error} />
              )}
            </form>
          </>
        
      </div>
    </div>
  );
}
