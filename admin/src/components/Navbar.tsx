import React, { useState, useEffect } from 'react';
import { Activity, Bell, RefreshCw } from 'lucide-react';

interface NavbarProps {
  title: string;
  onRefresh?: () => void;
  isRefreshing?: boolean;
}

export const Navbar: React.FC<NavbarProps> = ({ title, onRefresh, isRefreshing }) => {
  const [time, setTime] = useState<string>('');

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setTime(now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false }));
    };
    updateTime();
    const interval = setInterval(updateTime, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <header className="h-16 bg-white border-b border-sakhi-border px-8 flex items-center justify-between shadow-sm z-20">
      <div>
        <h2 className="text-xl font-bold text-sakhi-charcoal">{title}</h2>
      </div>

      <div className="flex items-center gap-5">
        {onRefresh && (
          <button
            onClick={onRefresh}
            disabled={isRefreshing}
            className="flex items-center gap-1.5 text-xs font-medium text-slate-600 hover:text-sakhi-violet px-3 py-1.5 rounded-lg border border-slate-200 hover:border-sakhi-violet/40 bg-slate-50 transition-all"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin text-sakhi-violet' : ''}`} />
            <span>Sync</span>
          </button>
        )}

        {/* Live Status Pill */}
        <div className="flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-200/60 text-emerald-700 text-xs font-semibold">
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
          </span>
          <span>SYSTEM LIVE</span>
        </div>

        {/* Switch to Citizen Portal */}
        <button
          onClick={() => {
            const url = new URL(window.location.href);
            url.searchParams.set('mode', 'user');
            window.location.href = url.toString();
          }}
          className="text-xs font-semibold px-3 py-1.5 bg-gradient-to-r from-red-600 to-purple-600 text-white rounded-lg shadow-sm hover:opacity-95 transition"
        >
          Citizen Portal &rarr;
        </button>

        {/* Live Clock */}
        <div className="text-xs font-mono font-medium text-slate-500 bg-slate-100 px-2.5 py-1 rounded-md border border-slate-200">
          {time} UTC
        </div>
      </div>
    </header>
  );
};
