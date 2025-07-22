import { useEffect, useRef } from 'react';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

interface MarketData {
  label: string;
  current: number;
  projected: number;
  unit: string;
  color: string;
}

export default function MarketGrowth() {
  const sectionRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<HTMLDivElement>(null);

  const marketData: MarketData[] = [
    {
      label: "Legal Tech Market",
      current: 31.6,
      projected: 63.6,
      unit: "B",
      color: "#966f33"
    },
    {
      label: "Creator Economy", 
      current: 191.6,
      projected: 528.4,
      unit: "B",
      color: "#b99c6d"
    },
    {
      label: "Online Education",
      current: 49.0,
      projected: 325.0,
      unit: "B", 
      color: "#d4b896"
    },
    {
      label: "India Legal Services",
      current: 2.5,
      projected: 3.4,
      unit: "B",
      color: "#e5cca4"
    },
    {
      label: "Total Addressable Market",
      current: 0,
      projected: 917,
      unit: "B",
      color: "#8b5a2b"
    }
  ];

  useEffect(() => {
    if (!chartRef.current) return;

    // Set initial state for all bars and values
    gsap.set('.market-growth__bar-current', { width: 0 });
    gsap.set('.market-growth__bar-projected', { width: 0 });
    gsap.set('.market-growth__value', { textContent: '0' });

    // Create scroll trigger for the market growth section
    ScrollTrigger.create({
      trigger: sectionRef.current,
      start: "top 70%",
      end: "bottom 30%",
      onEnter: () => {
        // Animate bars and values
        marketData.forEach((data, index) => {
          const currentBar = document.querySelector(`.market-growth__bar-current-${index}`);
          const projectedBar = document.querySelector(`.market-growth__bar-projected-${index}`);
          const currentValue = document.querySelector(`.market-growth__value-current-${index}`);
          const projectedValue = document.querySelector(`.market-growth__value-projected-${index}`);

          if (currentBar && projectedBar && currentValue && projectedValue) {
            // Calculate widths based on the largest projected value for scaling
            const maxValue = Math.max(...marketData.map(d => d.projected));
            const currentWidth = (data.current / maxValue) * 100;
            const projectedWidth = (data.projected / maxValue) * 100;

            // Animate current bars first (if they exist)
            if (data.current > 0) {
              gsap.to(currentBar, {
                width: `${currentWidth}%`,
                duration: 1.5,
                delay: index * 0.15,
                ease: "power2.out"
              });

              // Animate current values counting up
              gsap.to(currentValue, {
                textContent: data.current,
                duration: 1.5,
                delay: index * 0.15,
                ease: "power2.out",
                snap: { textContent: 0.1 },
                onUpdate: function() {
                  const value = parseFloat(this.targets()[0].textContent);
                  this.targets()[0].textContent = `$${value.toFixed(1)}${data.unit}`;
                }
              });
            }

            // Animate projected bars with slight delay
            gsap.to(projectedBar, {
              width: `${projectedWidth}%`,
              duration: 1.5,
              delay: index * 0.15 + (data.current > 0 ? 0.2 : 0),
              ease: "power2.out"
            });

            // Animate projected values counting up
            gsap.to(projectedValue, {
              textContent: data.projected,
              duration: 1.5,
              delay: index * 0.15 + (data.current > 0 ? 0.2 : 0),
              ease: "power2.out",
              snap: { textContent: 0.1 },
              onUpdate: function() {
                const value = parseFloat(this.targets()[0].textContent);
                this.targets()[0].textContent = `$${value.toFixed(1)}${data.unit}`;
              }
            });
          }
        });
      },
      // Add onLeave to reset animations when scrolling back up
      onLeave: () => {
        // Optional: Reset animations when leaving the section
      },
      onEnterBack: () => {
        // Optional: Re-trigger animations when scrolling back down
      }
    });

    return () => {
      ScrollTrigger.getAll().forEach(trigger => {
        if (trigger.trigger === sectionRef.current) {
          trigger.kill();
        }
      });
    };
  }, []);

  return (
    <div ref={sectionRef} className="market-growth">
      <div className="market-growth__content">
        <div className="market-growth__text">
          {/* Mobile heading */}
          <h2 className="market-growth__title market-growth__title--mobile">
            Market Growth &<br />Revenue Projections
          </h2>
          {/* Desktop heading */}
          <h2 className="market-growth__title market-growth__title--desktop">
            Market <br />Growth &<br />Revenue<br /> Projections
          </h2>
          <p className="market-growth__description hide-on-mobile">
            LawVriksh is positioned at the intersection of rapidly expanding markets. 
            The legal technology sector is experiencing unprecedented growth, while the 
            creator economy and online education markets are reshaping how professionals 
            monetize their expertise. Our platform captures value across these converging 
            trillion-dollar opportunities.
          </p>
        </div>
      </div>
      
      <div className="market-growth__chart" ref={chartRef}>
        <div className="market-growth__chart-container">
          <h3 className="market-growth__chart-title">Market Size by 2030</h3>
          <div className="market-growth__bars">
            {marketData.map((data, index) => (
              <div key={index} className="market-growth__bar-group">
                <div className="market-growth__bar-label">{data.label}</div>
                <div className="market-growth__bar-container">
                  <div className="market-growth__bar-track">
                    {data.current > 0 && (
                      <div 
                        className={`market-growth__bar market-growth__bar-current market-growth__bar-current-${index}`}
                        style={{ backgroundColor: data.color }}
                      />
                    )}
                    <div 
                      className={`market-growth__bar market-growth__bar-projected market-growth__bar-projected-${index}`}
                      style={{ backgroundColor: data.color, opacity: 0.7 }}
                    />
                  </div>
                  <div className="market-growth__values">
                    {data.current > 0 && (
                      <span className={`market-growth__value market-growth__value-current-${index}`}>
                        $0{data.unit}
                      </span>
                    )}
                    <span className={`market-growth__value market-growth__value-projected market-growth__value-projected-${index}`}>
                      $0{data.unit}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
          <div className="market-growth__legend">
            <div className="market-growth__legend-item">
              <div className="market-growth__legend-color" style={{ backgroundColor: '#966f33' }}></div>
              <span>Current Market Size</span>
            </div>
            <div className="market-growth__legend-item">
              <div className="market-growth__legend-color" style={{ backgroundColor: '#966f33', opacity: 0.7 }}></div>
              <span>Projected by 2030</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
