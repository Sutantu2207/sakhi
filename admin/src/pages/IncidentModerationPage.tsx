import React, { useState } from 'react';
import { Incident, IncidentStatus } from '../types';
import { AdminApi } from '../services/api';
import { Check, X, CheckCircle, ShieldAlert, Clock, MapPin, Eye } from 'lucide-react';

interface ModerationProps {
  incidents: Incident[];
  onRefresh: () => void;
}

export const IncidentModerationPage: React.FC<ModerationProps> = ({ incidents, onRefresh }) => {
  const [filterStatus, setFilterStatus] = useState<string>('PENDING');
  const [loadingId, setLoadingId] = useState<string | null>(null);
  const [selectedIncident, setSelectedIncident] = useState<Incident | null>(null);

  const handleModerate = async (id: string, status: IncidentStatus) => {
    const notes = prompt(`Enter moderation notes for ${status}:`, '');
    if (notes === null) return; // cancelled

    setLoadingId(id);
    try {
      await AdminApi.moderateIncident(id, status, notes || undefined);
      onRefresh();
    } catch (err: any) {
      alert(`Error updating incident: ${err.message}`);
    } finally {
      setLoadingId(null);
    }
  };

  const filtered = incidents.filter(i => filterStatus === 'ALL' || i.status === filterStatus);

  const statusColors: Record<string, string> = {
    PENDING: 'bg-amber-50 text-amber-700 border-amber-200',
    VERIFIED: 'bg-emerald-50 text-emerald-700 border-emerald-200',
    REJECTED: 'bg-rose-50 text-rose-700 border-rose-200',
    RESOLVED: 'bg-blue-50 text-blue-700 border-blue-200'
  };

  const severityColors: Record<string, string> = {
    CRITICAL: 'bg-red-500 text-white',
    HIGH: 'bg-amber-500 text-white',
    MEDIUM: 'bg-orange-400 text-white',
    LOW: 'bg-teal-600 text-white'
  };

  return (
    <div className="space-y-5">
      {/* Header & Filter Tabs */}
      <div className="bg-white p-4 rounded-xl border border-slate-200/80 shadow-sm flex items-center justify-between">
        <div className="flex items-center gap-2">
          {['PENDING', 'VERIFIED', 'REJECTED', 'RESOLVED', 'ALL'].map((tab) => (
            <button
              key={tab}
              onClick={() => setFilterStatus(tab)}
              className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                filterStatus === tab
                  ? 'bg-sakhi-violet text-white shadow-sm'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              }`}
            >
              {tab} ({tab === 'ALL' ? incidents.length : incidents.filter(i => i.status === tab).length})
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-600">
            <thead className="bg-slate-50 border-b border-slate-200 text-slate-700 uppercase font-semibold text-[11px] tracking-wider">
              <tr>
                <th className="py-3 px-4">Category & Severity</th>
                <th className="py-3 px-4">Description</th>
                <th className="py-3 px-4">Coordinates</th>
                <th className="py-3 px-4">Reported Time</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4 text-right">Moderation Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filtered.map((inc) => (
                <tr key={inc.id} className="hover:bg-slate-50/70 transition-colors">
                  <td className="py-3.5 px-4">
                    <div className="flex items-center gap-2">
                      <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${severityColors[inc.severity]}`}>
                        {inc.severity}
                      </span>
                      <span className="font-bold text-slate-800">{inc.category.replace('_', ' ')}</span>
                    </div>
                    {inc.is_anonymous && (
                      <span className="text-[10px] text-slate-400 block mt-1">Anonymous Report</span>
                    )}
                  </td>
                  <td className="py-3.5 px-4 max-w-xs">
                    <p className="line-clamp-2 text-slate-700 font-medium">{inc.description}</p>
                    {inc.moderator_notes && (
                      <p className="text-[11px] text-purple-700 italic mt-1 bg-purple-50 p-1 rounded">
                        Note: {inc.moderator_notes}
                      </p>
                    )}
                  </td>
                  <td className="py-3.5 px-4 font-mono text-[11px] text-slate-500 whitespace-nowrap">
                    {inc.latitude.toFixed(4)}, {inc.longitude.toFixed(4)}
                  </td>
                  <td className="py-3.5 px-4 whitespace-nowrap text-slate-500">
                    {new Date(inc.incident_time).toLocaleString()}
                  </td>
                  <td className="py-3.5 px-4">
                    <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold border ${statusColors[inc.status]}`}>
                      {inc.status}
                    </span>
                  </td>
                  <td className="py-3.5 px-4 text-right">
                    <div className="flex items-center justify-end gap-1.5">
                      {inc.status !== 'VERIFIED' && (
                        <button
                          onClick={() => handleModerate(inc.id, 'VERIFIED')}
                          disabled={loadingId === inc.id}
                          title="Verify Incident"
                          className="p-1.5 bg-emerald-50 text-emerald-700 hover:bg-emerald-100 rounded-lg border border-emerald-200 transition-colors"
                        >
                          <Check className="w-3.5 h-3.5" />
                        </button>
                      )}
                      {inc.status !== 'RESOLVED' && (
                        <button
                          onClick={() => handleModerate(inc.id, 'RESOLVED')}
                          disabled={loadingId === inc.id}
                          title="Mark Resolved"
                          className="p-1.5 bg-blue-50 text-blue-700 hover:bg-blue-100 rounded-lg border border-blue-200 transition-colors"
                        >
                          <CheckCircle className="w-3.5 h-3.5" />
                        </button>
                      )}
                      {inc.status !== 'REJECTED' && (
                        <button
                          onClick={() => handleModerate(inc.id, 'REJECTED')}
                          disabled={loadingId === inc.id}
                          title="Reject Report"
                          className="p-1.5 bg-rose-50 text-rose-700 hover:bg-rose-100 rounded-lg border border-rose-200 transition-colors"
                        >
                          <X className="w-3.5 h-3.5" />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400 italic">
                    No incidents matching status "{filterStatus}".
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
