import Button from "./Button";
import "./Homepage.css";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { ScrollToPlugin } from "gsap/ScrollToPlugin";
import Navbar from "./Navbar";
import WhyUs from "./WhyUs";
import MarketGrowth from "./MarketGrowth";
import WaitlistPopup from "./WaitlistPopup";
import Footer from "./Footer";
import { useState, useEffect, useMemo } from "react";
import HomepageMobile from "./HomepageMobile";
import ScrollProgressIndicator from "./ScrollProgressIndicator";
import CTASection from "./CTASection";

// Register ScrollTrigger and ScrollToPlugin
gsap.registerPlugin(ScrollTrigger, ScrollToPlugin);

export default function Homepage() {
  const [isWaitlistPopupOpen, setIsWaitlistPopupOpen] = useState(false);

  // State tracking for section animation completion and scroll direction
  const [sectionAnimated, setSectionAnimated] = useState({
    homepage: false,
    homepage2: false,
    marketGrowth: false,
    homepage3: false,
    homepage4: false,
    teamTestimonial: false,
    foundingMemberPerks: false,
    cta: false
  });

  const [scrollDirection, setScrollDirection] = useState('down');
  const [lastScrollY, setLastScrollY] = useState(0);
  const [isMobile, setIsMobile] = useState(false);
  const [currentQuoteIndex, setCurrentQuoteIndex] = useState(0);
  const [hoveredFeature, setHoveredFeature] = useState<number | null>(null);
  // const [scrollProgress, setScrollProgress] = useState(0);
  const [currentDividerTextIndex, setCurrentDividerTextIndex] = useState(0);

  // Testimonial system state
  const [currentPersonIndex, setCurrentPersonIndex] = useState(0);
  const [currentTestimonialIndex, setCurrentTestimonialIndex] = useState(0);
  const [isTransitioning, setIsTransitioning] = useState(false);

  // Testimonial data structure for the new interactive system
  const testimonialsData = useMemo(() => [
      {
        id: 1,
        name: "Suhani Jain",
        credentials: "BA. LLB, 3rd Year, Jagran Lakecity University, Bhopal",
        image: "/suhanijain.jpg",
        testimonials: [
          "One of the biggest challenges I face... is striking the right balance between accessibility and accuracy. Simplifying them for a general audience without losing the nuance—or worse, spreading misinformation—is a constant struggle.",
          "I believe lawyers should absolutely monetize their expertise through writing... However, the reason many... may hesitate... is due to a mix of time constraints, uncertainty about monetization models, and fear of non-compliance.",
          "For me, the most time-consuming part of writing a legal article is the structuring and outlining phase... crafting a coherent flow that integrates statutes, case law, and interpretation is a mentally demanding task."
        ]
      },
      {
        id: 2,
        name: "Ritanshu Dhangar",
        credentials: "BA. LLB, 5th Year, Mangalayatan University, Jabalpur",
        image: "/ritanshu.jpg",
        testimonials: [
          "Between court, clients, and paperwork, it's tough to sit down and write.",
          "Research: Even if you know the topic, you need to check the latest laws and cases.",
          "Not sure how to start or where to post and earn."
        ]
      },
      {
        id: 3,
        name: "Tanisha Srivastava",
        credentials: "BA. LLB, 5th Year, Mangalayatan University, Jabalpur",
        image: "/tanisha.jpg",
        testimonials: [
          "...rather than focusing on what I am saying they start to judge my credibility... and that in turn makes it difficult to... put forth your Idea or your insight."
        ]
      },
      {
        id: 4,
        name: "Dr. Vartika Pandey",
        credentials: "Professor, MUJ",
        image: "/suhanijain.jpg",
        testimonials: [
          "The most significant investment of time in my writing process is dedicated to the rigorous task of plagiarism removal. This crucial step ensures the absolute credibility and originality of the final work."
        ]
      },
      {
        id: 5,
        name: "Paras Shukla",
        credentials: "LLB(H) complete. Practicing lawyer at MP High court and District and session court Jabalpur",
        image: "/paras.jpg",
        testimonials: [
          "The biggest hurdle is simplifying complex legal concepts for a general audience without losing accuracy, along with the lack of visibility on credible platforms.",
          "Monetizing legal writing is a great idea, but uncertainty about where to start and ethical concerns have kept me from exploring it more.",
          "Research and ensuring legal accuracy take the most time, especially when balancing clarity with technical depth."
        ]
      },
      {
        id: 6,
        name: "Om Patil",
        credentials: "Mangalayatan University Jabalpur Ba.llb 5th year",
        image: "/ompatil.jpg",
        testimonials: [
          "When sharing legal insights online, a big frustration is second-guessing my opinion—worrying it might hurt someone's feelings or credibility. Another is explaining my thoughts to overconfident people who act like they already know everything.",
          "The most time consuming part of the legal article writing is content framing and the legal citeations and formatting all the articles and  , these are the main reasons which causes time consuming parts of the article writing"
        ]
      }
    ], []);

  // Mobile detection hook
  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth <= 767);
    };

    checkMobile();
    window.addEventListener('resize', checkMobile);

    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  const handleJoinWaitlist = () => {
    setIsWaitlistPopupOpen(true);
  };

  const handleCloseWaitlistPopup = () => {
    setIsWaitlistPopupOpen(false);
  };

  // Dialog content for each feature with heading-description structure
  const dialogContent = {
    0: { // Features
      title: "Features",
      items: [
        {
          heading: "The 60% Solution: Your AI Co-Pilot",
          description: "You spend up to 60% of your time on research and content creation. Our legal-specific AI, trained on Indian compliance and frameworks, automates your drafting process and frees you to focus on what truly matters—your expertise."
        },
        {
          heading: "Beyond the Billable Hour: The Monetization Hub",
          description: "The $191.6 billion creator economy has largely excluded legal professionals. Our platform provides the first direct path from legal expertise to sustainable revenue with credit-based economy and premium subscription tools."
        },
        {
          heading: "Your Digital Gavel: The Automated Portfolio",
          description: "While 73% of legal professionals use digital tools, they lack a comprehensive system to showcase expertise. Our Automated Portfolio Builder creates a credible, SEO-optimized digital presence with Professional Verification System."
        },
        {
          heading: "An All-India Reach: The Multilingual Engine",
          description: "Your insights are too valuable to be confined to one language. Our platform's multi-language support allows you to create and disseminate work across India's diverse linguistic landscape, reaching wider audiences."
        }
      ]
    },
    1: { // Why You Should Join Us
      title: "Why You Should Join Us",
      items: [
        {
          heading: "Founding Member Badge",
          description: "Claim the permanent 'Founding Member' badge, a mark of distinction no one else can ever earn. Solidify your legacy as a pioneer in India's new legal economy."
        },
        {
          heading: "Early Access & Homepage Feature",
          description: "Get every groundbreaking feature before the public and be featured on our homepage. This is your unignorable advantage to build instant authority and dominate the digital space."
        },
        {
          heading: "Premium Access & Exclusive Events",
          description: "Enjoy 3 months of unrestricted premium access to build your digital brand, on us. Plus, get an exclusive seat at closed-door strategy events with legal industry titans."
        },
        {
          heading: "Lifetime Status & Inner Circle",
          description: "Become a Founding Member for a lifetime of status and a perpetual head start. Secure your place in the inner circle before the door closes forever."
        }
      ]
    },
    2: { // Testimonials
      title: "Testimonials",
      items: [
        {
          heading: "Suhani Jain",
          profession: "BA. LLB, 3rd Year, Jagran Lakecity University, Bhopal",
          testimonials: [
            "One of the biggest challenges I face... is striking the right balance between accessibility and accuracy. Simplifying them for a general audience without losing the nuance—or worse, spreading misinformation—is a constant struggle.",
            "I believe lawyers should absolutely monetize their expertise through writing... However, the reason many... may hesitate... is due to a mix of time constraints, uncertainty about monetization models, and fear of non-compliance.",
            "For me, the most time-consuming part of writing a legal article is the structuring and outlining phase... crafting a coherent flow that integrates statutes, case law, and interpretation is a mentally demanding task."
          ]
        },
        {
          heading: "Ritanshu Dhangar",
          profession: "BA. LLB, 5th Year, Mangalayatan University, Jabalpur",
          testimonials: [
            "Between court, clients, and paperwork, it's tough to sit down and write.",
            "Research: Even if you know the topic, you need to check the latest laws and cases.",
            "Not sure how to start or where to post and earn."
          ]
        },
        {
          heading: "Tanisha Agarwal",
          profession: "BA. LLB, 5th Year, Mangalayatan University, Jabalpur",
          testimonials: [
            "...rather than focusing on what I am saying they start to judge my credibility... and that in turn makes it difficult to... put forth your Idea or your insight."

          ]
        },
        {
          heading: "Vartika Sharma",
          profession: "Professor, MUJ",
          testimonials: [
            "The most significant investment of time in my writing process is dedicated to the rigorous task of plagiarism removal. This crucial step ensures the absolute credibility and originality of the final work.",

          ]
        },
        {
          heading: "Paras Shukla",
          profession: "LLB(H) complete. Practicing lawyer at MP High court and District and session court Jabalpur",
          testimonials: [
            "The biggest hurdle is simplifying complex legal concepts for a general audience without losing accuracy, along with the lack of visibility on credible platforms.",
            "Monetizing legal writing is a great idea, but uncertainty about where to start and ethical concerns have kept me from exploring it more.",
            "Research and ensuring legal accuracy take the most time, especially when balancing clarity with technical depth."
          ]
        },
        {
          heading: "Om Patil",
          profession: "Mangalayatan University Jabalpur Ba.llb 5th year",
          testimonials: [
            "When sharing legal insights online, a big frustration is second-guessing my opinion—worrying it might hurt someone's feelings or credibility. Another is explaining my thoughts to overconfident people who act like they already know everything.",
            "The most time consuming part of the legal article writing is content framing and the legal citeations and formatting all the articles and  , these are the main reasons which causes time consuming parts of the article writing"
          ]
        }
      ]
    }
  };

  // Enhanced hover logic for interactive dialog
  const [isDialogHovered, setIsDialogHovered] = useState(false);
  const [hoverTimeout, setHoverTimeout] = useState<NodeJS.Timeout | null>(null);

  // Expandable testimonials state
  const [expandedTestimonial, setExpandedTestimonial] = useState<number | null>(null);

  const handleFeatureHover = (index: number) => {
    // Clear any existing timeout
    if (hoverTimeout) {
      clearTimeout(hoverTimeout);
      setHoverTimeout(null);
    }
    setHoveredFeature(index);
  };

  const handleFeatureLeave = () => {
    // Delay closing to allow transition to dialog
    const timeout = setTimeout(() => {
      if (!isDialogHovered) {
        setHoveredFeature(null);
      }
    }, 150); // 150ms delay for smooth transition
    setHoverTimeout(timeout);
  };

  const handleDialogEnter = () => {
    // Clear any pending close timeout
    if (hoverTimeout) {
      clearTimeout(hoverTimeout);
      setHoverTimeout(null);
    }
    setIsDialogHovered(true);
  };

  const handleDialogLeave = () => {
    setIsDialogHovered(false);
    // Close dialog after a brief delay
    const timeout = setTimeout(() => {
      setHoveredFeature(null);
      setExpandedTestimonial(null); // Reset expanded testimonial when dialog closes
    }, 100);
    setHoverTimeout(timeout);
  };

  // Handle testimonial expansion
  const handleTestimonialClick = (index: number) => {
    if (hoveredFeature === 2) { // Only for testimonials dialog
      setExpandedTestimonial(expandedTestimonial === index ? null : index);
    }
  };

  // Divider text array for rotation
  const dividerTexts = [
    "For the time you lose to non-billable work.",
    "For your rightful place in the creator economy.",
    "For a professional brand that's scattered and unseen.",
    "We are For the 90% of India that doesn't speak English as a first language."
  ];

  // Divider text rotation effect
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentDividerTextIndex((prevIndex) =>
        (prevIndex + 1) % dividerTexts.length
      );
    }, 3000); // Change every 3 seconds

    return () => clearInterval(interval);
  }, [dividerTexts.length]);

  // Smooth scrolling implementation and scroll direction tracking
  useEffect(() => {
    // Track scroll direction and progress
    const handleScroll = () => {
      const currentScrollY = window.scrollY;
      if (currentScrollY > lastScrollY) {
        setScrollDirection('down');
      } else if (currentScrollY < lastScrollY) {
        setScrollDirection('up');
      }
      setLastScrollY(currentScrollY);

      // Calculate scroll progress for the progress indicator
      // const documentHeight = document.documentElement.scrollHeight - window.innerHeight;
      // const progress = documentHeight > 0 ? (currentScrollY / documentHeight) * 100 : 0;
      // setScrollProgress(Math.min(100, Math.max(0, progress)));
    };

    // Create smooth scrolling for the entire page
    const smoothScroll = (target: number, duration: number = 1.5) => {
      gsap.to(window, {
        duration: duration,
        scrollTo: { y: target, autoKill: true },
        ease: "power2.inOut"
      });
    };

    // Handle smooth scrolling for anchor links and navigation
    const handleSmoothScroll = (e: Event) => {
      const target = e.target as HTMLElement;
      if (target.tagName === 'A' && target.getAttribute('href')?.startsWith('#')) {
        e.preventDefault();
        const targetId = target.getAttribute('href')?.substring(1);
        const targetElement = document.getElementById(targetId || '');
        if (targetElement) {
          const targetPosition = targetElement.offsetTop;
          smoothScroll(targetPosition);
        }
      }
    };

    // Add event listeners
    window.addEventListener('scroll', handleScroll, { passive: true });
    document.addEventListener('click', handleSmoothScroll);

    // Custom smooth scroll for wheel events (optional - for ultra-smooth experience)
    // let isScrolling = false;
    // const handleWheel = (e: WheelEvent) => {
    //   if (isScrolling) return;

    //   e.preventDefault();
    //   isScrolling = true;

    //   const currentScroll = window.pageYOffset;
    //   const delta = e.deltaY;
    //   const scrollAmount = delta > 0 ? 100 : -100;
    //   const targetScroll = Math.max(0, currentScroll + scrollAmount);

    //   gsap.to(window, {
    //     duration: 0.8,
    //     scrollTo: { y: targetScroll, autoKill: true },
    //     ease: "power2.out",
    //     onComplete: () => {
    //       isScrolling = false;
    //     }
    //   });
    // };

    // Uncomment the line below for ultra-smooth wheel scrolling (optional)
    // document.addEventListener('wheel', handleWheel, { passive: false });

    return () => {
      window.removeEventListener('scroll', handleScroll);
      document.removeEventListener('click', handleSmoothScroll);
      // document.removeEventListener('wheel', handleWheel);
    };
  }, [lastScrollY]);

  // Effect to recreate ScrollTriggers when animation state or scroll direction changes
  useEffect(() => {
    ScrollTrigger.refresh();
  }, [sectionAnimated, scrollDirection]);

  // Handle window resize for responsive animations
  useEffect(() => {
    const handleResize = () => {
      // Refresh ScrollTrigger on resize
      ScrollTrigger.refresh();

      // Refresh features section animations on resize
      ScrollTrigger.getAll().forEach(trigger => {
        if (trigger.trigger && trigger.trigger.classList.contains('homepage2')) {
          trigger.kill();
        }
      });

      // Features scroll trigger will be recreated in useGSAP
    };

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, [sectionAnimated.homepage2]);

  // Auto-cycling testimonials effect with smooth animation
  useEffect(() => {
    const interval = setInterval(() => {
      // Animate out current testimonial
      gsap.to(".homepage__testimonials-quote-text", {
        opacity: 0,
        y: -20,
        duration: 0.3,
        ease: "power2.in",
        onComplete: () => {
          // Update testimonial index
          setCurrentTestimonialIndex(prevIndex => {
            const currentPerson = testimonialsData[currentPersonIndex];
            return (prevIndex + 1) % currentPerson.testimonials.length;
          });

          // Animate in new testimonial
          gsap.fromTo(".homepage__testimonials-quote-text",
            { opacity: 0, y: 20 },
            {
              opacity: 1,
              y: 0,
              duration: 0.4,
              ease: "power2.out",
              delay: 0.1
            }
          );
        }
      });
    }, 4000); // 4 seconds

    return () => clearInterval(interval);
  }, [currentPersonIndex, testimonialsData]);

  // Add wheel event listener for testimonial image to handle preventDefault properly
  useEffect(() => {
    const testimonialImage = document.querySelector('.testimonialimage');
    if (!testimonialImage) return;

    const handleWheel = (e: Event) => {
      const wheelEvent = e as WheelEvent;
      e.preventDefault();
      e.stopPropagation();

      // Prevent rapid scrolling during transition
      if (isTransitioning) return;

      setIsTransitioning(true);

      // Create smooth transition animation
      const tl = gsap.timeline({
        onComplete: () => setIsTransitioning(false)
      });

      // Animate out current content
      tl.to([
        ".homepage__testimonials-person-info",
        ".homepage__testimonials-quote-text",
        ".testimonialimage"
      ], {
        opacity: 0,
        y: wheelEvent.deltaY > 0 ? -30 : 30,
        duration: 0.3,
        ease: "power2.in",
        stagger: 0.05
      })
      .call(() => {
        // Update person index
        if (wheelEvent.deltaY > 0) {
          // Scroll down - next person
          setCurrentPersonIndex(prevIndex => (prevIndex + 1) % testimonialsData.length);
        } else {
          // Scroll up - previous person
          setCurrentPersonIndex(prevIndex =>
            prevIndex === 0 ? testimonialsData.length - 1 : prevIndex - 1
          );
        }

        // Reset testimonial index when switching person
        setCurrentTestimonialIndex(0);
      })
      // Animate in new content
      .fromTo([
        ".homepage__testimonials-person-info",
        ".homepage__testimonials-quote-text",
        ".testimonialimage"
      ],
      {
        opacity: 0,
        y: wheelEvent.deltaY > 0 ? 30 : -30
      },
      {
        opacity: 1,
        y: 0,
        duration: 0.4,
        ease: "power2.out",
        stagger: 0.05
      });
    };

    testimonialImage.addEventListener('wheel', handleWheel, { passive: false });

    return () => {
      testimonialImage.removeEventListener('wheel', handleWheel);
    };
  }, [isTransitioning, testimonialsData, currentPersonIndex]);



  useGSAP(() => {
    // Initialize all animated elements to hidden state
    gsap.set([
      ".homepage__hero",
      ".homepage__hero-title",
      ".homepage__hero-word",
      ".homepage__main-title",
      ".homepage__main-content",
      ".homepage__feature-item"
    ], {
      opacity: 0,
      y: 50,
      x: 0
    });

    // Set responsive initial positions for hero elements
    const getResponsiveOffset = () => {
      const vw = window.innerWidth;
      if (vw <= 767) {
        return { large: 50, medium: 30, small: 20 };
      } else if (vw <= 1024) {
        return { large: 100, medium: 60, small: 40 };
      } else {
        return { large: 800, medium: 100, small: 50 };
      }
    };

    const offsets = getResponsiveOffset();

    gsap.set(".homepage__hero", { x: offsets.large, y: 0 });
    gsap.set(".homepage__hero-title", { x: -offsets.large, y: 0 });
    gsap.set(".homepage__hero-word", { x: offsets.small, y: 0 });
    gsap.set(".homepage__main-title", { x: offsets.medium, y: 0 });
    gsap.set(".homepage__main-content", { x: offsets.medium, y: 0 });
    gsap.set(".homepage__feature-item", { y: offsets.medium, x: 0 });

    // Section 1: Hero Section with Scroll-Back Optimization
    const createHeroScrollTrigger = () => {
      ScrollTrigger.create({
        trigger: ".homepage",
        start: "top top",
        end: sectionAnimated.homepage ? "bottom top" : "+=100%",
        pin: !sectionAnimated.homepage && scrollDirection === 'down',
        scrub: false,
        onEnter: () => {
          if (!sectionAnimated.homepage && scrollDirection === 'down') {
            // Hero section animations sequence (only on first visit scrolling down)
            const tl = gsap.timeline({
              onComplete: () => {
                setSectionAnimated(prev => ({ ...prev, homepage: true }));
                // Refresh ScrollTrigger after animation completes
                ScrollTrigger.refresh();
              }
            });

            tl.to(".homepage__hero", {
              duration: 1,
              opacity: 1,
              x: 0,
              ease: "power2.out"
            })
            .to(".homepage__hero-title", {
              duration: 0.5,
              opacity: 1,
              x: 0,
              ease: "power2.out"
            }, "-=0.5")
            .to(".homepage__hero-word", {
              duration: 0.3,
              opacity: 1,
              x: 0,
              stagger: 0.3,
              ease: "power2.out"
            }, "-=0.3")
            .to(".homepage__main-title", {
              duration: 0.5,
              opacity: 1,
              x: 0,
              ease: "power2.out"
            }, "-=0.5")
            .to(".homepage__main-content", {
              duration: 0.5,
              opacity: 1,
              x: 0,
              ease: "power2.out"
            }, "-=0.7")
            .to(".homepage__feature-item", {
              duration: 0.1,
              opacity: 1,
              y: 0,
              stagger: 0.1,
              ease: "power2.out"
            }, "-=0.5");
          }
        }
      });
    };

    createHeroScrollTrigger();

    // Features Section (homepage2) Scroll-Triggered Image Carousel with Scroll-Back Optimization
    const createFeaturesScrollTrigger = () => {
      let currentActiveFeature = 0;
      let isTransitioning = false;
      let activeTimeline: gsap.core.Timeline | null = null;

      // Function to cleanup active animations
      const cleanupAnimations = () => {
        if (activeTimeline) {
          activeTimeline.kill();
          activeTimeline = null;
        }
      };

      // Function to transition to a specific feature
      const transitionToFeature = (targetFeature: number) => {
        if (isTransitioning || targetFeature === currentActiveFeature) return;

        isTransitioning = true;
        cleanupAnimations();

        const featureContents = document.querySelectorAll('.homepage__feature-content-item');
        const featureImage = document.querySelector('.homepage__feature-image') as HTMLElement;

        // Create timeline for synchronized transitions
        activeTimeline = gsap.timeline({
          onComplete: () => {
            // Update CSS classes for proper state management
            featureContents.forEach((content, index) => {
              const element = content as HTMLElement;
              if (index === targetFeature) {
                element.classList.add('active');
              } else {
                element.classList.remove('active');
              }
            });

            currentActiveFeature = targetFeature;
            isTransitioning = false;
            activeTimeline = null;
          }
        });

        // First, fade out current feature if it's different
        if (currentActiveFeature !== targetFeature) {
          const currentElement = featureContents[currentActiveFeature] as HTMLElement;
          if (currentElement) {
            activeTimeline.to(currentElement, {
              opacity: 0,
              y: -10,
              duration: 0.25,
              ease: "power2.in"
            });
          }
        }

        // Simultaneously change background image and fade in new content
        activeTimeline.call(() => {
          if (featureImage) {
            const imageUrls = ['/feature1.png', '/feature2.png', '/feature3.png', '/feature4.png'];
            featureImage.style.backgroundImage = `url("${imageUrls[targetFeature]}")`;
          }
        })
        .to(featureContents[targetFeature], {
          opacity: 1,
          y: 0,
          duration: 0.35,
          ease: "power2.out"
        }, currentActiveFeature !== targetFeature ? "-=0.05" : "0"); // Slight overlap only if transitioning
      };

      ScrollTrigger.create({
        trigger: ".homepage2",
        start: "top top",
        end: sectionAnimated.homepage2 ? "bottom top" : "+=300%",
        pin: !sectionAnimated.homepage2 && scrollDirection === 'down',
        scrub: 1,
        onEnter: () => {
          setCurrentActiveSection('homepage2');
          console.log('Entered homepage2 section');
        },
        onUpdate: (self) => {
          const progress = self.progress;
          let targetFeature = 0;

          // Determine target feature based on progress with precise thresholds
          if (progress >= 0.75) {
            targetFeature = 3;
          } else if (progress >= 0.5) {
            targetFeature = 2;
          } else if (progress >= 0.25) {
            targetFeature = 1;
          } else {
            targetFeature = 0;
          }

          // Always update scroll progress indicator regardless of animation state
          setActiveFeatureIndex(targetFeature);

          if (!sectionAnimated.homepage2 && scrollDirection === 'down') {
            // Only transition if we've crossed a threshold
            transitionToFeature(targetFeature);

            // Mark as completed when fully scrolled
            if (progress >= 1) {
              setSectionAnimated(prev => ({ ...prev, homepage2: true }));
            }
          }
        },
        onLeave: () => {
          // Cleanup when leaving the section
          cleanupAnimations();
          isTransitioning = false;
          setCurrentActiveSection(null);
        },
        onEnterBack: () => {
          // Reset state when entering back
          setCurrentActiveSection('homepage2');
          if (sectionAnimated.homepage2) {
            currentActiveFeature = 0;
            isTransitioning = false;
            cleanupAnimations();
            // Reset scroll progress indicator
            setActiveFeatureIndex(0);
          }
        }
      });
    };

    createFeaturesScrollTrigger();

    // Initialize feature content items to hidden state (except first one)
    gsap.set(".homepage__feature-content-item", { opacity: 0, y: 20 });
    gsap.set(".homepage__feature-content-item:first-child", { opacity: 1, y: 0 });

    // Set initial CSS classes for proper state management
    const initialFeatureContents = document.querySelectorAll('.homepage__feature-content-item');
    initialFeatureContents.forEach((content, index) => {
      const element = content as HTMLElement;
      if (index === 0) {
        element.classList.add('active');
      } else {
        element.classList.remove('active');
      }
    });

    // Why Us section now handles its own animations internally
    // No external scroll trigger needed for the vertical carousel

    // Section 3: Market Growth Section with Scroll-Back Optimization
    const createMarketGrowthScrollTrigger = () => {
      ScrollTrigger.create({
        trigger: ".homepage__market-growth-section",
        start: "top top",
        end: sectionAnimated.marketGrowth ? "bottom top" : "+=100%",
        pin: !sectionAnimated.marketGrowth && scrollDirection === 'down',
        scrub: false,
        onEnter: () => {
          if (!sectionAnimated.marketGrowth && scrollDirection === 'down') {
            // Market growth section animations sequence (only on first visit scrolling down)
            const tl = gsap.timeline({
              onComplete: () => {
                setSectionAnimated(prev => ({ ...prev, marketGrowth: true }));
                ScrollTrigger.refresh();
              }
            });

            // The MarketGrowth component handles its own internal animations
            // This scroll trigger just manages the section pinning and completion state
            tl.to({}, { duration: 2 }); // Placeholder duration for pinning
          }
        }
      });
    };

    createMarketGrowthScrollTrigger();

    // Initialize Testimonials section elements to hidden state with responsive offsets
    gsap.set([
      ".testimonialimage",
      ".homepage__testimonials-title",
      ".homepage__testimonials-person-info",
      ".homepage__testimonials-quote-box",
      ".homepage__testimonials-scroll-indicator"
    ], {
      opacity: 0
    });

    const testimonialsOffsets = getResponsiveOffset();
    gsap.set(".testimonialimage", { scale: 0.8 });
    gsap.set(".homepage__testimonials-person-info", { y: testimonialsOffsets.small });
    gsap.set(".homepage__testimonials-quote-box", { y: testimonialsOffsets.small });
    gsap.set(".homepage__testimonials-title", { y: testimonialsOffsets.small * 1.5 });
    gsap.set(".homepage__testimonials-scroll-indicator", { scale: 0.8, y: testimonialsOffsets.small });

    // Section 4: Testimonials Section with Scroll-Back Optimization
    const createTestimonialsScrollTrigger = () => {
      ScrollTrigger.create({
        trigger: ".homepage4",
        start: "top top",
        end: sectionAnimated.homepage4 ? "bottom top" : "+=100%",
        pin: !sectionAnimated.homepage4 && scrollDirection === 'down',
        scrub: false,
        onEnter: () => {
          if (!sectionAnimated.homepage4 && scrollDirection === 'down') {
            // Testimonials section animations sequence (only on first visit scrolling down)
            const tl = gsap.timeline({
              onComplete: () => {
                setSectionAnimated(prev => ({ ...prev, homepage4: true }));
                ScrollTrigger.refresh();
              }
            });

            tl.to(".homepage__testimonials-title", {
              duration: 0.4,
              opacity: 1,
              y: 0,
              ease: "power2.out"
            })
            .to(".testimonialimage", {
              duration: 0.8,
              opacity: 1,
              scale: 1,
              ease: "power2.out"
            }, "-=0.3")
            .to(".homepage__testimonials-person-info", {
              duration: 0.4,
              opacity: 1,
              y: 0,
              ease: "power2.out"
            }, "-=0.6")
            .to(".homepage__testimonials-quote-box", {
              duration: 0.4,
              opacity: 1,
              y: 0,
              ease: "power2.out"
            }, "-=0.4")
            .to(".homepage__testimonials-scroll-indicator", {
              duration: 0.3,
              opacity: 1,
              scale: 1,
              y: 0,
              ease: "back.out(1.7)"
            }, "-=0.2");
          }
        }
      });
    };

    createTestimonialsScrollTrigger();

    // Initialize Team Testimonial section elements to hidden state with responsive offsets
    gsap.set([
      ".homepage__team-testimonial-background",
      ".homepage__team-testimonial-title",
      ".homepage__team-testimonial-quote",
      ".homepage__team-testimonial-author",
      ".homepage__team-testimonial-star"
    ], {
      opacity: 0
    });

    const teamTestimonialOffsets = getResponsiveOffset();
    gsap.set(".homepage__team-testimonial-background", { scale: 1.1 });
    gsap.set(".homepage__team-testimonial-title", { x: -teamTestimonialOffsets.medium });
    gsap.set(".homepage__team-testimonial-quote", { y: teamTestimonialOffsets.small * 2.5 });
    gsap.set(".homepage__team-testimonial-author", { x: -teamTestimonialOffsets.small * 2.5 });
    gsap.set(".homepage__team-testimonial-star", { scale: 0, rotation: 180 });

    // Section 5: Team Testimonial Section with Scroll-Back Optimization
    const createTeamTestimonialScrollTrigger = () => {
      ScrollTrigger.create({
        trigger: ".homepage__team-testimonial-section",
        start: "top top",
        end: sectionAnimated.teamTestimonial ? "bottom top" : "+=100%",
        pin: !sectionAnimated.teamTestimonial && scrollDirection === 'down',
        scrub: false,
        onEnter: () => {
          if (!sectionAnimated.teamTestimonial && scrollDirection === 'down') {
            // Team testimonial section animations sequence (only on first visit scrolling down)
            const tl = gsap.timeline({
              onComplete: () => {
                setSectionAnimated(prev => ({ ...prev, teamTestimonial: true }));
                ScrollTrigger.refresh();
              }
            });

            tl.to(".homepage__team-testimonial-background", {
              duration: 1.5,
              opacity: 1,
              scale: 1,
              ease: "power2.out"
            })
            .to(".homepage__team-testimonial-title", {
              duration: 1,
              opacity: 1,
              x: 0,
              ease: "power2.out"
            }, "-=1")
            .to(".homepage__team-testimonial-quote", {
              duration: 1.2,
              opacity: 1,
              y: 0,
              ease: "power2.out"
            }, "-=0.8")
            .to(".homepage__team-testimonial-author", {
              duration: 0.8,
              opacity: 1,
              x: 0,
              ease: "power2.out"
            }, "-=0.6")
            .to(".homepage__team-testimonial-star", {
              duration: 0.6,
              opacity: 1,
              scale: 1,
              rotation: 0,
              stagger: 0.1,
              ease: "back.out(1.7)"
            }, "-=0.4");
          }
        }
      });
    };

    createTeamTestimonialScrollTrigger();

    // Initialize Founding Member Perks section elements to hidden state
    gsap.set(".founding-member-perks__content-item", { opacity: 0, y: 50 });
    gsap.set(".founding-member-perks__title", { opacity: 0, y: 30 });
    // Set first perk to visible state
    gsap.set(".founding-member-perks__content-item:first-child", { opacity: 1, y: 0 });

    // Section 6: Founding Member Perks Section with Scroll-Back Optimization
    const createFoundingMemberPerksScrollTrigger = () => {
      let currentActivePerk = 0;
      let isTransitioning = false;
      let activeTimeline: gsap.core.Timeline | null = null;

      // Function to cleanup active animations
      const cleanupAnimations = () => {
        if (activeTimeline) {
          activeTimeline.kill();
          activeTimeline = null;
        }
      };

      // Function to transition to a specific perk
      const transitionToPerk = (targetPerk: number) => {
        if (isTransitioning || currentActivePerk === targetPerk) return;

        isTransitioning = true;
        cleanupAnimations();

        const perkContents = document.querySelectorAll('.founding-member-perks__content-item');

        activeTimeline = gsap.timeline({
          onComplete: () => {
            currentActivePerk = targetPerk;
            isTransitioning = false;
          }
        });

        // Fade out current perk
        if (perkContents[currentActivePerk]) {
          activeTimeline.to(perkContents[currentActivePerk], {
            opacity: 0,
            y: -30,
            duration: 0.3,
            ease: "power2.in"
          });
        }

        // Fade in new perk
        activeTimeline.to(perkContents[targetPerk], {
          opacity: 1,
          y: 0,
          duration: 0.4,
          ease: "power2.out"
        }, "-=0.1");
      };

      ScrollTrigger.create({
        trigger: ".founding-member-perks-section",
        start: "top top",
        end: sectionAnimated.foundingMemberPerks ? "bottom top" : "+=300%",
        pin: !sectionAnimated.foundingMemberPerks && scrollDirection === 'down',
        scrub: 1,
        onEnter: () => {
          // Set active section
          setCurrentActiveSection('foundingMemberPerks');
          console.log('Entered foundingMemberPerks section');
          // Animate title on first enter
          if (!sectionAnimated.foundingMemberPerks && scrollDirection === 'down') {
            gsap.to(".founding-member-perks__title", {
              duration: 1,
              opacity: 1,
              y: 0,
              ease: "power2.out"
            });
          }
        },
        onUpdate: (self) => {
          const progress = self.progress;
          let targetPerk = 0;

          // Determine target perk based on progress with precise thresholds
          if (progress >= 0.75) {
            targetPerk = 3;
          } else if (progress >= 0.5) {
            targetPerk = 2;
          } else if (progress >= 0.25) {
            targetPerk = 1;
          } else {
            targetPerk = 0;
          }

          // Only update scroll progress indicator if it actually changed
          setActiveFoundingPerkIndex(prevIndex => {
            if (prevIndex !== targetPerk) {
              return targetPerk;
            }
            return prevIndex;
          });

          if (!sectionAnimated.foundingMemberPerks && scrollDirection === 'down') {
            // Only transition if we've crossed a threshold
            transitionToPerk(targetPerk);

            // Mark as completed when fully scrolled
            if (progress >= 1) {
              setSectionAnimated(prev => ({ ...prev, foundingMemberPerks: true }));
            }
          }
        },
        onLeave: () => {
          // Cleanup when leaving the section
          cleanupAnimations();
          isTransitioning = false;
          setCurrentActiveSection(null);
        },
        onEnterBack: () => {
          // Reset state when entering back
          setCurrentActiveSection('foundingMemberPerks');
          if (sectionAnimated.foundingMemberPerks) {
            currentActivePerk = 0;
            isTransitioning = false;
            cleanupAnimations();
            // Reset scroll progress indicator
            setActiveFoundingPerkIndex(0);
            // Reset title and first perk visibility for smooth scroll-back
            gsap.set(".founding-member-perks__title", { opacity: 1, y: 0 });
            gsap.set(".founding-member-perks__content-item", { opacity: 0, y: 50 });
            gsap.set(".founding-member-perks__content-item:first-child", { opacity: 1, y: 0 });
          }
        }
      });
    };

    createFoundingMemberPerksScrollTrigger();

    // Initialize CTA section elements to hidden state with responsive offsets
    gsap.set([
      ".homepage__cta-title",
      ".homepage__cta-description",
      ".homepage__cta-button",
      ".homepage__cta-image"
    ], {
      opacity: 0
    });

    const ctaOffsets = getResponsiveOffset();
    gsap.set(".homepage__cta-title", { y: ctaOffsets.medium });
    gsap.set(".homepage__cta-description", { y: ctaOffsets.small * 2.5 });
    gsap.set(".homepage__cta-button", { scale: 0.8 });
    gsap.set(".homepage__cta-image", { x: ctaOffsets.large * 0.25, scale: 1.1 });

    // Section 6: CTA Section with Scroll-Back Optimization
    const createCTAScrollTrigger = () => {
      ScrollTrigger.create({
        trigger: ".homepage__cta-section",
        start: "top top",
        end: sectionAnimated.cta ? "bottom top" : "+=100%",
        
        scrub: false,
        onEnter: () => {
          if (!sectionAnimated.cta && scrollDirection === 'down') {
            // CTA section animations sequence (only on first visit scrolling down)
            const tl = gsap.timeline({
              onComplete: () => {
                setSectionAnimated(prev => ({ ...prev, cta: true }));
                ScrollTrigger.refresh();
              }
            });

            tl.to(".homepage__cta-title", {
              duration: 1.2,
              opacity: 1,
              y: 0,
              ease: "power2.out"
            })
            .to(".homepage__cta-description", {
              duration: 1,
              opacity: 1,
              y: 0,
              ease: "power2.out"
            }, "-=0.8")
            .to(".homepage__cta-button", {
              duration: 0.8,
              opacity: 1,
              scale: 1,
              ease: "back.out(1.7)"
            }, "-=0.6")
            .to(".homepage__cta-image", {
              duration: 1.5,
              opacity: 1,
              x: 0,
              scale: 1,
              ease: "power2.out"
            }, "-=1");
          }
        }
      });
    };

    createCTAScrollTrigger();

    // Footer animations (non-pinned, traditional scroll trigger)
  });

  // Hero quotes array for dynamic rotation
  const heroQuotes = useMemo(() => [
    "LawVriksh is the first AI-powered platform that helps legal experts build a respected online voice, create high-impact content, and unlock new monetization opportunities.",
    "You are one of India's 2 million legal minds. Your insights shape justice. But the digital world wasn't built for you.",
    "Join the exclusive beta for India's first platform designed to turn legal professionals into digital entrepreneurs.",
  ], []);

  // Hero quote rotation effect using pure GSAP
  useEffect(() => {
    let quoteTimeline: gsap.core.Timeline | null = null;

    const startQuoteRotation = () => {
      const quoteElement = document.querySelector('.homepage__main-quote');
      if (!quoteElement) return;

      // Set initial state
      gsap.set(quoteElement, { opacity: 1, y: 0, scale: 1 });

      // Create infinite timeline for quote rotation
      quoteTimeline = gsap.timeline({
        repeat: -1,
        repeatDelay: 0
      });

      // Create a single rotation cycle that repeats
      quoteTimeline
        // Hold current quote for 4 seconds
        .to(quoteElement, { duration: 4 })
        // Fade out with smooth animation
        .to(quoteElement, {
          opacity: 0,
          y: -15,
          scale: 0.98,
          duration: 0.4,
          ease: "power2.in"
        })
        // Update to next quote
        .call(() => {
          setCurrentQuoteIndex((prevIndex) => {
            const nextIndex = (prevIndex + 1) % heroQuotes.length;
            quoteElement.textContent = `"${heroQuotes[nextIndex]}"`;
            return nextIndex;
          });
        })
        // Fade in new quote with smooth animation
        .to(quoteElement, {
          opacity: 1,
          y: 0,
          scale: 1,
          duration: 0.6,
          ease: "power2.out"
        });
    };

    // Start the rotation after a short delay to ensure DOM is ready
    const timeoutId = setTimeout(startQuoteRotation, 1000);

    // Cleanup function
    return () => {
      clearTimeout(timeoutId);
      if (quoteTimeline) {
        quoteTimeline.kill();
        quoteTimeline = null;
      }
    };
  }, [heroQuotes]);

  // Smooth full-page scroll functionality

  const features = [
    {
      icon: "https://api.builder.io/api/v1/image/assets/TEMP/aa858a2f8ed0a134930f72e7fef50e364573ebfc?width=118",
      title: "Features",
      description: "Unlock exclusive platform benefits. Hover for a closer look.",
      iconClass: "homepage__feature-icon",
    },
    {
      icon: "https://api.builder.io/api/v1/image/assets/TEMP/9badbe856312fc48be0805e349db264b09d2846c?width=118",
      title: "Why You should Join us",
      description: "Discover your path to success. Hover to see the advantages.",
      iconClass: "homepage__feature-icon homepage__feature-icon--medium",
      contentClass: "homepage__feature-content homepage__feature-content--wide",
    },
    {
      icon: "https://api.builder.io/api/v1/image/assets/TEMP/189e56502619bfcd3df1b9c9dfa220747ca30a92?width=118",
      title: "Testimonials",
      description: "Hear success stories from peers. Hover to see what they're saying.",
      iconClass: "homepage__feature-icon homepage__feature-icon--small",
    },
  ];



  // Feature content for the animated sections
  const featureContents = [
    {
      title: "The 60% Solution: Your AI Co-Pilot",
      bullets: [
        "You spend up to 60% of your time on research and content creation.",
        "Our legal-specific AI, trained on Indian compliance and frameworks, automates your drafting process",
        "It's more than a tool; it's an integrated engine for writing, research, and SEO optimization that frees you to focus on what truly matters—your expertise."
      ]
    },
    
    {
      title: "Your Digital Gavel: The Automated Portfolio",
      bullets: [
        "While 73% of legal professionals use digital tools, they lack a single, comprehensive system to showcase their expertise.",
        "Our Automated Portfolio Builder creates a credible, SEO-optimized digital presence for you.",
        "Combined with our Professional Verification System, you don't just get found—you get trusted."
      ]
    },
    {
      title: "An All-India Reach: The Multilingual Engine",
      bullets: [
        "Your insights are too valuable to be confined to one language.",
        "Our platform's multi-language support allows you to create and disseminate your work across India's diverse linguistic landscape.",
        "Reach a wider audience, connect with more clients, and build a truly national reputation."
      ]
    },
    {
      title: "Beyond the Billable Hour: The Monetization Hub",
      bullets: [
        "The $191.6 billion creator economy has largely excluded legal professionals. We're correcting this.",
        "Our platform provides the first direct path from legal expertise to sustainable revenue.",
        "With a credit-based economy and tools for premium subscriptions, you can finally build income streams beyond the traditional billable hour."
      ]
    },
  ];

  // State for scroll progress indicator
  const [activeFeatureIndex, setActiveFeatureIndex] = useState(0);
  const [activeFoundingPerkIndex, setActiveFoundingPerkIndex] = useState(0);
  const [currentActiveSection, setCurrentActiveSection] = useState<string | null>(null);

  // Founding Member Perks data
  const foundingMemberPerks = [
    {
      title: "Founding Member Badge",
      description: "Claim the permanent 'Founding Member' badge, a mark of distinction no one else can ever earn. Solidify your legacy as a pioneer in India's new legal economy."
    },
    {
      title: "Early Access & Homepage Feature",
      description: "Get every groundbreaking feature before the public and be featured on our homepage. This is your unignorable advantage to build instant authority and dominate the digital space."
    },
    {
      title: "Premium Access & Exclusive Events",
      description: "Enjoy 3 months of unrestricted premium access to build your digital brand, on us. Plus, get an exclusive seat at closed-door strategy events with legal industry titans."
    },
    {
      title: "Lifetime Status & Inner Circle",
      description: "Become a Founding Member for a lifetime of status and a perpetual head start. Secure your place in the inner circle before the door closes forever."
    }
  ];

  // CTA Section Content Data
  const ctaContent = {
    first: [
      "Soon, a verified profile on this platform will be the new standard for digital credibility in law. Get yours first.",
      "Why limit your audience? Beta users will be the first to establish a pan-India presence."
    ],
    second: [
      "The first wave of India's legal creators is about to launch. Will you be on the inside, or will you be reading their work?",
      "Your peers are about to start producing high-value content in minutes, not days. Don't get left behind."
    ]
  };


  // Render mobile version if on mobile device
  if (isMobile) {
    return <HomepageMobile onJoinWaitlist={handleJoinWaitlist} />;
  }

  return (
    <div>
      <div id="home" className="homepage">
        <Navbar onJoinWaitlist={handleJoinWaitlist} />
        <div className="homepage__hero5">
        <div className="homepage__main-wrapper">
          <div className="homepage__hero-title">
            <span className="homepage__hero-word">Be</span>{" "}
            <span className="homepage__hero-word">a</span>{" "}
            <span className="homepage__hero-word">legal</span> <br />
            <span className="homepage__hero-word">entrepreneur</span>
          </div>

          <div className="homepage__features-section">
            {features.map((feature, index) => (
              <div
                key={index}
                className="homepage__feature-item"
                onMouseEnter={() => handleFeatureHover(index)}
                onMouseLeave={handleFeatureLeave}
              >
                <img src={feature.icon} alt="" className={feature.iconClass} />
                <div
                  className={
                    feature.contentClass || "homepage__feature-content"
                  }
                >
                  <div className="homepage__feature-title">{feature.title}</div>
                  <div className="homepage__feature-description">
                    {feature.description}
                  </div>
                </div>
              </div>
            ))}
          </div>

        </div>
        </div >
        <div className="homepage__hero">
          <div className="homepage__main-section">
            <div className="homepage__main-title">
              Creator platform for modern
              <br />
              --- legal professionals
            </div>

            <div className="homepage__main-content">
              <div className="homepage__main-quote">
                &ldquo;{heroQuotes[currentQuoteIndex]}&rdquo;
              </div>
              <Button size="large" onClick={handleJoinWaitlist} showFomoDialog={true}>Join Waitlist</Button>
            </div>
          </div>
        </div>

        {/* Interactive Dialog - Completely Redesigned */}
        {hoveredFeature !== null && (
          <div
            className="homepage__interactive-dialog"
            onMouseEnter={handleDialogEnter}
            onMouseLeave={handleDialogLeave}
          >
            <div className="dialog__container">
              {/* Header Section */}
              <div className="dialog__header">
                <div className="dialog__header-accent"></div>
                <div className="dialog__header-content">
                  <div className="dialog__header-text">
                    <h3 className="dialog__title">
                      {dialogContent[hoveredFeature as keyof typeof dialogContent].title}
                    </h3>
                    <div className="dialog__header-subtitle">
                      Explore the details below
                    </div>
                  </div>
                  <div className="dialog__header-logo">
                    <img src="/logo2.png" alt="LawVriksh Logo" className="dialog__logo-image" />
                  </div>
                </div>
              </div>

              {/* Content List - Single Column */}
              <div className="dialog__content-list">
                {dialogContent[hoveredFeature as keyof typeof dialogContent].items.map((item, index) => (
                  <div
                    key={index}
                    className={`dialog__content-card ${hoveredFeature === 2 ? 'dialog__content-card--testimonial' : ''}`}
                    onClick={() => handleTestimonialClick(index)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter' || e.key === ' ') {
                        e.preventDefault();
                        handleTestimonialClick(index);
                      }
                    }}
                    role={hoveredFeature === 2 ? "button" : undefined}
                    tabIndex={hoveredFeature === 2 ? 0 : undefined}
                    aria-expanded={hoveredFeature === 2 ? expandedTestimonial === index : undefined}
                  >
                    <div className="dialog__card-header">
                      <div className="dialog__card-number">
                        <span>{index + 1}</span>
                      </div>
                      <div className="dialog__card-title">
                        <div className="dialog__card-name">
                          {item.heading}
                        </div>
                        {hoveredFeature === 2 && 'profession' in item && (
                          <div className="dialog__card-profession">
                            {item.profession}
                          </div>
                        )}
                      </div>
                      {hoveredFeature === 2 && (
                        <div className={`dialog__expand-indicator ${expandedTestimonial === index ? 'dialog__expand-indicator--expanded' : ''}`}>
                          <span>▼</span>
                        </div>
                      )}
                    </div>

                    {/* Regular content for Features and Why You Should Join Us */}
                    {hoveredFeature !== 2 && 'description' in item && (
                      <div className="dialog__card-content">
                        <p className="dialog__card-description">
                          {item.description}
                        </p>
                      </div>
                    )}

                    {/* Expandable testimonial content with multiple testimonials */}
                    {hoveredFeature === 2 && 'testimonials' in item && (
                      <div className={`dialog__testimonial-content ${expandedTestimonial === index ? 'dialog__testimonial-content--expanded' : ''}`}>
                        <div className="dialog__testimonials-container">
                          {item.testimonials.map((testimonial, testimonialIndex) => (
                            <div key={testimonialIndex} className="dialog__single-testimonial">
                              <div className="dialog__testimonial-quote">
                                <span className="dialog__quote-mark">&ldquo;</span>
                                <p className="dialog__quote-text">
                                  {testimonial}
                                </p>
                                <span className="dialog__quote-mark dialog__quote-mark--closing">&rdquo;</span>
                              </div>
                              {testimonialIndex < item.testimonials.length - 1 && (
                                <div className="dialog__testimonial-divider"></div>
                              )}
                            </div>
                          ))}
                        </div>
                        <div className="dialog__testimonial-attribution">
                          — {item.heading}
                        </div>
                      </div>
                    )}

                    <div className="dialog__card-footer">
                      <div className="dialog__card-accent-line"></div>
                    </div>
                  </div>
                ))}
              </div>

              {/* Footer Section */}
              <div className="dialog__footer">
                <div className="dialog__footer-text">
                  Hover to explore • Click feature items for more details
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Decorative Strip Divider */}
      <div className="homepage__divider-strip">
        <div className="homepage__divider-content">
          <div className="homepage__divider-text">
            {dividerTexts[currentDividerTextIndex]}
          </div>
        </div>
        <div className="homepage__divider-pattern">
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
        </div>
      </div>

      <div id="features" className="homepage2">
        {/* Scroll Progress Indicator - Desktop Only */}
        {!isMobile && (
          <ScrollProgressIndicator
            activeIndex={activeFeatureIndex}
            totalSections={4}
            sectionTitles={[
              "AI Co-Pilot",
              "Monetization Hub",
              "Automated Portfolio",
              "Multilingual Engine"
            ]}
            visible={true}
          />
        )}

        {/* Card Container for Image and Content */}
        <div className="homepage__feature-card">
          <div className="homepage__feature-image"></div>

          <div className="homepage__content-engine-content">
            {featureContents.map((feature, index) => (
              <div key={index} className="homepage__feature-content-item">
                <div className="homepage__content-engine-title">
                  <div className="homepage__content-engine-title-text">
                    {feature.title.split(':')[0]}:
                    <br />{feature.title.split(':')[1]}
                  </div>
                </div>
                <div className="homepage__content-engine-description">
                  <div className="homepage__content-engine-description-text">
                    <ul className="homepage__feature-bullets">
                      {feature.bullets.map((bullet, bulletIndex) => (
                        <li key={bulletIndex}>{bullet}</li>
                      ))}
                    </ul>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
      <div className="homepage__divider-strip">
        <div className="homepage__divider-content">
          <div className="homepage__divider-text">
            {dividerTexts[currentDividerTextIndex]}
          </div>
        </div>
        <div className="homepage__divider-pattern">
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
        </div>
      </div>

      <div id="market-growth" className="homepage__market-growth-section">
        <MarketGrowth />
      </div>

      {/* First CTA Section */}
      <CTASection
        contentItems={ctaContent.first}
        onButtonClick={handleJoinWaitlist}
      />

      <div className="homepage__divider-strip">
        <div className="homepage__divider-content">
          <div className="homepage__divider-text">
            {dividerTexts[currentDividerTextIndex]}
          </div>
        </div>
        <div className="homepage__divider-pattern">
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
        </div>
      </div>
      <div id="why-us" className="homepage3">
        <WhyUs />
      </div>
      <div className="homepage__divider-strip">
        <div className="homepage__divider-content">
          <div className="homepage__divider-text">
            {dividerTexts[currentDividerTextIndex]}
          </div>
        </div>
        <div className="homepage__divider-pattern">
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
        </div>
      </div>
      <div id="testimonials" className="homepage4">
        <div className="homepage__testimonials-content">
          <div className="homepage__testimonials-header">
            <div className="homepage__testimonials-title">
              What problems We are targetting?
            </div>
            <div className="homepage__testimonials-quote-mark"></div>
          </div>
          <div className="homepage__testimonials-person-info">
            <div className="homepage__testimonials-person-name">
              {testimonialsData[currentPersonIndex].name}
            </div>
            <div className="homepage__testimonials-person-credentials">
              {testimonialsData[currentPersonIndex].credentials}
            </div>
          </div>
          <div className="homepage__testimonials-quote-box">
            <div className="homepage__testimonials-quote-text">
              {testimonialsData[currentPersonIndex].testimonials[currentTestimonialIndex]}
            </div>
          </div>
        </div>
        <div className="homepage__hero2">
          <div
            className="testimonialimage"
            style={{
              backgroundImage: `url(${testimonialsData[currentPersonIndex].image})`
            }}

          >
            <div className="homepage__testimonials-scroll-indicator">
              <div className="homepage__testimonials-scroll-text">Scroll to see next person</div>
              <div className="homepage__testimonials-scroll-arrow">↓</div>
            </div>
          </div>
          <div className="homepage__subhero"></div>
        </div>
      </div>
      <div className="homepage__divider-strip">
        <div className="homepage__divider-content">
          <div className="homepage__divider-text">
            {dividerTexts[currentDividerTextIndex]}
          </div>
        </div>
        <div className="homepage__divider-pattern">
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
        </div>
      </div>
      

      {/* Founding Member Perks Section */}
      <div id="founding-member-perks" className="founding-member-perks-section">
        <div className="founding-member-perks__container">
          <div className="founding-member-perks__title">
            Founding Member Perks
          </div>

          <div className="founding-member-perks__content">
            {foundingMemberPerks.map((perk, index) => (
              <div
                key={index}
                className="founding-member-perks__content-item"
                style={{ position: 'absolute', width: '100%' }}
              >
                <div className="founding-member-perks__perk-title">
                  {perk.title}
                </div>
                <div className="founding-member-perks__perk-description">
                  {perk.description}
                </div>
              </div>
            ))}
          </div>

          {/* Scroll Progress Indicator for Founding Member Perks - Desktop Only */}
          {!isMobile && (
            <ScrollProgressIndicator
              activeIndex={activeFoundingPerkIndex}
              totalSections={4}
              sectionTitles={[
                "Founding Member Badge",
                "Early Access & Homepage Feature",
                "Premium Access & Exclusive Events",
                "Lifetime Status & Inner Circle"
              ]}
              visible={currentActiveSection === 'foundingMemberPerks'}
            />
          )}
        </div>
      </div>

      {/* Second CTA Section */}
      <CTASection
        contentItems={ctaContent.second}
        onButtonClick={handleJoinWaitlist}
      />

      <div className="homepage__divider-strip">
        <div className="homepage__divider-content">
          <div className="homepage__divider-text">
            {dividerTexts[currentDividerTextIndex]}
          </div>
        </div>
        <div className="homepage__divider-pattern">
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
          <div className="homepage__divider-dot"></div>
        </div>
      </div>
      

      <Footer />

      <WaitlistPopup
        isOpen={isWaitlistPopupOpen}
        onClose={handleCloseWaitlistPopup}
      />
    </div>
  );
}
