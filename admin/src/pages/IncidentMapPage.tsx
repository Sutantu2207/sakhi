import React, { useState } from 'react';
import { Incident, IncidentCategory, IncidentSeverity, IncidentStatus } from '../types';
import { IncidentMap } from '../components/IncidentMap';
import { Filter, Layers } from 'lucide-react';

interface IncidentMapPageProps {
  incidents: Incident[];
}

export const IncidentMapPage: React.FC<IncidentMapPageProps> = ({ incidents }) => {
  const [selectedCategory, setSelectedCategory] = useState<string>('ALL');
  const [selectedSeverity, setSelectedSeverity] = useState<string>('ALL');
  const [selectedStatus, setSelectedStatus] = useState<string>('ALL');

  const filteredIncidents = incidents.filter((inc) => {
    if (selectedCategory !== 'ALL' && inc.category !== selectedCategory) return false;
    if (selectedSeverity !== 'ALL' && inc.severity !== selectedSeverity) return false;
    if (selectedStatus !== 'ALL' && inc.status !== selectedStatus) return false;
    return true;
  });

  return (
    <div className="h-[calc(100vh-8.5rem)] flex flex-col space-y-4">
      {/* Filter Toolbar */}
      <div className="bg-white p-4 rounded-xl border border-slate-200/80 shadow-sm flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-2 text-slate-700 font-semibold text-sm">
          <Filter className="w-4 h-4 text-sakhi-violet" />
          <span>Map Filters</span>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Category */}
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="text-xs bg-slate-50 border border-slate-200 rounded-lg px-3 py-2 font-medium text-slate-700 focus:outline-none focus:ring-2 focus:ring-sakhi-violet/30"
          >
            <option value="ALL">All Categories</option>
            <option value="HARASSMENT">Harassment</option>
            <option value="STALKING">Stalking</option>
            <option value="POOR_LIGHTING">Poor Lighting</option>
            <option value="UNSAFE_AREA">Unsafe Area</option>
            <option value="ASSAULT">Assault</option>
            <option value="CYBERCRIME">Cybercrime</option>
          </select>

          {/* Severity */}
          <select
            value={selectedSeverity}
            onChange={(e) => setSelectedSeverity(e.target.value)}
            className="text-xs bg-slate-50 border border-slate-200 rounded-lg px-3 py-2 font-medium text-slate-700 focus:outline-none focus:ring-2 focus:ring-sakhi-violet/30"
          >
            <option value="ALL">All Severities</option>
            <option value="CRITICAL">Critical</option>
            <option value="HIGH">High</option>
            <option value="MEDIUM">Medium</option>
            <option value="LOW">Low</option>
          </select>

          {/* Status */}
          <select
            value={selectedStatus}
            onChange={(e) => setSelectedStatus(e.target.value)}
            className="text-xs bg-slate-50 border border-slate-200 rounded-lg px-3 py-2 font-medium text-slate-700 focus:outline-none focus:ring-2 focus:ring-sakhi-violet/30"
          >
            <option value="ALL">All Statuses</option>
            <option value="VERIFIED">Verified</option>
            <option value="PENDING">Pending</option>
            <option value="RESOLVED">Resolved</option>
          </select>

          <span className="text-xs font-semibold px-3 py-1.5 bg-purple-50 text-sakhi-violet rounded-lg border border-purple-200">
            {filteredIncidents.length} Visible
          </span>
        </div>
      </div>

      {/* Map Container */}
      <div className="flex-1 w-full bg-white rounded-xl overflow-hidden shadow-sm border border-slate-200">
        <IncidentMap incidents={filteredIncidents} />
      </div>
    </div>
  );
};
