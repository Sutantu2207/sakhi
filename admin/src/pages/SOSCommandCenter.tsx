import React, { useState } from 'react';
import { SOSEvent } from '../types';
import { AdminApi } from '../services/api';
import { AlertOctagon, CheckCircle2, Clock, Phone, MapPin, Shield, Check } from 'lucide-react';

interface SOSProps {
  sosEvents: SOSEvent[];
  onRefresh: () => void;
}

export const SOSCommandCenter: React.FC<SOSProps> = ({ sosEvents, onRefresh }) => {
  const [loadingId, setLoadingId] = useState<string | null>(null);

  const activeEvents = sosEvents.filter(e => e.status === 'ACTIVE' || e.status === 'ACKNOWLEDGED' || e.status === 'CREATED');
  const pastEvents = sosEvents.filter(e => e.status === 'RESOLVED' || e.status === 'CANCELLED');

  const handleAcknowledge = async (id: string) => {
    setLoadingId(id);
    try {
      await AdminApi.acknowledgeSOS(id);
      onRefresh();
    } catch (err: any) {
      alert(`Failed to acknowledge: ${err.message}`);
    } finally {
      setLoadingId(null);
    }
  };

  const handleResolve = async (id: string) => {
    const notes = prompt('Enter resolution summary / dispatch notes:', 'Emergency patrol dispatched. Victim reported safe.');
    if (notes === null) return;

    setLoadingId(id);
    try {
      await AdminApi.resolveSOS(id, notes);
      onRefresh();
    } catch (err: any) {
      alert(`Failed to resolve: ${err.message}`);
    } finally {
      setLoadingId(null);
    }
  };

  return (
    <div className="space-y-6">
      {/* Active Alerts Section */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2.5">
            <div className="p-2 bg-red-100 rounded-lg text-red-600">
              <AlertOctagon className="w-5 h-5" />
            </div>
            <div>
              <h3 className="font-bold text-slate-800 text-base">Active Emergency Dispatches</h3>
              <p className="text-xs text-slate-500">Live high-priority emergency alerts captured by the Sakhi network</p>
            </div>
          </div>
          <span className="text-xs font-bold px-3 py-1 bg-red-50 text-red-700 rounded-full border border-red-200 animate-pulse">
            {activeEvents.length} Pending Actions
          </span>
        </div>

        {activeEvents.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {activeEvents.map((sos) => (
              <div 
                key={sos.id} 
                className="bg-white rounded-xl border-2 border-red-500/40 p-5 shadow-md shadow-red-500/5 relative overflow-hidden"
              >
                <div className="absolute top-0 left-0 w-1.5 h-full bg-red-500"></div>

                <div className="flex items-start justify-between mb-3">
                  <div>
                    <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-slate-100 text-slate-600">
                      ID: {sos.id.slice(0, 8)}
                    </span>
                    <h4 className="font-bold text-slate-800 text-base mt-1">
                      {sos.address_approx || 'GPS Emergency Beacon'}
                    </h4>
                  </div>
                  <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${
                    sos.status === 'ACKNOWLEDGED' 
                      ? 'bg-amber-100 text-amber-800 border border-amber-300' 
                      : 'bg-red-100 text-red-700 border border-red-300 animate-pulse'
                  }`}>
                    {sos.status}
                  </span>
                </div>

                <div className="space-y-2 text-xs text-slate-600 my-4 bg-slate-50 p-3 rounded-lg border border-slate-200">
                  <div className="flex items-center gap-2">
                    <MapPin className="w-3.5 h-3.5 text-red-500" />
                    <span className="font-mono">{sos.latitude.toFixed(5)}, {sos.longitude.toFixed(5)}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Clock className="w-3.5 h-3.5 text-slate-400" />
                    <span>Triggered: {new Date(sos.triggered_at).toLocaleString()}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Shield className="w-3.5 h-3.5 text-emerald-600" />
                    <span>Trusted Contacts Notified: <b>{sos.contacts_notified_count}</b> ({sos.notification_status})</span>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex items-center gap-2 mt-4 pt-3 border-t border-slate-100">
                  {sos.status !== 'ACKNOWLEDGED' && (
                    <button
                      onClick={() => handleAcknowledge(sos.id)}
                      disabled={loadingId === sos.id}
                      className="flex-1 py-2 px-3 bg-amber-500 hover:bg-amber-600 text-white font-bold text-xs rounded-lg transition-colors flex items-center justify-center gap-1.5 shadow-sm"
                    >
                      <Check className="w-3.5 h-3.5" />
                      <span>Acknowledge Dispatch</span>
                    </button>
                  )}
                  <button
                    onClick={() => handleResolve(sos.id)}
                    disabled={loadingId === sos.id}
                    className="flex-1 py-2 px-3 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-lg transition-colors flex items-center justify-center gap-1.5 shadow-sm"
                  >
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    <span>Resolve & Close Alert</span>
                  </button>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="bg-white rounded-xl p-8 border border-slate-200/80 text-center shadow-sm">
            <div className="w-12 h-12 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-3 text-emerald-600">
              <CheckCircle2 className="w-6 h-6" />
            </div>
            <h4 className="font-bold text-slate-800 text-sm">No Active Emergency Alerts</h4>
            <p className="text-xs text-slate-500 mt-1">All historical SOS events have been resolved and logged.</p>
          </div>
        )}
      </div>

      {/* Historical Resolved Section */}
      <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-slate-200">
          <h4 className="font-bold text-slate-800 text-sm">Resolved & Past SOS Events</h4>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-600">
            <thead className="bg-slate-50 text-slate-700 uppercase font-semibold text-[11px] tracking-wider border-b border-slate-200">
              <tr>
                <th className="py-3 px-4">Event ID</th>
                <th className="py-3 px-4">Location</th>
                <th className="py-3 px-4">Trigger Time</th>
                <th className="py-3 px-4">Resolved Time</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4">Resolution Notes</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {pastEvents.map((e) => (
                <tr key={e.id} className="hover:bg-slate-50/70">
                  <td className="py-3 px-4 font-mono font-medium">{e.id.slice(0, 8)}</td>
                  <td className="py-3 px-4">{e.address_approx || `${e.latitude.toFixed(4)}, ${e.longitude.toFixed(4)}`}</td>
                  <td className="py-3 px-4">{new Date(e.triggered_at).toLocaleString()}</td>
                  <td className="py-3 px-4">{e.resolved_at ? new Date(e.resolved_at).toLocaleString() : '—'}</td>
                  <td className="py-3 px-4">
                    <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                      e.status === 'RESOLVED' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' : 'bg-slate-100 text-slate-600'
                    }`}>
                      {e.status}
                    </span>
                  </td>
                  <td className="py-3 px-4 max-w-xs truncate text-slate-700 italic">
                    {e.admin_notes || '—'}
                  </td>
                </tr>
              ))}
              {pastEvents.length === 0 && (
                <tr>
                  <td colSpan={6} className="py-6 text-center text-slate-400 italic">
                    No past SOS records.
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
