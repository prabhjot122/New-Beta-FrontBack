import React from 'react';
import { gsap } from 'gsap';
// import { ScrollTrigger } from 'gsap/ScrollTrigger';
import './ScrollProgressIndicator.css';

interface ScrollProgressIndicatorProps {
  activeIndex: number;
  totalSections: number;
  sectionTitles?: string[];
  onSectionClick?: (index: number) => void;
  visible?: boolean;
}

const ScrollProgressIndicator: React.FC<ScrollProgressIndicatorProps> = ({
  activeIndex,
  totalSections,
  sectionTitles = [],
  onSectionClick,
  visible = true
}) => {
  const handleCircleClick = (index: number) => {
    if (onSectionClick) {
      onSectionClick(index);
    } else {
      // Default behavior: scroll to the corresponding section
      const homepage2Element = document.querySelector('.homepage2');
      if (homepage2Element) {
        const progress = index / (totalSections - 1);
        const scrollPosition = homepage2Element.getBoundingClientRect().top + window.pageYOffset;
        const sectionHeight = homepage2Element.clientHeight;
        const targetScroll = scrollPosition + (sectionHeight * progress * 3); // Multiply by 3 for the pinned section length

        gsap.to(window, {
          duration: 1.5,
          scrollTo: targetScroll,
          ease: "power2.inOut"
        });
      }
    }
  };

  return (
    <div className={`scroll-progress-indicator ${visible ? 'visible' : 'hidden'}`}>
      <div className="scroll-progress-container">
        {Array.from({ length: totalSections }, (_, index) => (
          <div
            key={index}
            className={`scroll-progress-circle ${
              index <= activeIndex ? 'active' : ''
            }`}
            title={sectionTitles[index] || `Section ${index + 1}`}
            onClick={() => handleCircleClick(index)}
            role="button"
            tabIndex={0}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                handleCircleClick(index);
              }
            }}
            aria-label={`Navigate to ${sectionTitles[index] || `Section ${index + 1}`}`}
          >
            <div className="scroll-progress-circle-inner"></div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ScrollProgressIndicator;
