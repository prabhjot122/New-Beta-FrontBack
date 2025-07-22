import React, { useEffect, useState } from 'react';
import Button from './Button';
import './Navbar.css';
import { gsap } from 'gsap';
import { ScrollToPlugin } from 'gsap/ScrollToPlugin';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

// Register GSAP plugins
gsap.registerPlugin(ScrollToPlugin, ScrollTrigger);

interface NavbarProps {
  onJoinWaitlist?: () => void;
}

const Navigation = () => {
  // Handle URL hash navigation on page load
  useEffect(() => {
    const handleHashNavigation = () => {
      const hash = window.location.hash.substring(1); // Remove the # symbol
      if (hash) {
        // Small delay to ensure page is fully loaded
        setTimeout(() => {
          let targetElement: HTMLElement | null = null;
          const scrollOffset = 80;

          // Handle specific hash cases
          if (hash === 'home') {
            // Scroll to top for home
            gsap.to(window, {
              duration: 0.8,
              scrollTo: { y: 0 },
              ease: "power2.out"
            });
            return;
          } else if (hash === 'contact-us') {
            targetElement = document.getElementById('contact-us');
          } else if (hash === 'why-us') {
            targetElement = document.getElementById('why-us');
          } else {
            targetElement = document.getElementById(hash);
          }

          if (targetElement) {
            gsap.to(window, {
              duration: 0.8,
              scrollTo: {
                y: targetElement,
                offsetY: scrollOffset
              },
              ease: "power2.out"
            });
          }
        }, 50);
      }
    };

    // Handle initial page load with hash
    handleHashNavigation();

    // Handle hash changes (browser back/forward)
    window.addEventListener('hashchange', handleHashNavigation);

    return () => {
      window.removeEventListener('hashchange', handleHashNavigation);
    };
  }, []);

  const handleSmoothScroll = (e: React.MouseEvent<HTMLAnchorElement>, targetId: string) => {
    e.preventDefault();

    // Check if we're on the homepage (has .homepage element)
    const isOnHomepage = document.querySelector('.homepage') !== null;

    if (!isOnHomepage) {
      // If not on homepage, navigate to homepage first, then scroll
      window.location.href = `/#${targetId}`;
      return;
    }

    let targetElement: HTMLElement | null = null;
    const scrollOffset = 80; // Reduced offset for better positioning

    // Handle different target sections
    switch (targetId) {
      case 'home':
        // Scroll to the very top of the page (hero section)
        gsap.to(window, {
          duration: 0.8,
          scrollTo: { y: 0 },
          ease: "power2.out",
          overwrite: true // Prevent conflicts with other animations
        });
        return;

      case 'contact-us':
        targetElement = document.getElementById('contact-us');
        break;

      case 'why-us':
        targetElement = document.getElementById('why-us');
        break;

      default:
        targetElement = document.getElementById(targetId);
    }

    if (targetElement) {
      // Kill any existing scroll animations first
      gsap.killTweensOf(window);

      // Calculate target position
      const targetTop = targetElement.offsetTop - scrollOffset;

      // Use faster, more reliable scrolling with fallback for other sections
      gsap.to(window, {
        duration: 0.8,
        scrollTo: {
          y: targetElement,
          offsetY: scrollOffset
        },
        ease: "power2.out",
        overwrite: true,
        onComplete: () => {
          // Verify we reached the target
          const currentScroll = window.pageYOffset || document.documentElement.scrollTop;
          const tolerance = 15; // Allow 15px tolerance

          if (Math.abs(currentScroll - targetTop) > tolerance) {
            // If we didn't reach the target, do a quick correction
            window.scrollTo({
              top: targetTop,
              behavior: 'auto' // Use instant scroll for correction
            });
          }
        },
        onInterrupt: () => {
          // If animation is interrupted, fallback to native scroll
          window.scrollTo({
            top: targetTop,
            behavior: 'smooth'
          });
        }
      });

      // Fallback timeout in case GSAP fails
      setTimeout(() => {
        const currentScroll = window.pageYOffset || document.documentElement.scrollTop;
        if (Math.abs(currentScroll - targetTop) > 50) {
          // If we're still far from target after timeout, use native scroll
          gsap.killTweensOf(window);
          window.scrollTo({
            top: targetTop,
            behavior: 'smooth'
          });
        }
      }, 1000);
    }
  };

  return (
    <div className="navbar__nav">
      <a href="#home" className="navbar__nav-link" onClick={(e) => handleSmoothScroll(e, 'home')}>Home</a>
      <span className="navbar__nav-separator"> • </span>
      <a href="#contact-us" className="navbar__nav-link" onClick={(e) => handleSmoothScroll(e, 'contact-us')}>Contact Us</a>
      <span className="navbar__nav-separator"> • </span>
      <a href="#why-us" className="navbar__nav-link" onClick={(e) => handleSmoothScroll(e, 'why-us')}>Why Us</a>
    </div>
  );
};

export default function Navbar({ onJoinWaitlist }: NavbarProps) {
  const [isScrolled, setIsScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      const scrollPosition = window.scrollY;
      const threshold = 80; // Scroll threshold in pixels

      setIsScrolled(prevIsScrolled => {
        const shouldBeScrolled = scrollPosition > threshold;
        // Only update state if it actually changed
        if (prevIsScrolled !== shouldBeScrolled) {
          return shouldBeScrolled;
        }
        return prevIsScrolled;
      });
    };

    // Add scroll event listener
    window.addEventListener('scroll', handleScroll);

    // Cleanup function to remove event listener
    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  }, []);

  return (
    <nav className={`navbar ${isScrolled ? 'navbar--scrolled' : ''}`}>
      <div className="navbar__brand">
        LawVriksh
      </div>

      <div className="navbar__content">
        <Navigation />

        <Button onClick={onJoinWaitlist}>
          Join Waitlist
        </Button>
      </div>
    </nav>
  );
}
