import React from 'react';
import { 
  LayoutDashboard, 
  MapPin, 
  ShieldAlert, 
  AlertTriangle, 
  Building2, 
  BookOpen, 
  BarChart3, 
  History, 
  LogOut,
  Shield
} from 'lucide-react';

interface SidebarProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
  onLogout: () => void;
  activeSosCount: number;
  pendingIncidentsCount: number;
}

export const Sidebar: React.FC<SidebarProps> = ({
  activeTab,
  setActiveTab,
  onLogout,
  activeSosCount,
  pendingIncidentsCount
}) => {
  const menuItems = [
    { id: 'overview', label: 'Overview', icon: LayoutDashboard },
    { id: 'incident-map', label: 'Incident Map', icon: MapPin },
    { 
      id: 'moderation', 
      label: 'Incident Queue', 
      icon: ShieldAlert,
      badge: pendingIncidentsCount > 0 ? pendingIncidentsCount : null,
      badgeColor: 'bg-sakhi-amber text-white'
    },
    { 
      id: 'sos', 
      label: 'SOS Command Center', 
      icon: AlertTriangle,
      badge: activeSosCount > 0 ? activeSosCount : null,
      badgeColor: 'bg-sakhi-emergency text-white animate-pulse'
    },
    { id: 'resources', label: 'Emergency Resources', icon: Building2 },
    { id: 'support', label: 'Support Directory', icon: BookOpen },
    { id: 'analytics', label: 'Risk Analytics', icon: BarChart3 },
    { id: 'audit', label: 'Audit Logs', icon: History },
  ];

  return (
    <aside className="w-64 bg-[#1A1429] text-white flex flex-col justify-between shadow-xl flex-shrink-0">
      <div>
        {/* Brand Header */}
        <div className="p-6 border-b border-white/10 flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-[#3A1C71] to-[#6A3FB5] flex items-center justify-center shadow-lg shadow-purple-950/50">
            <Shield className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="font-bold text-lg tracking-wider text-white">SAKHI</h1>
            <p className="text-xs text-purple-300/70 font-medium">CENTRAL OPS PORTAL</p>
          </div>
        </div>

        {/* Navigation */}
        <nav className="p-4 space-y-1.5">
          {menuItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-lg text-sm font-medium transition-all ${
                  isActive
                    ? 'bg-sakhi-violet text-white shadow-md shadow-purple-900/30 font-semibold'
                    : 'text-purple-200/80 hover:bg-white/5 hover:text-white'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon className={`w-4 h-4 ${isActive ? 'text-white' : 'text-purple-300/70'}`} />
                  <span>{item.label}</span>
                </div>
                {item.badge !== null && (
                  <span className={`text-[11px] px-2 py-0.5 rounded-full font-bold ${item.badgeColor}`}>
                    {item.badge}
                  </span>
                )}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Footer Profile & Logout */}
      <div className="p-4 border-t border-white/10">
        <div className="flex items-center justify-between px-2 py-2">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-full bg-purple-800/80 flex items-center justify-center text-xs font-bold text-white border border-purple-500/30">
              AD
            </div>
            <div>
              <p className="text-xs font-semibold text-white">Admin Console</p>
              <p className="text-[10px] text-emerald-400 flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
                Authorized
              </p>
            </div>
          </div>
          <button
            onClick={onLogout}
            title="Logout"
            className="p-2 text-purple-300 hover:text-rose-400 hover:bg-white/5 rounded-lg transition-colors"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </div>
    </aside>
  );
};
