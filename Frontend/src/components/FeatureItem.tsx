interface FeatureItemProps {
  icon: string;
  title: string;
  description: string;
}

export default function FeatureItem({
  icon,
  title,
  description,
}: FeatureItemProps) {
  return (
    <div className="homepage__feature-item-container">
      <div className="homepage__feature-item-header">
        <div className="homepage__feature-item-icon">
          <div
            dangerouslySetInnerHTML={{
              __html: icon,
            }}
          />
        </div>
        <div className="homepage__feature-item-title">{title}</div>
      </div>
      <div className="homepage__feature-item-description">{description}</div>
    </div>
  );
}
