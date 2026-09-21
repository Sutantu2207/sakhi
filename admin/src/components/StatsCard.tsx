import React from 'react';
import { LucideIcon } from 'lucide-react';

interface StatsCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: LucideIcon;
  colorClass: string;
  badge?: string;
  badgeType?: 'neutral' | 'emergency' | 'warning' | 'success';
}

export const StatsCard: React.FC<StatsCardProps> = ({
  title,
  value,
  subtitle,
  icon: Icon,
  colorClass,
  badge,
  badgeType = 'neutral'
}) => {
  const badgeStyles = {
    neutral: 'bg-slate-100 text-slate-600',
    emergency: 'bg-red-50 text-red-600 border border-red-200 animate-pulse',
    warning: 'bg-amber-50 text-amber-700 border border-amber-200',
    success: 'bg-emerald-50 text-emerald-700 border border-emerald-200',
  };

  return (
    <div className="bg-white rounded-xl p-5 border border-slate-200/80 shadow-sm hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-slate-500 mb-1">{title}</p>
          <h3 className="text-2xl font-bold text-slate-800 tracking-tight">{value}</h3>
        </div>
        <div className={`p-3 rounded-xl ${colorClass}`}>
          <Icon className="w-5 h-5" />
        </div>
      </div>

      {(subtitle || badge) && (
        <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
          {subtitle && <span className="text-slate-500 font-medium">{subtitle}</span>}
          {badge && (
            <span className={`px-2 py-0.5 rounded-full font-semibold ${badgeStyles[badgeType]}`}>
              {badge}
            </span>
          )}
        </div>
      )}
    </div>
  );
};
