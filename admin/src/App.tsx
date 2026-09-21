import React, { useState, useEffect } from 'react';
import { Sidebar } from './components/Sidebar';
import { Navbar } from './components/Navbar';
import { Overview } from './pages/Overview';
import { IncidentMapPage } from './pages/IncidentMapPage';
import { IncidentModerationPage } from './pages/IncidentModerationPage';
import { SOSCommandCenter } from './pages/SOSCommandCenter';
import { ResourcesPage } from './pages/ResourcesPage';
import { RiskAnalyticsPage } from './pages/RiskAnalyticsPage';
import { AuditLogsPage } from './pages/AuditLogsPage';
import { LoginPage } from './pages/LoginPage';
import { UserDashboard } from './pages/UserDashboard';
import { MeshMonitorPage } from './pages/MeshMonitorPage';
import { AdminApi } from './services/api';
import { OverviewStats, Incident, SOSEvent } from './types';

export function App() {
  // Mode: 'admin' vs 'user' (checked via URL or state)
  const [portalMode, setPortalMode] = useState<'admin' | 'user'>(() => {
    const params = new URLSearchParams(window.location.search);
    if (params.get('mode') === 'user') return 'user';
    return 'admin';
  });

  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(() => {
    return !!localStorage.getItem('sakhi_admin_token');
  });
  const [activeTab, setActiveTab] = useState<string>('overview');
  const [stats, setStats] = useState<OverviewStats | null>(null);
  const [incidents, setIncidents] = useState<Incident[]>([]);
  const [sosEvents, setSosEvents] = useState<SOSEvent[]>([]);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);

  const fetchData = async () => {
    if (!isAuthenticated) return;
    setIsRefreshing(true);
    try {
      const [overviewData, incidentsData, sosData] = await Promise.all([
        AdminApi.getOverview(),
        AdminApi.getIncidents(),
        AdminApi.getSOSEvents()
      ]);
      setStats(overviewData);
      setIncidents(incidentsData);
      setSosEvents(sosData);
    } catch (err: any) {
      console.error('Data fetch error:', err);
    } finally {
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    if (isAuthenticated && portalMode === 'admin') {
      fetchData();
      const interval = setInterval(fetchData, 15000); // 15s polling
      return () => clearInterval(interval);
    }
  }, [isAuthenticated, portalMode]);

  useEffect(() => {
    const handleAuthExpired = () => setIsAuthenticated(false);
    window.addEventListener('auth_expired', handleAuthExpired);
    return () => window.removeEventListener('auth_expired', handleAuthExpired);
  }, []);

  const handleLogout = () => {
    AdminApi.clearToken();
    setIsAuthenticated(false);
  };

  const switchMode = (newMode: 'admin' | 'user') => {
    setPortalMode(newMode);
    const url = new URL(window.location.href);
    url.searchParams.set('mode', newMode);
    window.history.pushState({}, '', url.toString());
  };

  // If in user mode, render the Citizen / User Safety Dashboard
  if (portalMode === 'user') {
    return <UserDashboard onSwitchToAdmin={() => switchMode('admin')} />;
  }

  // If admin mode and not authenticated, render Admin Login
  if (!isAuthenticated) {
    return <LoginPage onLoginSuccess={() => setIsAuthenticated(true)} />;
  }

  const activeSosCount = sosEvents.filter(e => e.status === 'ACTIVE' || e.status === 'ACKNOWLEDGED').length;
  const pendingIncidentsCount = stats?.pending_moderation || 0;

  const tabTitles: Record<string, string> = {
    'overview': 'Operations Overview & Live Metrics',
    'incident-map': 'Geospatial Incident & Risk Zone Map',
    'moderation': 'Incident Moderation & Verification Queue',
    'sos': 'Emergency SOS Command Center',
    'resources': 'Emergency Infrastructure & Facilities',
    'support': 'Legal & Crisis Support Directory',
    'analytics': 'AI/ML Risk Engine & Analytics',
    'mesh': 'SAKHI Emergency Mesh & BLE Gateway Telemetry',
    'audit': 'Security & Compliance Audit Logs',
  };

  return (
    <div className="flex h-screen bg-[#F8F9FC] overflow-hidden">
      {/* Sidebar */}
      <Sidebar
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        onLogout={handleLogout}
        activeSosCount={activeSosCount}
        pendingIncidentsCount={pendingIncidentsCount}
      />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <Navbar
          title={tabTitles[activeTab] || 'Sakhi Admin Console'}
          onRefresh={fetchData}
          isRefreshing={isRefreshing}
        />

        <main className="flex-1 overflow-y-auto p-8">
          {activeTab === 'overview' && (
            <Overview
              stats={stats}
              incidents={incidents}
              activeSosEvents={sosEvents.filter(e => e.status === 'ACTIVE' || e.status === 'ACKNOWLEDGED')}
              onNavigateToModeration={() => setActiveTab('moderation')}
              onNavigateToSOS={() => setActiveTab('sos')}
            />
          )}

          {activeTab === 'incident-map' && (
            <IncidentMapPage incidents={incidents} />
          )}

          {activeTab === 'moderation' && (
            <IncidentModerationPage
              incidents={incidents}
              onRefresh={fetchData}
            />
          )}

          {activeTab === 'sos' && (
            <SOSCommandCenter
              sosEvents={sosEvents}
              onRefresh={fetchData}
            />
          )}

          {activeTab === 'resources' && (
            <ResourcesPage />
          )}

          {activeTab === 'support' && (
            <ResourcesPage />
          )}

          {activeTab === 'analytics' && (
            <RiskAnalyticsPage stats={stats} />
          )}

          {activeTab === 'mesh' && (
            <MeshMonitorPage />
          )}

          {activeTab === 'audit' && (
            <AuditLogsPage />
          )}
        </main>
      </div>
    </div>
  );
}

export default App;
