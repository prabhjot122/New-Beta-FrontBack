import React, { useEffect, useRef, useState } from 'react';
import gsap from 'gsap';

interface CTASectionProps {
  contentItems: string[];
  buttonText?: string;
  onButtonClick?: () => void;
  className?: string;
}

const CTASection: React.FC<CTASectionProps> = ({
  contentItems,
  buttonText = "Click here to become founding member >",
  onButtonClick,
  className = ""
}) => {
  const [currentIndex, setCurrentIndex] = useState(0);
  const textRefs = useRef<(HTMLDivElement | null)[]>([]);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    // Initialize all text elements to hidden except the first one
    textRefs.current.forEach((ref, index) => {
      if (ref) {
        gsap.set(ref, { opacity: index === 0 ? 1 : 0 });
      }
    });

    // Start the animation cycle
    const startCycle = () => {
      intervalRef.current = setInterval(() => {
        setCurrentIndex((prevIndex) => {
          const nextIndex = (prevIndex + 1) % contentItems.length;
          
          // Animate transition
          const currentRef = textRefs.current[prevIndex];
          const nextRef = textRefs.current[nextIndex];
          
          if (currentRef && nextRef) {
            const tl = gsap.timeline();
            
            // Fade out current text
            tl.to(currentRef, {
              opacity: 0,
              duration: 0.5,
              ease: "power2.out"
            });
            
            // Fade in next text
            tl.to(nextRef, {
              opacity: 1,
              duration: 0.5,
              ease: "power2.out"
            }, "-=0.2");
          }
          
          return nextIndex;
        });
      }, 5000); // 5-second intervals
    };

    startCycle();

    // Cleanup on unmount
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [contentItems.length]);

  const handleButtonClick = () => {
    if (onButtonClick) {
      onButtonClick();
    }
  };

  return (
    <div className={`homepage__cta-animated-section ${className}`}>
      <div className="homepage__cta-animated-container">
        {/* Enhanced content wrapper with improved mobile hierarchy */}
        <div className="homepage__cta-animated-content-wrapper">
          <div className="homepage__cta-animated-content">
            {contentItems.map((content, index) => (
              <div
                key={index}
                ref={(el) => (textRefs.current[index] = el)}
                className={`homepage__cta-animated-text ${index === currentIndex ? 'active' : ''}`}
              >
                {content}
              </div>
            ))}
          </div>

          {/* Enhanced mobile-optimized button with professional styling */}
          <div className="homepage__cta-button-wrapper">
            <button className="homepage__cta-animated-button" onClick={handleButtonClick}>
              <span className="homepage__cta-button-text">{buttonText}</span>
              <span className="homepage__cta-button-arrow">→</span>
            </button>

            {/* Mobile-specific visual enhancement */}
            <div className="homepage__cta-button-accent"></div>
          </div>
        </div>

        {/* Mobile visual enhancement elements */}
        <div className="homepage__cta-mobile-decorative">
          <div className="homepage__cta-decorative-line"></div>
        </div>
      </div>
    </div>
  );
};

export default CTASection;
