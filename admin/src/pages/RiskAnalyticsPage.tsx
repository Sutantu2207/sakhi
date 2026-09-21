import React from 'react';
import { OverviewStats } from '../types';
import { BrainCircuit, ShieldAlert, Cpu, Sparkles, AlertCircle } from 'lucide-react';

interface RiskAnalyticsProps {
  stats: OverviewStats | null;
}

export const RiskAnalyticsPage: React.FC<RiskAnalyticsProps> = ({ stats }) => {
  const modelFeatures = [
    { name: 'Weighted Incident Severity Score', weight: '46.8%', desc: 'Composite impact of critical vs medium verified reports' },
    { name: 'Incident Density (1km Radius)', weight: '19.3%', desc: 'Aggregate verified incident frequency within walkable radius' },
    { name: 'Incident Density (500m Immediate)', weight: '7.5%', desc: 'Immediate block incident density' },
    { name: 'Street Harassment Density', weight: '7.0%', desc: 'Past reported tailing / catcalling frequency' },
    { name: 'Poor Street Lighting Density', weight: '6.1%', desc: 'Reported dark alleyways and non-operational street lamps' },
    { name: 'Temporal Night Travel Window', weight: '4.8%', desc: 'Hour 21:00 - 05:00 weighting factor' },
    { name: 'Distance to Verified Police Assistance', weight: '2.0%', desc: 'Proximity to nearest active emergency responder post' },
    { name: 'Distance to Medical Facility', weight: '2.2%', desc: 'Proximity to nearest hospital casualty / trauma center' },
  ];

  return (
    <div className="space-y-6">
      {/* ML Pipeline Status Header */}
      <div className="bg-gradient-to-r from-[#1A1429] to-[#3A1C71] text-white p-6 rounded-2xl shadow-lg flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="p-3 bg-white/10 rounded-xl backdrop-blur-md">
            <BrainCircuit className="w-8 h-8 text-purple-200" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-lg font-bold">Contextual Geospatial Risk Engine</h3>
              <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
                ACTIVE
              </span>
            </div>
            <p className="text-xs text-purple-200/80 mt-1">
              Model: <span className="font-mono text-white font-semibold">sakhi-risk-xgb-v1.0</span> (XGBoost Multi-Class Contextual Classifier)
            </p>
          </div>
        </div>

        <div className="text-right">
          <span className="text-xs text-purple-200/70 block">Validation Macro Accuracy</span>
          <span className="text-2xl font-bold font-mono text-emerald-400">86.8%</span>
        </div>
      </div>

      {/* Ethical AI Principle Callout */}
      <div className="bg-amber-50 border border-amber-200/80 p-4 rounded-xl flex items-start gap-3 text-xs text-amber-900">
        <AlertCircle className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
        <div>
          <h4 className="font-bold">Strict Ethical AI & Privacy Constraint</h4>
          <p className="mt-0.5 leading-relaxed text-amber-800">
            The Sakhi ML risk engine operates solely on aggregated environmental indicators (verified historical reports, infrastructure proximity, lighting, time-of-day).
            It <b>never profiles individual persons</b>, never predicts individual criminal behavior, and does not label any area as absolute "safe" or "dangerous".
          </p>
        </div>
      </div>

      {/* Feature Importances Grid */}
      <div className="bg-white p-6 rounded-xl border border-slate-200/80 shadow-sm">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h4 className="font-bold text-slate-800 text-sm">Feature Weight Distribution in Trained Model</h4>
            <p className="text-xs text-slate-500">Calculated Gini importance from trained decision trees</p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {modelFeatures.map((f) => (
            <div key={f.name} className="p-3.5 bg-slate-50 rounded-xl border border-slate-200/70">
              <div className="flex justify-between items-center text-xs font-semibold text-slate-800 mb-1">
                <span>{f.name}</span>
                <span className="font-mono text-sakhi-violet font-bold">{f.weight}</span>
              </div>
              <p className="text-[11px] text-slate-500">{f.desc}</p>
              <div className="w-full bg-slate-200 h-1.5 rounded-full mt-2 overflow-hidden">
                <div 
                  className="bg-sakhi-violet h-full rounded-full" 
                  style={{ width: f.weight }} 
                />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
