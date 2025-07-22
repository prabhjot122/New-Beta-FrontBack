import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import gsap from 'gsap';
import Button from './Button';
import { feedbackService, FeedbackSubmission } from '../services/feedbackService';
import './Feedback.css';

interface FeedbackFormData {
  // User information
  email: string;
  name: string;

  // Multiple choice questions
  biggestHurdle: string;
  biggestHurdleOther: string;
  primaryMotivation: string;
  timeConsumingPart: string;
  professionalFear: string;

  // Short answer questions
  monetizationConsiderations: string;
  professionalLegacy: string;
  platformImpact: string;
}

interface FormErrors {
  [key: string]: string;
}

const Feedback: React.FC = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState<FeedbackFormData>({
    email: '',
    name: '',
    biggestHurdle: '',
    biggestHurdleOther: '',
    primaryMotivation: '',
    timeConsumingPart: '',
    professionalFear: '',
    monetizationConsiderations: '',
    professionalLegacy: '',
    platformImpact: ''
  });
  
  const [errors, setErrors] = useState<FormErrors>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);

  useEffect(() => {
    // GSAP animation for page load
    const tl = gsap.timeline();
    
    tl.fromTo('.feedback__container', 
      { opacity: 0, y: 50 },
      { opacity: 1, y: 0, duration: 0.8, ease: "power2.out" }
    )
    .fromTo('.feedback__form-section',
      { opacity: 0, y: 30 },
      { opacity: 1, y: 0, duration: 0.6, stagger: 0.1, ease: "power2.out" },
      "-=0.4"
    );
  }, []);

  const validateForm = (): boolean => {
    const newErrors: FormErrors = {};

    // Validate user information
    if (!formData.email.trim()) {
      newErrors.email = 'Please enter your email address';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = 'Please enter a valid email address';
    }

    if (!formData.name.trim()) {
      newErrors.name = 'Please enter your name';
    }

    // Validate mandatory multiple choice questions (Questions 1 and 4)
    if (!formData.biggestHurdle) {
      newErrors.biggestHurdle = 'Please select your biggest hurdle';
    }
    if (formData.biggestHurdle === 'E' && !formData.biggestHurdleOther.trim()) {
      newErrors.biggestHurdleOther = 'Please specify your answer';
    }

    if (!formData.professionalFear) {
      newErrors.professionalFear = 'Please select your biggest professional fear';
    }

    // Validate short answer questions with minimum length requirement
    const validateShortAnswer = (text: string, fieldName: string, displayName: string, isRequired: boolean = false) => {
      if (isRequired && !text.trim()) {
        newErrors[fieldName] = `Please provide your answer for ${displayName}`;
        return;
      }
      if (text.trim() && text.trim().length < 10) {
        newErrors[fieldName] = 'Please enter at least 10 characters';
        return;
      }
    };

    // Question 5 (Platform Impact) is mandatory
    validateShortAnswer(formData.platformImpact, 'platformImpact', 'platform impact', true);

    // Questions 3 and 4 (Monetization and Professional Legacy) are optional
    validateShortAnswer(formData.monetizationConsiderations, 'monetizationConsiderations', 'monetization considerations', false);
    validateShortAnswer(formData.professionalLegacy, 'professionalLegacy', 'professional legacy', false);

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleInputChange = (field: keyof FeedbackFormData, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) {
      // Scroll to first error
      const firstErrorField = Object.keys(errors)[0];
      const errorElement = document.querySelector(`[data-field="${firstErrorField}"]`);
      if (errorElement) {
        errorElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }
      return;
    }

    setIsSubmitting(true);

    try {
      const submissionData: FeedbackSubmission = {
        email: formData.email,
        name: formData.name,
        biggest_hurdle: formData.biggestHurdle,
        biggest_hurdle_other: formData.biggestHurdle === 'E' ? formData.biggestHurdleOther : undefined,
        primary_motivation: formData.primaryMotivation || undefined,
        time_consuming_part: formData.timeConsumingPart || undefined,
        professional_fear: formData.professionalFear,
        monetization_considerations: formData.monetizationConsiderations || undefined,
        professional_legacy: formData.professionalLegacy || undefined,
        platform_impact: formData.platformImpact
      };

      await feedbackService.submitFeedback(submissionData);

      setIsSubmitted(true);

      // Success animation
      gsap.fromTo('.feedback__success-message',
        { opacity: 0, scale: 0.8 },
        { opacity: 1, scale: 1, duration: 0.6, ease: "back.out(1.7)" }
      );

    } catch (error: any) {
      console.error('Failed to submit feedback:', error);
      // Set error message that user can see
      setErrors({ submit: error.message || 'Failed to submit feedback. Please try again.' });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleBackToHome = () => {
    navigate('/');
  };

  if (isSubmitted) {
    return (
      <div className="feedback">
        <div className="feedback__container">
          <div className="feedback__success-message">
            <div className="feedback__success-card">
              <h1 className="feedback__success-title">Thank You!</h1>
              <p className="feedback__success-description">
                Your feedback has been successfully submitted. Your insights are invaluable 
                in helping us build a platform that truly serves the needs of legal professionals.
              </p>
              <div className="feedback__success-actions">
                <Button onClick={handleBackToHome}>
                  Back to Home
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="feedback">
      <div className="feedback__container">
        {/* Header */}
        <div className="feedback__header">
          <h1 className="feedback__title">Beta User Feedback Survey</h1>
          <p className="feedback__subtitle">
            Thank you for being a part of our beta program! Your feedback is crucial in helping us 
            build a platform that truly serves the needs of legal professionals. Please answer the 
            following questions to help us understand your challenges and goals related to sharing 
            your expertise online.
          </p>
        </div>

        {/* Form */}
        <form className="feedback__form" onSubmit={handleSubmit}>
          {/* User Information Section */}
          <div className="feedback__form-section">
            <h2 className="feedback__section-title">Contact Information</h2>
            <p className="feedback__section-subtitle">
              Please provide your contact information so we can follow up on your valuable feedback.
            </p>

            {/* Email Field */}
            <div className="feedback__question-group" data-field="email">
              <h3 className="feedback__question-title">Email Address *</h3>
              <input
                type="email"
                value={formData.email}
                onChange={(e) => handleInputChange('email', e.target.value)}
                className="feedback__text-input"
                placeholder="Enter your email address"
                required
              />
              {errors.email && (
                <div className="feedback__error">
                  {errors.email}
                </div>
              )}
            </div>

            {/* Name Field */}
            <div className="feedback__question-group" data-field="name">
              <h3 className="feedback__question-title">Full Name *</h3>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => handleInputChange('name', e.target.value)}
                className="feedback__text-input"
                placeholder="Enter your full name"
                required
              />
              {errors.name && (
                <div className="feedback__error">
                  {errors.name}
                </div>
              )}
            </div>
          </div>

          {/* Objective Questions Section */}
          <div className="feedback__form-section">
            <h2 className="feedback__section-title">Objective Questions</h2>
            <p className="feedback__section-subtitle">
              These questions help us quantify the most common challenges and motivations. Questions marked with * are required.
            </p>

            {/* Question 1 */}
            <div className="feedback__question-group" data-field="biggestHurdle">
              <h3 className="feedback__question-title">
                1. When you consider writing and sharing your legal insights online, what is your single biggest hurdle? *
              </h3>
              <div className="feedback__options">
                {[
                  { value: 'A', text: 'The sheer time commitment required for research and writing.' },
                  { value: 'B', text: 'The difficulty of simplifying complex legal topics for a wider audience.' },
                  { value: 'C', text: 'Uncertainty about how to reach the right audience or build a following.' },
                  { value: 'D', text: 'Concerns about professional ethics, compliance, or potential liability.' },
                  { value: 'E', text: 'Other (please specify):' }
                ].map((option) => (
                  <label key={option.value} className="feedback__option">
                    <input
                      type="radio"
                      name="biggestHurdle"
                      value={option.value}
                      checked={formData.biggestHurdle === option.value}
                      onChange={(e) => handleInputChange('biggestHurdle', e.target.value)}
                      className="feedback__radio"
                    />
                    <span className="feedback__option-text">
                      ({option.value}) {option.text}
                    </span>
                  </label>
                ))}
              </div>

              {formData.biggestHurdle === 'E' && (
                <div className="feedback__other-input">
                  <input
                    type="text"
                    placeholder="Please specify..."
                    value={formData.biggestHurdleOther}
                    onChange={(e) => handleInputChange('biggestHurdleOther', e.target.value)}
                    className="feedback__text-input"
                    data-field="biggestHurdleOther"
                  />
                </div>
              )}

              {(errors.biggestHurdle || errors.biggestHurdleOther) && (
                <div className="feedback__error">
                  {errors.biggestHurdle || errors.biggestHurdleOther}
                </div>
              )}
            </div>

            {/* Question 2 */}
            <div className="feedback__question-group" data-field="primaryMotivation">
              <h3 className="feedback__question-title">
                2. What is your primary motivation for wanting to share your legal expertise online?
              </h3>
              <div className="feedback__options">
                {[
                  { value: 'A', text: 'To build my professional brand and be recognized as a thought leader.' },
                  { value: 'B', text: 'To attract new, high-quality clients for my practice.' },
                  { value: 'C', text: 'To create an additional revenue stream by monetizing my knowledge.' },
                  { value: 'D', text: 'To educate the public or contribute to the legal community.' }
                ].map((option) => (
                  <label key={option.value} className="feedback__option">
                    <input
                      type="radio"
                      name="primaryMotivation"
                      value={option.value}
                      checked={formData.primaryMotivation === option.value}
                      onChange={(e) => handleInputChange('primaryMotivation', e.target.value)}
                      className="feedback__radio"
                    />
                    <span className="feedback__option-text">
                      ({option.value}) {option.text}
                    </span>
                  </label>
                ))}
              </div>

              {errors.primaryMotivation && (
                <div className="feedback__error">
                  {errors.primaryMotivation}
                </div>
              )}
            </div>

            {/* Question 3 */}
            <div className="feedback__question-group" data-field="timeConsumingPart">
              <h3 className="feedback__question-title">
                3. Thinking about the process of creating a detailed legal article, which part typically consumes the most of your time?
              </h3>
              <div className="feedback__options">
                {[
                  { value: 'A', text: 'Initial legal research and fact-checking to ensure accuracy.' },
                  { value: 'B', text: 'The actual drafting and structuring of the argument.' },
                  { value: 'C', text: 'Editing, proofreading, and simplifying the language for non-lawyers.' },
                  { value: 'D', text: 'Formatting, managing citations, and preparing it for a digital platform.' }
                ].map((option) => (
                  <label key={option.value} className="feedback__option">
                    <input
                      type="radio"
                      name="timeConsumingPart"
                      value={option.value}
                      checked={formData.timeConsumingPart === option.value}
                      onChange={(e) => handleInputChange('timeConsumingPart', e.target.value)}
                      className="feedback__radio"
                    />
                    <span className="feedback__option-text">
                      ({option.value}) {option.text}
                    </span>
                  </label>
                ))}
              </div>

              {errors.timeConsumingPart && (
                <div className="feedback__error">
                  {errors.timeConsumingPart}
                </div>
              )}
            </div>

            {/* Question 4 */}
            <div className="feedback__question-group" data-field="professionalFear">
              <h3 className="feedback__question-title">
                4. In today's increasingly digital world, what is your biggest professional fear regarding your online presence? *
              </h3>
              <div className="feedback__options">
                {[
                  { value: 'A', text: 'Losing potential clients to competitors who are more visible online.' },
                  { value: 'B', text: 'My expertise becoming less relevant or discoverable over time.' },
                  { value: 'C', text: 'Being perceived as outdated or out of touch by peers and clients.' },
                  { value: 'D', text: 'I don\'t have a significant fear about this.' }
                ].map((option) => (
                  <label key={option.value} className="feedback__option">
                    <input
                      type="radio"
                      name="professionalFear"
                      value={option.value}
                      checked={formData.professionalFear === option.value}
                      onChange={(e) => handleInputChange('professionalFear', e.target.value)}
                      className="feedback__radio"
                    />
                    <span className="feedback__option-text">
                      ({option.value}) {option.text}
                    </span>
                  </label>
                ))}
              </div>

              {errors.professionalFear && (
                <div className="feedback__error">
                  {errors.professionalFear}
                </div>
              )}
            </div>
          </div>

          {/* Short Answer Questions Section */}
          <div className="feedback__form-section">
            <h2 className="feedback__section-title">Short Answer Questions</h2>
            <p className="feedback__section-subtitle">
              These questions help us understand your personal vision and the deeper context behind your choices.
              Please provide detailed answers.
            </p>

            {/* Short Answer Question 1 */}
            <div className="feedback__question-group" data-field="monetizationConsiderations">
              <h3 className="feedback__question-title">
                3. Regarding monetizing your legal expertise through writing, what are the main considerations
                (practical or ethical) that have stopped you from exploring it more often or at all? (Optional)
              </h3>
              <textarea
                value={formData.monetizationConsiderations}
                onChange={(e) => handleInputChange('monetizationConsiderations', e.target.value)}
                className="feedback__textarea"
                placeholder="Please provide your detailed answer..."
                rows={4}
              />
              {errors.monetizationConsiderations && (
                <div className="feedback__error">
                  {errors.monetizationConsiderations}
                </div>
              )}
            </div>

            {/* Short Answer Question 2 */}
            <div className="feedback__question-group" data-field="professionalLegacy">
              <h3 className="feedback__question-title">
                4. Beyond your day-to-day casework, how do you define "professional legacy"? Describe the unique
                impact you hope to have in your field and what role sharing your knowledge plays in that vision. (Optional)
              </h3>
              <textarea
                value={formData.professionalLegacy}
                onChange={(e) => handleInputChange('professionalLegacy', e.target.value)}
                className="feedback__textarea"
                placeholder="Please provide your detailed answer..."
                rows={4}
              />
              {errors.professionalLegacy && (
                <div className="feedback__error">
                  {errors.professionalLegacy}
                </div>
              )}
            </div>

            {/* Short Answer Question 3 */}
            <div className="feedback__question-group" data-field="platformImpact">
              <h3 className="feedback__question-title">
                5. Imagine a platform made it truly effortless to capture and share your insights with the right
                audience. Describe how that would change what you believe is possible for your career growth and
                influence in the next 5 years. *
              </h3>
              <textarea
                value={formData.platformImpact}
                onChange={(e) => handleInputChange('platformImpact', e.target.value)}
                className="feedback__textarea"
                placeholder="Please provide your detailed answer..."
                rows={4}
              />
              {errors.platformImpact && (
                <div className="feedback__error">
                  {errors.platformImpact}
                </div>
              )}
            </div>
          </div>

          {/* Submit Section */}
          <div className="feedback__submit-section">
            {errors.submit && (
              <div className="feedback__error feedback__submit-error">
                {errors.submit}
              </div>
            )}
            <Button
              type="submit"
              disabled={isSubmitting}
              size="large"
            >
              {isSubmitting ? 'Submitting...' : 'Submit Feedback'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default Feedback;
