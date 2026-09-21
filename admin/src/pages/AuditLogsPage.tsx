import React, { useState, useEffect } from 'react';
import { AuditLogItem } from '../types';
import { AdminApi } from '../services/api';
import { History, ShieldCheck, UserCheck } from 'lucide-react';

export const AuditLogsPage: React.FC = () => {
  const [logs, setLogs] = useState<AuditLogItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  const loadLogs = async () => {
    setLoading(true);
    try {
      const data = await AdminApi.getAuditLogs(100);
      setLogs(data);
    } catch (err: any) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadLogs();
  }, []);

  return (
    <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm overflow-hidden">
      <div className="p-4 border-b border-slate-200 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <History className="w-4 h-4 text-sakhi-violet" />
          <h3 className="font-bold text-slate-800 text-sm">System & Compliance Audit Trail</h3>
        </div>
        <span className="text-xs text-slate-500 font-medium">Last 100 logged events</span>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs text-slate-600">
          <thead className="bg-slate-50 text-slate-700 uppercase font-semibold text-[11px] tracking-wider border-b border-slate-200">
            <tr>
              <th className="py-3 px-4">Timestamp</th>
              <th className="py-3 px-4">Action</th>
              <th className="py-3 px-4">Resource</th>
              <th className="py-3 px-4">User ID</th>
              <th className="py-3 px-4">Operational Details</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {logs.map((log) => (
              <tr key={log.id} className="hover:bg-slate-50/70">
                <td className="py-3 px-4 whitespace-nowrap text-slate-500">
                  {new Date(log.timestamp).toLocaleString()}
                </td>
                <td className="py-3 px-4">
                  <span className="px-2 py-0.5 rounded text-[10px] font-mono font-bold bg-purple-50 text-sakhi-violet border border-purple-200">
                    {log.action}
                  </span>
                </td>
                <td className="py-3 px-4 font-mono text-[11px] text-slate-700 font-semibold">
                  {log.resource_type}
                </td>
                <td className="py-3 px-4 font-mono text-[11px] text-slate-500">
                  {log.user_id ? log.user_id.slice(0, 8) : 'ANONYMOUS / SYSTEM'}
                </td>
                <td className="py-3 px-4 max-w-sm truncate text-slate-600 font-medium">
                  {log.details || '—'}
                </td>
              </tr>
            ))}
            {logs.length === 0 && (
              <tr>
                <td colSpan={5} className="py-8 text-center text-slate-400 italic">
                  No audit logs recorded yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
