import React from 'react';
import { 
  Navigation, 
  AlertOctagon, 
  FileText, 
  CheckCircle2, 
  Users, 
  ShieldCheck,
  TrendingUp,
  AlertCircle
} from 'lucide-react';
import { OverviewStats, Incident, SOSEvent } from '../types';
import { StatsCard } from '../components/StatsCard';
import { IncidentMap } from '../components/IncidentMap';

interface OverviewProps {
  stats: OverviewStats | null;
  incidents: Incident[];
  activeSosEvents: SOSEvent[];
  onNavigateToModeration: () => void;
  onNavigateToSOS: () => void;
}

export const Overview: React.FC<OverviewProps> = ({
  stats,
  incidents,
  activeSosEvents,
  onNavigateToModeration,
  onNavigateToSOS
}) => {
  if (!stats) {
    return (
      <div className="flex items-center justify-center h-64 text-slate-500 text-sm">
        Loading operational metrics...
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Critical Active SOS Banner if any */}
      {activeSosEvents.length > 0 && (
        <div className="bg-gradient-to-r from-red-600 to-rose-700 text-white rounded-xl p-4 shadow-lg flex items-center justify-between animate-pulse">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-white/20 rounded-lg">
              <AlertOctagon className="w-6 h-6 text-white" />
            </div>
            <div>
              <h4 className="font-bold text-sm">CRITICAL: {activeSosEvents.length} Active SOS Alert(s) Triggered</h4>
              <p className="text-xs text-red-100">Immediate response required. Dispatches and victim contacts available in Command Center.</p>
            </div>
          </div>
          <button
            onClick={onNavigateToSOS}
            className="px-4 py-2 bg-white text-red-700 font-bold text-xs rounded-lg shadow hover:bg-red-50 transition-colors"
          >
            Open SOS Command Center
          </button>
        </div>
      )}

      {/* Top Metric Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        <StatsCard
          title="Active Journeys"
          value={stats.active_journeys}
          subtitle="Real-time tracked travelers"
          icon={Navigation}
          colorClass="bg-purple-100 text-sakhi-violet"
          badge={stats.active_journeys > 0 ? "LIVE" : "0 Active"}
          badgeType={stats.active_journeys > 0 ? "success" : "neutral"}
        />
        <StatsCard
          title="Active SOS Events"
          value={stats.active_sos}
          subtitle="Emergency alerts pending"
          icon={AlertOctagon}
          colorClass={stats.active_sos > 0 ? "bg-red-100 text-sakhi-emergency" : "bg-slate-100 text-slate-600"}
          badge={stats.active_sos > 0 ? "CRITICAL ALERT" : "Normal"}
          badgeType={stats.active_sos > 0 ? "emergency" : "success"}
        />
        <StatsCard
          title="Incidents Reported Today"
          value={stats.incidents_today}
          subtitle={`${stats.pending_moderation} pending review`}
          icon={FileText}
          colorClass="bg-amber-100 text-sakhi-amber"
          badge={stats.pending_moderation > 0 ? "Needs Review" : "Up to date"}
          badgeType={stats.pending_moderation > 0 ? "warning" : "neutral"}
        />
        <StatsCard
          title="Resolved Incidents"
          value={stats.resolved_incidents}
          subtitle={`Out of ${stats.total_incidents} total recorded`}
          icon={CheckCircle2}
          colorClass="bg-emerald-100 text-sakhi-emerald"
          badge="Verified Safe"
          badgeType="success"
        />
      </div>

      {/* Main Grid: Live Map + Moderation Preview */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Live Incident Map */}
        <div className="lg:col-span-2 bg-white p-5 rounded-xl border border-slate-200/80 shadow-sm flex flex-col">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="font-bold text-slate-800 text-base">Geospatial Risk & Incident Cluster Map</h3>
              <p className="text-xs text-slate-500">Live verified and reported incident coordinates</p>
            </div>
            <span className="text-xs font-semibold px-2.5 py-1 bg-slate-100 text-slate-700 rounded-full border border-slate-200">
              {incidents.length} Markers Plotted
            </span>
          </div>
          <div className="flex-1 min-h-[380px]">
            <IncidentMap incidents={incidents} />
          </div>
        </div>

        {/* Category Breakdown & Quick Moderation */}
        <div className="space-y-6">
          {/* Categories */}
          <div className="bg-white p-5 rounded-xl border border-slate-200/80 shadow-sm">
            <h3 className="font-bold text-slate-800 text-sm mb-1">Reported Categories Distribution</h3>
            <p className="text-xs text-slate-500 mb-4">Breakdown of verified reports across areas</p>

            <div className="space-y-3">
              {Object.entries(stats.categories_breakdown || {}).map(([cat, count]) => {
                const pct = stats.total_incidents > 0 ? Math.round((count / stats.total_incidents) * 100) : 0;
                return (
                  <div key={cat}>
                    <div className="flex justify-between text-xs font-medium mb-1">
                      <span className="text-slate-700">{cat.replace('_', ' ')}</span>
                      <span className="text-slate-500">{count} ({pct}%)</span>
                    </div>
                    <div className="w-full bg-slate-100 h-2 rounded-full overflow-hidden">
                      <div 
                        className="bg-sakhi-violet h-full rounded-full transition-all duration-500" 
                        style={{ width: `${Math.max(5, pct)}%` }} 
                      />
                    </div>
                  </div>
                );
              })}
              {Object.keys(stats.categories_breakdown || {}).length === 0 && (
                <p className="text-xs text-slate-400 italic">No incidents recorded yet.</p>
              )}
            </div>
          </div>

          {/* Pending Moderation Queue Card */}
          <div className="bg-white p-5 rounded-xl border border-slate-200/80 shadow-sm">
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-bold text-slate-800 text-sm">Pending Verification Queue</h3>
              <span className="text-xs font-bold text-amber-600 bg-amber-50 px-2 py-0.5 rounded-full border border-amber-200">
                {stats.pending_moderation}
              </span>
            </div>
            <p className="text-xs text-slate-500 mb-4">
              Community reported incidents awaiting moderator review and ground verification.
            </p>
            <button
              onClick={onNavigateToModeration}
              className="w-full py-2.5 px-4 bg-sakhi-violet text-white text-xs font-semibold rounded-lg hover:bg-[#4A2491] transition-colors shadow-sm"
            >
              Open Moderation Queue ({stats.pending_moderation})
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
