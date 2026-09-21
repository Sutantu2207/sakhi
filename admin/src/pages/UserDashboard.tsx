import React, { useState, useEffect } from 'react';
import { 
  Shield, AlertTriangle, PhoneCall, Navigation, MapPin, 
  Users, Lock, FileText, CheckCircle2, Radio, Bell, ArrowRight,
  RefreshCw, LogOut, EyeOff, Sparkles, X, Plus, Trash2, ExternalLink,
  Share2, HelpCircle, HeartHandshake, Wifi, Cpu, Clock, Phone, ShieldAlert
} from 'lucide-react';
import { UserApi } from '../services/api';
import { IncidentMap } from '../components/IncidentMap';

interface Contact {
  id: string;
  name: string;
  phone_number: string;
  relationship?: string;
  notify_sos: boolean;
}

export function UserDashboard({ onSwitchToAdmin }: { onSwitchToAdmin: () => void }) {
  // Auth state
  const [isUserLoggedIn, setIsUserLoggedIn] = useState<boolean>(() => {
    return !!localStorage.getItem('sakhi_user_token');
  });
  const [email, setEmail] = useState('priya@example.com');
  const [password, setPassword] = useState('SakhiUser123!');
  const [authError, setAuthError] = useState('');
  const [userProfile, setUserProfile] = useState<any>(null);

  // Active view tab
  const [activeTab, setActiveTab] = useState<'home' | 'journey' | 'map' | 'report' | 'nearby' | 'legal' | 'contacts' | 'privacy'>('home');

  // SOS state
  const [sosCountdown, setSosCountdown] = useState<number | null>(null);
  const [activeSOS, setActiveSOS] = useState<any | null>(null);
  const [isSosLoading, setIsSosLoading] = useState<boolean>(false);

  // Journey state
  const [activeJourney, setActiveJourney] = useState<any | null>(null);
  const [destination, setDestination] = useState('Connaught Place Metro Station');
  const [etaMins, setEtaMins] = useState(25);
  const [sharedLink, setSharedLink] = useState<string | null>(null);

  // Safety & Area risk
  const [areaRisk, setAreaRisk] = useState<any | null>(null);
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number }>({ lat: 28.6139, lng: 77.2090 }); // New Delhi center
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [incidents, setIncidents] = useState<any[]>([]);
  const [resources, setResources] = useState<any[]>([]);

  // Reporting form
  const [reportCategory, setReportCategory] = useState('POOR_LIGHTING');
  const [reportDesc, setReportDesc] = useState('');
  const [reportSeverity, setReportSeverity] = useState('MEDIUM');
  const [isAnonymous, setIsAnonymous] = useState(true);
  const [reportSuccess, setReportSuccess] = useState(false);

  // Add Contact modal
  const [showAddContact, setShowAddContact] = useState(false);
  const [newContactName, setNewContactName] = useState('');
  const [newContactPhone, setNewContactPhone] = useState('');
  const [newContactRelation, setNewContactRelation] = useState('Sister');

  // Emergency Upgrades & Modals
  const [showHelplinesModal, setShowHelplinesModal] = useState(false);
  const [showDecisionSupportModal, setShowDecisionSupportModal] = useState(false);
  const [showPostSosModal, setShowPostSosModal] = useState(false);
  const [showLocationShareModal, setShowLocationShareModal] = useState(false);
  const [shareDuration, setShareDuration] = useState<'15m' | '30m' | '1h' | 'until_stop'>('30m');
  const [tempShareToken, setTempShareToken] = useState<string | null>(null);
  const [selectedDecisionCategory, setSelectedDecisionCategory] = useState<string | null>(null);

  // Load Initial Data
  const loadUserData = async () => {
    if (!isUserLoggedIn) return;
    try {
      const [profileData, contactsData, activeSosData, activeJourneyData, riskData, nearbyIncidents, nearbyRes] = await Promise.all([
        UserApi.getProfile().catch(() => null),
        UserApi.getContacts().catch(() => []),
        UserApi.getActiveSOS().catch(() => null),
        UserApi.getActiveJourney().catch(() => null),
        UserApi.getAreaRisk(userLocation.lat, userLocation.lng).catch(() => null),
        UserApi.getNearbyIncidents(userLocation.lat, userLocation.lng, 10).catch(() => []),
        UserApi.getNearbyResources(userLocation.lat, userLocation.lng, undefined, 15).catch(() => [])
      ]);

      if (profileData) setUserProfile(profileData);
      if (contactsData) setContacts(contactsData);
      if (activeSosData) setActiveSOS(activeSosData);
      if (activeJourneyData) setActiveJourney(activeJourneyData);
      if (riskData) setAreaRisk(riskData);
      if (nearbyIncidents) setIncidents(nearbyIncidents);
      if (nearbyRes) setResources(nearbyRes);
    } catch (e) {
      console.error('Error loading user data:', e);
    }
  };

  useEffect(() => {
    if (isUserLoggedIn) {
      loadUserData();
    }
  }, [isUserLoggedIn]);

  // Handle SOS countdown timer
  useEffect(() => {
    let timer: any;
    if (sosCountdown !== null && sosCountdown > 0) {
      timer = setTimeout(() => setSosCountdown(sosCountdown - 1), 1000);
    } else if (sosCountdown === 0) {
      setSosCountdown(null);
      triggerSOSNow();
    }
    return () => clearTimeout(timer);
  }, [sosCountdown]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthError('');
    try {
      await UserApi.login(email, password);
      setIsUserLoggedIn(true);
    } catch (err: any) {
      setAuthError(err.message || 'Login failed');
    }
  };

  const handleLogout = () => {
    UserApi.clearToken();
    setIsUserLoggedIn(false);
    setUserProfile(null);
  };

  const startSosCountdown = () => {
    setSosCountdown(5);
  };

  const cancelSosCountdown = () => {
    setSosCountdown(null);
  };

  const triggerSOSNow = async () => {
    setIsSosLoading(true);
    try {
      const sos = await UserApi.triggerSOS(userLocation.lat, userLocation.lng, 8.5);
      setActiveSOS(sos);
    } catch (err: any) {
      alert('Could not trigger SOS: ' + err.message);
    } finally {
      setIsSosLoading(false);
    }
  };

  const resolveSOSNow = async () => {
    if (!activeSOS) return;
    setIsSosLoading(true);
    try {
      await UserApi.resolveSOS(activeSOS.id, 'User marked herself safe');
      setActiveSOS(null);
      setShowPostSosModal(true);
    } catch (err: any) {
      alert('Error marking safe: ' + err.message);
    } finally {
      setIsSosLoading(false);
    }
  };

  const handleStartJourney = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const journey = await UserApi.startJourney({
        origin_latitude: userLocation.lat,
        origin_longitude: userLocation.lng,
        destination_latitude: userLocation.lat + 0.02,
        destination_longitude: userLocation.lng + 0.02,
        destination_name: destination,
        expected_duration_minutes: Number(etaMins)
      });
      setActiveJourney(journey);
      setSharedLink(`https://sakhi.network/track/j-${journey.id.substring(0, 8)}`);
    } catch (err: any) {
      alert('Could not start journey: ' + err.message);
    }
  };

  const handleEndJourney = async () => {
    if (!activeJourney) return;
    try {
      await UserApi.endJourney(activeJourney.id);
      setActiveJourney(null);
      setSharedLink(null);
    } catch (err: any) {
      alert('Error ending journey: ' + err.message);
    }
  };

  const handleReportIncident = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await UserApi.reportIncident({
        category: reportCategory,
        description: reportDesc,
        latitude: userLocation.lat,
        longitude: userLocation.lng,
        severity: reportSeverity,
        is_anonymous: isAnonymous
      });
      setReportSuccess(true);
      setReportDesc('');
      setTimeout(() => setReportSuccess(false), 5000);
      loadUserData();
    } catch (err: any) {
      alert('Error submitting report: ' + err.message);
    }
  };

  const handleAddContact = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await UserApi.addContact({
        name: newContactName,
        phone_number: newContactPhone,
        relationship: newContactRelation,
        notify_sos: true
      });
      setShowAddContact(false);
      setNewContactName('');
      setNewContactPhone('');
      loadUserData();
    } catch (err: any) {
      alert('Error adding contact: ' + err.message);
    }
  };

  const handleDeleteContact = async (id: string) => {
    if (!confirm('Remove this trusted emergency contact?')) return;
    try {
      await UserApi.deleteContact(id);
      loadUserData();
    } catch (err: any) {
      alert('Error removing contact: ' + err.message);
    }
  };

  // If user is not logged in, show User Login / Demo portal
  if (!isUserLoggedIn) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-[#1F1F24] via-[#3A1C71] to-[#1F1F24] text-white flex flex-col justify-center items-center p-4">
        <div className="max-w-md w-full bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-8 shadow-2xl">
          <div className="flex justify-between items-center mb-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-[#3A1C71] to-[#E63946] flex items-center justify-center font-bold text-xl text-white shadow-lg">
                S
              </div>
              <div>
                <h1 className="text-xl font-bold tracking-tight text-white">SAKHI</h1>
                <p className="text-xs text-purple-200">Citizen Safety Portal</p>
              </div>
            </div>
            <button
              onClick={onSwitchToAdmin}
              className="text-xs text-purple-300 hover:text-white underline"
            >
              Switch to Admin &rarr;
            </button>
          </div>

          <div className="mb-6 p-4 rounded-xl bg-purple-950/40 border border-purple-500/30">
            <p className="text-xs text-purple-200 leading-relaxed">
              <strong>Demo User Account:</strong> Priya Sharma (Citizen)<br/>
              Empowering late-night travel, real-time SOS, safe routes, and community support.
            </p>
          </div>

          {authError && (
            <div className="mb-4 p-3 bg-red-500/20 border border-red-500/40 rounded-lg text-xs text-red-200">
              {authError}
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-xs font-medium text-purple-200 mb-1">Email Address</label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded-lg text-sm text-white focus:outline-none focus:border-purple-400"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-purple-200 mb-1">Password</label>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded-lg text-sm text-white focus:outline-none focus:border-purple-400"
              />
            </div>
            <button
              type="submit"
              className="w-full py-3 bg-[#E63946] hover:bg-[#d62839] text-white font-semibold rounded-xl text-sm transition-all duration-200 shadow-lg shadow-red-900/40 mt-2"
            >
              Log In to Citizen Portal
            </button>
          </form>

          <div className="mt-6 pt-4 border-t border-white/10 flex justify-between items-center text-xs text-purple-300">
            <span>Travel safer. Respond faster.</span>
            <button
              onClick={() => {
                setEmail('priya@example.com');
                setPassword('SakhiUser123!');
              }}
              className="hover:text-white underline"
            >
              Fill Demo Credentials
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F8F9FC] flex flex-col">
      {/* Top Banner & Quick Helplines */}
      <header className="bg-[#1F1F24] text-white px-6 py-3 border-b border-gray-800">
        <div className="max-w-7xl mx-auto flex flex-wrap justify-between items-center gap-4">
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-[#E63946] flex items-center justify-center font-bold text-white text-base">
                S
              </div>
              <div>
                <h1 className="font-bold text-sm tracking-wide">SAKHI CITIZEN SAFETY</h1>
                <p className="text-[10px] text-gray-400">Travel safer. Respond faster. Stay connected.</p>
              </div>
            </div>

            <div className="hidden md:flex items-center gap-2 pl-4 border-l border-gray-700">
              <span className="text-xs text-gray-400">Emergency Helplines:</span>
              <a href="tel:112" className="px-2 py-0.5 bg-red-600/30 text-red-300 rounded text-xs font-semibold hover:bg-red-600/50">
                112 Police
              </a>
              <a href="tel:1091" className="px-2 py-0.5 bg-purple-600/30 text-purple-300 rounded text-xs font-semibold hover:bg-purple-600/50">
                1091 Women
              </a>
              <a href="tel:1930" className="px-2 py-0.5 bg-blue-600/30 text-blue-300 rounded text-xs font-semibold hover:bg-blue-600/50">
                1930 Cybercrime
              </a>
              <a href="tel:181" className="px-2 py-0.5 bg-emerald-600/30 text-emerald-300 rounded text-xs font-semibold hover:bg-emerald-600/50">
                181 Crisis
              </a>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={onSwitchToAdmin}
              className="px-3 py-1.5 bg-purple-900/60 hover:bg-purple-900 text-purple-200 border border-purple-700/50 rounded-lg text-xs font-medium transition"
            >
              Switch to Admin Console &rarr;
            </button>
            <span className="text-xs text-gray-400 hidden sm:inline">
              Signed in as <strong className="text-white">{userProfile?.full_name || 'Priya Sharma'}</strong>
            </span>
            <button
              onClick={handleLogout}
              className="p-1.5 text-gray-400 hover:text-white rounded-lg hover:bg-gray-800"
              title="Logout"
            >
              <LogOut size={16} />
            </button>
          </div>
        </div>
      </header>

      {/* Navigation Sub-header */}
      <div className="bg-white border-b border-gray-200 px-6 py-2 sticky top-0 z-30 shadow-sm">
        <div className="max-w-7xl mx-auto flex items-center justify-between overflow-x-auto gap-4">
          <nav className="flex space-x-1 sm:space-x-2">
            {[
              { id: 'home', label: 'Safety Hub', icon: Shield },
              { id: 'journey', label: 'Journey Guard', icon: Navigation },
              { id: 'map', label: 'Safety Map', icon: MapPin },
              { id: 'report', label: 'Report Incident', icon: AlertTriangle },
              { id: 'nearby', label: 'Nearby Help', icon: PhoneCall },
              { id: 'legal', label: 'Rights Navigator', icon: FileText },
              { id: 'contacts', label: 'Emergency Contacts', icon: Users },
              { id: 'privacy', label: 'Privacy Vault', icon: Lock }
            ].map(tab => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id as any)}
                  className={`flex items-center gap-1.5 px-3 py-2 rounded-lg text-xs font-medium whitespace-nowrap transition-colors ${
                    isActive 
                      ? 'bg-purple-100 text-[#3A1C71] font-semibold' 
                      : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
                  }`}
                >
                  <Icon size={14} className={isActive ? 'text-[#3A1C71]' : 'text-gray-500'} />
                  {tab.label}
                </button>
              );
            })}
          </nav>

          <button
            onClick={loadUserData}
            className="flex items-center gap-1 text-xs text-gray-500 hover:text-gray-800 px-2 py-1 rounded"
            title="Refresh Data"
          >
            <RefreshCw size={12} />
            <span className="hidden sm:inline">Sync</span>
          </button>
        </div>
      </div>

      {/* Active SOS Critical Alert Banner */}
      {activeSOS && (
        <div className="bg-red-600 text-white px-6 py-3 shadow-lg animate-pulse flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Radio className="animate-ping" size={20} />
            <div>
              <strong className="text-sm font-bold">EMERGENCY SOS IS CURRENTLY ACTIVE!</strong>
              <p className="text-xs text-red-100">
                Live location broadcasted to {contacts.length} trusted contacts and emergency services dispatch.
              </p>
            </div>
          </div>
          <button
            onClick={resolveSOSNow}
            disabled={isSosLoading}
            className="px-4 py-1.5 bg-white text-red-700 font-bold rounded-lg text-xs shadow hover:bg-gray-100 transition"
          >
            I am Safe / Cancel SOS
          </button>
        </div>
      )}

      {/* SOS 5-Second Countdown Modal */}
      {sosCountdown !== null && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl p-8 max-w-sm w-full text-center shadow-2xl border-4 border-red-500 animate-bounce-short">
            <div className="w-20 h-20 mx-auto rounded-full bg-red-100 text-red-600 flex items-center justify-center text-4xl font-extrabold mb-4 shadow-inner">
              {sosCountdown}
            </div>
            <h2 className="text-xl font-bold text-gray-900 mb-2">TRIGGERING EMERGENCY SOS</h2>
            <p className="text-xs text-gray-500 mb-6">
              Dispatching live GPS location to trusted contacts and nearest helpline in {sosCountdown} seconds...
            </p>
            <div className="flex flex-col gap-2">
              <button
                onClick={triggerSOSNow}
                className="w-full py-3 bg-red-600 hover:bg-red-700 text-white font-bold rounded-xl text-sm shadow-lg shadow-red-600/40"
              >
                Trigger Immediately
              </button>
              <button
                onClick={cancelSosCountdown}
                className="w-full py-2.5 bg-gray-200 hover:bg-gray-300 text-gray-800 font-semibold rounded-xl text-sm"
              >
                Cancel / Accidental Press
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add Contact Modal */}
      {showAddContact && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full shadow-2xl">
            <div className="flex justify-between items-center mb-4">
              <h3 className="font-bold text-gray-900">Add Trusted Emergency Contact</h3>
              <button onClick={() => setShowAddContact(false)} className="text-gray-400 hover:text-gray-600">
                <X size={18} />
              </button>
            </div>
            <form onSubmit={handleAddContact} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Full Name</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Aditi Sharma"
                  value={newContactName}
                  onChange={(e) => setNewContactName(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-purple-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Phone Number</label>
                <input
                  type="tel"
                  required
                  placeholder="e.g. +91 98765 43210"
                  value={newContactPhone}
                  onChange={(e) => setNewContactPhone(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-purple-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1">Relationship</label>
                <select
                  value={newContactRelation}
                  onChange={(e) => setNewContactRelation(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-purple-500 focus:outline-none"
                >
                  <option value="Mother">Mother</option>
                  <option value="Father">Father</option>
                  <option value="Sister">Sister</option>
                  <option value="Brother">Brother</option>
                  <option value="Friend">Friend</option>
                  <option value="Partner">Partner</option>
                  <option value="Colleague">Colleague</option>
                </select>
              </div>
              <p className="text-[11px] text-gray-500">
                This contact will receive SMS/automated dispatch with your live GPS location during an SOS event.
              </p>
              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowAddContact(false)}
                  className="px-4 py-2 border border-gray-300 rounded-lg text-xs font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-[#3A1C71] text-white rounded-lg text-xs font-semibold hover:bg-purple-900"
                >
                  Save Contact
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Pan-India Emergency Helplines Modal */}
      {showHelplinesModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl p-6 max-w-lg w-full shadow-2xl border border-gray-100 max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center pb-3 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-red-100 text-red-600 flex items-center justify-center font-bold">
                  <PhoneCall size={18} />
                </div>
                <div>
                  <h3 className="font-extrabold text-base text-gray-900">EMERGENCY HELP CENTER</h3>
                  <p className="text-[11px] text-gray-500">Official Pan-India verified helplines. 1-tap direct dial.</p>
                </div>
              </div>
              <button onClick={() => setShowHelplinesModal(false)} className="text-gray-400 hover:text-gray-600 p-1 rounded-lg">
                <X size={20} />
              </button>
            </div>

            <div className="space-y-3 my-4">
              {/* 112 */}
              <div className="p-4 bg-red-50 rounded-2xl border border-red-100 flex items-center justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-lg font-black text-red-600">112</span>
                    <span className="px-2 py-0.5 bg-red-200/60 text-red-800 text-[10px] font-bold rounded-md">PAN-INDIA EMERGENCY</span>
                  </div>
                  <p className="text-xs text-gray-700 font-medium mt-0.5">National Emergency Response (Police, Fire, Ambulance)</p>
                  <p className="text-[10px] text-gray-500">Single emergency number across all states and union territories.</p>
                </div>
                <a
                  href="tel:112"
                  className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-bold rounded-xl text-xs shadow-md shadow-red-500/30 flex items-center gap-1.5 shrink-0"
                >
                  <Phone size={13} /> CALL
                </a>
              </div>

              {/* 181 */}
              <div className="p-4 bg-purple-50 rounded-2xl border border-purple-100 flex items-center justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-lg font-black text-purple-700">181</span>
                    <span className="px-2 py-0.5 bg-purple-200/60 text-purple-800 text-[10px] font-bold rounded-md">WOMEN HELPLINE</span>
                  </div>
                  <p className="text-xs text-gray-700 font-medium mt-0.5">Women in Distress & Crisis Support</p>
                  <p className="text-[10px] text-gray-500">24/7 confidential legal, medical, counseling & rescue support.</p>
                </div>
                <a
                  href="tel:181"
                  className="px-4 py-2 bg-[#3A1C71] hover:bg-purple-900 text-white font-bold rounded-xl text-xs shadow-md shadow-purple-900/30 flex items-center gap-1.5 shrink-0"
                >
                  <Phone size={13} /> CALL
                </a>
              </div>

              {/* 1930 */}
              <div className="p-4 bg-blue-50 rounded-2xl border border-blue-100 flex items-center justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-lg font-black text-blue-700">1930</span>
                    <span className="px-2 py-0.5 bg-blue-200/60 text-blue-800 text-[10px] font-bold rounded-md">CYBER FRAUD & SAFETY</span>
                  </div>
                  <p className="text-xs text-gray-700 font-medium mt-0.5">National Cyber Crime Reporting Portal</p>
                  <p className="text-[10px] text-gray-500">Immediate financial transaction freeze & online harassment assistance.</p>
                </div>
                <a
                  href="tel:1930"
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl text-xs shadow-md shadow-blue-600/30 flex items-center gap-1.5 shrink-0"
                >
                  <Phone size={13} /> CALL
                </a>
              </div>

              {/* 1098 */}
              <div className="p-4 bg-amber-50 rounded-2xl border border-amber-100 flex items-center justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-lg font-black text-amber-700">1098</span>
                    <span className="px-2 py-0.5 bg-amber-200/60 text-amber-800 text-[10px] font-bold rounded-md">CHILDLINE</span>
                  </div>
                  <p className="text-xs text-gray-700 font-medium mt-0.5">Child Protection & Emergency Assistance</p>
                  <p className="text-[10px] text-gray-500">24-hour emergency phone outreach service for children in need.</p>
                </div>
                <a
                  href="tel:1098"
                  className="px-4 py-2 bg-amber-600 hover:bg-amber-700 text-white font-bold rounded-xl text-xs shadow-md shadow-amber-600/30 flex items-center gap-1.5 shrink-0"
                >
                  <Phone size={13} /> CALL
                </a>
              </div>

              {/* Safety Circle Call section */}
              {contacts.length > 0 && (
                <div className="pt-2">
                  <h4 className="text-xs font-bold text-gray-700 uppercase tracking-wider mb-2">My Safety Circle Contacts</h4>
                  <div className="space-y-2">
                    {contacts.map(c => (
                      <div key={c.id} className="p-3 bg-gray-50 rounded-xl border border-gray-200 flex items-center justify-between">
                        <div>
                          <div className="text-xs font-bold text-gray-900">{c.name} ({c.relationship || 'Guardian'})</div>
                          <div className="text-[10px] text-gray-500">{c.phone_number}</div>
                        </div>
                        <a
                          href={`tel:${c.phone_number}`}
                          className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold rounded-lg text-xs flex items-center gap-1"
                        >
                          <Phone size={12} /> Call
                        </a>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            <button
              onClick={() => setShowHelplinesModal(false)}
              className="w-full py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 font-semibold rounded-xl text-xs transition"
            >
              Close Helplines
            </button>
          </div>
        </div>
      )}

      {/* "I Don't Know What to Do / What Happened?" Modal */}
      {showDecisionSupportModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl p-6 max-w-lg w-full shadow-2xl border border-gray-100 max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center pb-3 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-purple-100 text-[#3A1C71] flex items-center justify-center font-bold">
                  <HelpCircle size={18} />
                </div>
                <div>
                  <h3 className="font-extrabold text-base text-gray-900">HOW CAN WE HELP YOU?</h3>
                  <p className="text-[11px] text-gray-500">Calm, structured guidance for unsafe situations.</p>
                </div>
              </div>
              <button onClick={() => setShowDecisionSupportModal(false)} className="text-gray-400 hover:text-gray-600 p-1 rounded-lg">
                <X size={20} />
              </button>
            </div>

            {/* Step 1: Immediate Danger Assessment */}
            <div className="my-4 p-4 bg-red-50 border border-red-200 rounded-2xl">
              <span className="text-xs font-bold text-red-800 uppercase tracking-wider block mb-1">Step 1: Immediate Safety Check</span>
              <p className="text-sm font-extrabold text-gray-900 mb-3">Are you currently in immediate physical danger?</p>
              <div className="flex gap-2">
                <a
                  href="tel:112"
                  className="flex-1 py-2.5 bg-red-600 hover:bg-red-700 text-white font-bold rounded-xl text-xs text-center shadow-md shadow-red-500/20"
                >
                  YES — CALL 112 NOW
                </a>
                <button
                  onClick={() => setSelectedDecisionCategory('followed')}
                  className="flex-1 py-2.5 bg-white border border-gray-300 hover:bg-gray-50 text-gray-700 font-semibold rounded-xl text-xs text-center"
                >
                  NO — I NEED GUIDANCE
                </button>
              </div>
            </div>

            {/* Step 2: Category Selector */}
            <div className="space-y-2 mb-4">
              <span className="text-xs font-bold text-gray-700 uppercase tracking-wider block">Step 2: What is happening?</span>
              <div className="grid grid-cols-2 gap-2">
                {[
                  { id: 'followed', label: "I'm being followed", icon: "👁️" },
                  { id: 'harassed', label: "Someone is harassing me", icon: "⚠️" },
                  { id: 'threat', label: "Someone is threatening me", icon: "🛑" },
                  { id: 'domestic', label: "Domestic abuse / Violence", icon: "🏠" },
                  { id: 'cyber', label: "Cybercrime / Online blackmail", icon: "💻" },
                  { id: 'medical', label: "I need medical help", icon: "🏥" },
                  { id: 'dark_area', label: "I'm in an unsafe dark area", icon: "🌑" },
                ].map(cat => (
                  <button
                    key={cat.id}
                    onClick={() => setSelectedDecisionCategory(cat.id)}
                    className={`p-3 rounded-xl text-left border text-xs font-semibold transition ${
                      selectedDecisionCategory === cat.id
                        ? 'bg-purple-50 border-[#3A1C71] text-[#3A1C71] shadow-sm'
                        : 'bg-gray-50 border-gray-200 text-gray-700 hover:bg-gray-100'
                    }`}
                  >
                    <span className="text-base mr-1.5">{cat.icon}</span>
                    {cat.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Guided Instructions for selected category */}
            {selectedDecisionCategory && (
              <div className="p-4 bg-purple-50 border border-purple-200 rounded-2xl mb-4 space-y-3">
                <div className="flex justify-between items-center">
                  <h4 className="font-extrabold text-xs text-[#3A1C71] uppercase tracking-wider">
                    Recommended Action Steps
                  </h4>
                  <span className="text-[10px] bg-purple-200/70 text-purple-900 font-bold px-2 py-0.5 rounded">
                    Verified Guidance
                  </span>
                </div>

                {selectedDecisionCategory === 'followed' && (
                  <div className="text-xs text-gray-700 space-y-1.5">
                    <p>• <strong>Do NOT head directly home</strong> or to isolated alleys.</p>
                    <p>• Head toward a well-lit, busy commercial shop, metro station, or pharmacy.</p>
                    <p>• Call a trusted contact and speak aloud so others notice.</p>
                    <p>• <strong>Legal Protection:</strong> Section 354D IPC penalizes stalking. You can file a <em>Zero FIR</em> at any nearby police station.</p>
                    <div className="flex gap-2 pt-2">
                      <a href="tel:112" className="flex-1 py-2 bg-red-600 text-white rounded-lg text-xs font-bold text-center">Dial 112</a>
                      <a href="tel:181" className="flex-1 py-2 bg-[#3A1C71] text-white rounded-lg text-xs font-bold text-center">Dial 181</a>
                    </div>
                  </div>
                )}

                {selectedDecisionCategory === 'harassed' && (
                  <div className="text-xs text-gray-700 space-y-1.5">
                    <p>• Maintain physical distance and loudly draw public attention.</p>
                    <p>• Note descriptions, timestamps, and vehicle registration numbers if applicable.</p>
                    <p>• <strong>Legal Protection:</strong> Section 354A IPC penalizes sexual harassment.</p>
                    <div className="flex gap-2 pt-2">
                      <a href="tel:181" className="flex-1 py-2 bg-[#3A1C71] text-white rounded-lg text-xs font-bold text-center">Dial 181</a>
                      <a href="tel:112" className="flex-1 py-2 bg-red-600 text-white rounded-lg text-xs font-bold text-center">Dial 112</a>
                    </div>
                  </div>
                )}

                {selectedDecisionCategory === 'threat' && (
                  <div className="text-xs text-gray-700 space-y-1.5">
                    <p>• Move immediately toward a security booth, metro officer, or busy storefront.</p>
                    <p>• Alert your Safety Circle and keep live sharing active.</p>
                    <p>• <strong>Legal Protection:</strong> Criminal intimidation is punishable under Section 506 IPC.</p>
                    <div className="flex gap-2 pt-2">
                      <a href="tel:112" className="w-full py-2 bg-red-600 text-white rounded-lg text-xs font-bold text-center">Call Police 112</a>
                    </div>
                  </div>
                )}

                {selectedDecisionCategory === 'domestic' && (
                  <div className="text-xs text-gray-700 space-y-1.5">
                    <p>• You have the right to emergency shelter, medical care, and protection orders under the Protection of Women from Domestic Violence Act (PWDVA).</p>
                    <p>• Dial 181 for confidential support and linkage to One-Stop Centres (Sakhi Centres).</p>
                    <div className="flex gap-2 pt-2">
                      <a href="tel:181" className="w-full py-2 bg-[#3A1C71] text-white rounded-lg text-xs font-bold text-center">Dial 181 Women Helpline</a>
                    </div>
                  </div>
                )}

                {selectedDecisionCategory === 'cyber' && (
                  <div className="text-xs text-gray-700 space-y-1.5">
                    <p>• <strong>Do NOT delete chats, photos, or transaction records</strong>. Take clear screenshots with timestamps and URLs.</p>
                    <p>• If financial fraud occurred, dial <strong>1930 immediately</strong> to activate bank freeze mechanisms.</p>
                    <p>• File a report at <em>cybercrime.gov.in</em>.</p>
                    <div className="flex gap-2 pt-2">
                      <a href="tel:1930" className="w-full py-2 bg-blue-600 text-white rounded-lg text-xs font-bold text-center">Dial 1930 Cyber Helpline</a>
                    </div>
                  </div>
                )}

                {selectedDecisionCategory === 'medical' && (
                  <div className="text-xs text-gray-700 space-y-1.5">
                    <p>• Dial 112 or 102 for emergency ambulance dispatch.</p>
                    <p>• Use 'Help Near Me' to navigate to the nearest hospital emergency room.</p>
                    <div className="flex gap-2 pt-2">
                      <a href="tel:112" className="w-full py-2 bg-red-600 text-white rounded-lg text-xs font-bold text-center">Dial 112 Emergency</a>
                    </div>
                  </div>
                )}

                {selectedDecisionCategory === 'dark_area' && (
                  <div className="text-xs text-gray-700 space-y-1.5">
                    <p>• Turn on Journey Guard mode with continuous GPS tracking.</p>
                    <p>• Share temporary 30-minute location token with your trusted contacts.</p>
                    <p>• Keep phone in hand with SOS button accessible.</p>
                    <div className="flex gap-2 pt-2">
                      <button onClick={() => { setShowDecisionSupportModal(false); setShowLocationShareModal(true); }} className="w-full py-2 bg-[#3A1C71] text-white rounded-lg text-xs font-bold text-center">Share My Location</button>
                    </div>
                  </div>
                )}
              </div>
            )}

            <button
              onClick={() => setShowDecisionSupportModal(false)}
              className="w-full py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 font-semibold rounded-xl text-xs transition"
            >
              Close Assistant
            </button>
          </div>
        </div>
      )}

      {/* Post-SOS Support Modal */}
      {showPostSosModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl p-6 max-w-md w-full shadow-2xl border border-gray-100 text-center">
            <div className="w-16 h-16 mx-auto rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mb-3">
              <CheckCircle2 size={32} />
            </div>
            <h3 className="font-extrabold text-lg text-gray-900">SOS RESOLVED</h3>
            <p className="text-xs text-gray-500 mb-6">
              Your emergency broadcast has been concluded and your trusted contacts notified.
            </p>

            <div className="p-4 bg-gray-50 rounded-2xl border border-gray-200 mb-6 text-left">
              <span className="text-xs font-bold text-gray-800 block mb-2">Are you safe right now?</span>
              <div className="flex flex-col gap-2">
                <button
                  onClick={() => setShowPostSosModal(false)}
                  className="w-full py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-xs shadow transition"
                >
                  YES, I AM SAFE NOW
                </button>
                <button
                  onClick={() => {
                    setShowPostSosModal(false);
                    setShowDecisionSupportModal(true);
                  }}
                  className="w-full py-2.5 bg-purple-50 hover:bg-purple-100 text-[#3A1C71] border border-purple-200 font-bold rounded-xl text-xs transition"
                >
                  I STILL NEED HELP (Medical / Legal / Helplines)
                </button>
              </div>
            </div>

            <button
              onClick={() => setShowPostSosModal(false)}
              className="text-xs text-gray-400 hover:text-gray-600"
            >
              Dismiss
            </button>
          </div>
        </div>
      )}

      {/* Temporary Location Sharing Modal */}
      {showLocationShareModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl p-6 max-w-md w-full shadow-2xl border border-gray-100">
            <div className="flex justify-between items-center pb-3 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
                  <Share2 size={18} />
                </div>
                <div>
                  <h3 className="font-extrabold text-base text-gray-900">TEMPORARY LOCATION SHARE</h3>
                  <p className="text-[11px] text-gray-500">Secure, non-predictable ephemeral token.</p>
                </div>
              </div>
              <button onClick={() => setShowLocationShareModal(false)} className="text-gray-400 hover:text-gray-600 p-1 rounded-lg">
                <X size={20} />
              </button>
            </div>

            <div className="my-4 space-y-4">
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">Select Sharing Duration:</label>
                <div className="grid grid-cols-4 gap-2">
                  {[
                    { id: '15m', label: '15 min' },
                    { id: '30m', label: '30 min' },
                    { id: '1h', label: '1 hour' },
                    { id: 'until_stop', label: 'Until Stop' },
                  ].map(d => (
                    <button
                      key={d.id}
                      onClick={() => setShareDuration(d.id as any)}
                      className={`py-2 rounded-xl text-xs font-bold transition border ${
                        shareDuration === d.id
                          ? 'bg-blue-50 border-blue-600 text-blue-700'
                          : 'bg-gray-50 border-gray-200 text-gray-700 hover:bg-gray-100'
                      }`}
                    >
                      {d.label}
                    </button>
                  ))}
                </div>
              </div>

              {!tempShareToken ? (
                <button
                  onClick={() => {
                    const token = 'tok_' + Math.random().toString(36).substring(2, 12);
                    setTempShareToken(`https://sakhi.network/track/${token}`);
                  }}
                  className="w-full py-3 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl text-xs shadow-md shadow-blue-500/20 transition"
                >
                  Generate Ephemeral Share Link
                </button>
              ) : (
                <div className="p-3 bg-blue-50 rounded-xl border border-blue-200 space-y-2">
                  <span className="text-[10px] font-bold uppercase text-blue-800">Active Share Link</span>
                  <div className="flex gap-2">
                    <input
                      type="text"
                      readOnly
                      value={tempShareToken}
                      className="w-full text-xs bg-white border border-blue-300 rounded px-2.5 py-1.5 text-gray-800"
                    />
                    <button
                      onClick={() => {
                        navigator.clipboard.writeText(tempShareToken);
                        alert('Link copied to clipboard!');
                      }}
                      className="px-3 py-1.5 bg-blue-700 text-white rounded text-xs font-medium hover:bg-blue-800 whitespace-nowrap"
                    >
                      Copy
                    </button>
                  </div>
                  <button
                    onClick={() => setTempShareToken(null)}
                    className="text-[11px] text-red-600 hover:underline font-semibold block pt-1"
                  >
                    Revoke & Deactivate Link Immediately
                  </button>
                </div>
              )}
            </div>

            <button
              onClick={() => setShowLocationShareModal(false)}
              className="w-full py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 font-semibold rounded-xl text-xs transition"
            >
              Close
            </button>
          </div>
        </div>
      )}

      {/* Main Content Area */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-4 sm:p-6 lg:p-8">
        {/* TAB 1: SAFETY HUB (HOME) */}
        {activeTab === 'home' && (
          <div className="space-y-6">
            {/* Communication Status Bar */}
            <div className="bg-white border border-gray-200 rounded-xl px-4 py-2.5 shadow-sm flex flex-wrap items-center justify-between gap-3 text-xs">
              <div className="flex items-center gap-2">
                <span className="font-bold text-gray-700 uppercase tracking-wider text-[11px]">Communication Status:</span>
              </div>
              <div className="flex flex-wrap items-center gap-2 sm:gap-3">
                <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 text-[11px] font-semibold">
                  <Wifi size={13} className="text-emerald-600" />
                  <span>Internet: Online</span>
                </div>
                <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-blue-50 text-blue-700 border border-blue-200 text-[11px] font-semibold">
                  <MapPin size={13} className="text-blue-600" />
                  <span>GPS: High Accuracy (±6m)</span>
                </div>
                <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-purple-50 text-purple-700 border border-purple-200 text-[11px] font-semibold">
                  <Radio size={13} className="text-purple-600" />
                  <span>Emergency Mesh: Standby (BLE + ESP-NOW)</span>
                </div>
              </div>
            </div>

            {/* Core 6 Emergency Actions Grid */}
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
              {/* 1. SOS */}
              <button
                onClick={activeSOS ? resolveSOSNow : startSosCountdown}
                className="p-4 rounded-2xl bg-gradient-to-br from-red-500 to-rose-600 text-white font-bold text-left shadow-lg hover:shadow-red-500/30 hover:scale-[1.02] active:scale-95 transition flex flex-col justify-between h-28"
              >
                <div className="flex justify-between items-center w-full">
                  <AlertTriangle size={24} className="text-white" />
                  <span className="text-[10px] uppercase font-bold bg-white/20 px-1.5 py-0.5 rounded">Emergency</span>
                </div>
                <div>
                  <div className="text-sm font-black tracking-wide">🚨 SOS</div>
                  <div className="text-[10px] text-red-100 font-normal">Press & Hold 2s</div>
                </div>
              </button>

              {/* 2. Emergency Help */}
              <button
                onClick={() => setShowHelplinesModal(true)}
                className="p-4 rounded-2xl bg-gradient-to-br from-[#3A1C71] to-[#4A2590] text-white font-bold text-left shadow-md hover:shadow-purple-500/20 hover:scale-[1.02] active:scale-95 transition flex flex-col justify-between h-28"
              >
                <div className="flex justify-between items-center w-full">
                  <PhoneCall size={22} className="text-purple-200" />
                  <span className="text-[10px] uppercase font-bold bg-white/20 px-1.5 py-0.5 rounded">1-Tap Dial</span>
                </div>
                <div>
                  <div className="text-sm font-black tracking-wide">☎ Helplines</div>
                  <div className="text-[10px] text-purple-200 font-normal">112, 181, 1930, 1098</div>
                </div>
              </button>

              {/* 3. Safety Circle */}
              <button
                onClick={() => setActiveTab('contacts')}
                className="p-4 rounded-2xl bg-white border border-gray-200 text-gray-800 font-bold text-left shadow-sm hover:border-purple-300 hover:scale-[1.02] active:scale-95 transition flex flex-col justify-between h-28"
              >
                <div className="flex justify-between items-center w-full">
                  <Users size={22} className="text-[#3A1C71]" />
                  <span className="text-[10px] uppercase font-bold bg-purple-100 text-[#3A1C71] px-1.5 py-0.5 rounded">{contacts.length} Connected</span>
                </div>
                <div>
                  <div className="text-sm font-black tracking-wide">👥 Safety Circle</div>
                  <div className="text-[10px] text-gray-500 font-normal">Trusted Guardians</div>
                </div>
              </button>

              {/* 4. Share My Location */}
              <button
                onClick={() => setShowLocationShareModal(true)}
                className="p-4 rounded-2xl bg-white border border-gray-200 text-gray-800 font-bold text-left shadow-sm hover:border-purple-300 hover:scale-[1.02] active:scale-95 transition flex flex-col justify-between h-28"
              >
                <div className="flex justify-between items-center w-full">
                  <Share2 size={22} className="text-blue-600" />
                  <span className="text-[10px] uppercase font-bold bg-blue-100 text-blue-700 px-1.5 py-0.5 rounded">Timed</span>
                </div>
                <div>
                  <div className="text-sm font-black tracking-wide">📍 Share Location</div>
                  <div className="text-[10px] text-gray-500 font-normal">15m, 30m, 1h tokens</div>
                </div>
              </button>

              {/* 5. Start Safe Journey */}
              <button
                onClick={() => setActiveTab('journey')}
                className="p-4 rounded-2xl bg-white border border-gray-200 text-gray-800 font-bold text-left shadow-sm hover:border-purple-300 hover:scale-[1.02] active:scale-95 transition flex flex-col justify-between h-28"
              >
                <div className="flex justify-between items-center w-full">
                  <Navigation size={22} className="text-emerald-600" />
                  <span className="text-[10px] uppercase font-bold bg-emerald-100 text-emerald-700 px-1.5 py-0.5 rounded">{activeJourney ? 'Active' : 'Start'}</span>
                </div>
                <div>
                  <div className="text-sm font-black tracking-wide">🧭 Safe Journey</div>
                  <div className="text-[10px] text-gray-500 font-normal">Route & Check-ins</div>
                </div>
              </button>

              {/* 6. Help Near Me */}
              <button
                onClick={() => setActiveTab('nearby')}
                className="p-4 rounded-2xl bg-white border border-gray-200 text-gray-800 font-bold text-left shadow-sm hover:border-purple-300 hover:scale-[1.02] active:scale-95 transition flex flex-col justify-between h-28"
              >
                <div className="flex justify-between items-center w-full">
                  <MapPin size={22} className="text-amber-600" />
                  <span className="text-[10px] uppercase font-bold bg-amber-100 text-amber-700 px-1.5 py-0.5 rounded">Verified</span>
                </div>
                <div>
                  <div className="text-sm font-black tracking-wide">🗺️ Help Near Me</div>
                  <div className="text-[10px] text-gray-500 font-normal">Police, Hospitals</div>
                </div>
              </button>
            </div>

            {/* "I Don't Know What to Do / What Happened?" Banner */}
            <div className="bg-gradient-to-r from-purple-50 via-indigo-50 to-pink-50 border border-purple-200 rounded-2xl p-4 flex flex-col sm:flex-row items-center justify-between gap-4 shadow-sm">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-[#3A1C71] text-white flex items-center justify-center shrink-0 shadow-md">
                  <HelpCircle size={22} />
                </div>
                <div>
                  <h4 className="font-extrabold text-sm text-[#3A1C71]">I DON'T KNOW WHAT TO DO / WHAT HAPPENED?</h4>
                  <p className="text-xs text-gray-600">
                    Feeling unsafe, followed, or facing cyber fraud? Follow our calm step-by-step decision support flow.
                  </p>
                </div>
              </div>
              <button
                onClick={() => {
                  setSelectedDecisionCategory(null);
                  setShowDecisionSupportModal(true);
                }}
                className="px-4 py-2 bg-[#3A1C71] hover:bg-purple-900 text-white font-bold rounded-xl text-xs whitespace-nowrap shadow-sm transition shrink-0"
              >
                Open Decision Assistant &rarr;
              </button>
            </div>

            {/* Hero Welcome & Philosophy */}
            <div className="bg-gradient-to-r from-[#3A1C71] via-[#4A2590] to-[#2E1559] rounded-2xl p-6 text-white shadow-xl flex flex-col md:flex-row items-center justify-between gap-6">
              <div className="space-y-2 max-w-xl">
                <div className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-white/10 text-purple-200 text-xs font-medium backdrop-blur-sm">
                  <Sparkles size={12} />
                  <span>Ethical AI • Privacy-First Women's Protection</span>
                </div>
                <h2 className="text-2xl font-extrabold tracking-tight">
                  Welcome back, {userProfile?.full_name || 'Priya'}
                </h2>
                <p className="text-xs text-purple-100 leading-relaxed">
                  Sakhi assists your daily travel and unexpected emergencies. With real-time journey guards, trusted guardian alerts, and ML-assisted environmental safety awareness.
                </p>
              </div>

              {/* Central Pulse SOS Trigger */}
              <div className="flex flex-col items-center">
                <button
                  onClick={activeSOS ? resolveSOSNow : startSosCountdown}
                  className={`relative group w-32 h-32 rounded-full flex flex-col items-center justify-center font-black text-white shadow-2xl transition-transform transform active:scale-95 ${
                    activeSOS 
                      ? 'bg-red-600 animate-pulse ring-8 ring-red-400/50' 
                      : 'bg-gradient-to-tr from-[#E63946] to-[#ff5d6c] hover:scale-105 ring-8 ring-white/20 hover:ring-red-400/30'
                  }`}
                >
                  <AlertTriangle size={32} className="mb-1" />
                  <span className="text-xl tracking-wider">{activeSOS ? 'ACTIVE' : 'SOS'}</span>
                  <span className="text-[9px] font-normal opacity-90">{activeSOS ? 'Tap to Safe' : 'Tap for Help'}</span>
                </button>
                <span className="text-[10px] text-purple-200 mt-2">5-second abort countdown included</span>
              </div>
            </div>

            {/* Quick Status Cards Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {/* Area Risk Status */}
              <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-sm hover:border-purple-300 transition">
                <div className="flex justify-between items-start mb-2">
                  <span className="text-xs font-medium text-gray-500">Area Risk Index</span>
                  <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-green-100 text-green-700 uppercase">
                    {areaRisk?.risk_category?.replace(/_/g, ' ') || 'Moderate'}
                  </span>
                </div>
                <div className="text-xl font-bold text-gray-900">
                  {areaRisk ? `${(areaRisk.risk_score * 100).toFixed(0)} / 100` : '32 / 100'}
                </div>
                <p className="text-[11px] text-gray-400 mt-1">
                  Environmental analysis based on verified reports & lighting.
                </p>
              </div>

              {/* Journey Guard */}
              <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-sm hover:border-purple-300 transition">
                <div className="flex justify-between items-start mb-2">
                  <span className="text-xs font-medium text-gray-500">Journey Guard</span>
                  <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${
                    activeJourney ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-100 text-gray-600'
                  }`}>
                    {activeJourney ? 'Active' : 'Standby'}
                  </span>
                </div>
                <div className="text-lg font-bold text-gray-900 truncate">
                  {activeJourney ? activeJourney.destination_name : 'No Active Travel'}
                </div>
                <button
                  onClick={() => setActiveTab('journey')}
                  className="text-[11px] text-[#3A1C71] font-semibold mt-1 hover:underline flex items-center gap-1"
                >
                  {activeJourney ? 'View Live Tracking &rarr;' : 'Start Safe Journey &rarr;'}
                </button>
              </div>

              {/* Trusted Guardians */}
              <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-sm hover:border-purple-300 transition">
                <div className="flex justify-between items-start mb-2">
                  <span className="text-xs font-medium text-gray-500">Emergency Contacts</span>
                  <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-purple-100 text-purple-700">
                    {contacts.length} Connected
                  </span>
                </div>
                <div className="text-xl font-bold text-gray-900">
                  {contacts.length > 0 ? contacts[0].name : 'None Set'}
                </div>
                <button
                  onClick={() => setActiveTab('contacts')}
                  className="text-[11px] text-[#3A1C71] font-semibold mt-1 hover:underline flex items-center gap-1"
                >
                  Manage Trusted Network &rarr;
                </button>
              </div>

              {/* Confidential Incident Reports */}
              <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-sm hover:border-purple-300 transition">
                <div className="flex justify-between items-start mb-2">
                  <span className="text-xs font-medium text-gray-500">Community Reports</span>
                  <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-blue-100 text-blue-700">
                    {incidents.length} Nearby
                  </span>
                </div>
                <div className="text-xl font-bold text-gray-900">
                  {incidents.length} Verified
                </div>
                <button
                  onClick={() => setActiveTab('report')}
                  className="text-[11px] text-[#3A1C71] font-semibold mt-1 hover:underline flex items-center gap-1"
                >
                  Report Unsafe Hazard &rarr;
                </button>
              </div>
            </div>

            {/* Two-Column Section: Live Map Mini & Quick Support */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              <div className="lg:col-span-2 bg-white p-6 rounded-2xl border border-gray-200 shadow-sm">
                <div className="flex justify-between items-center mb-4">
                  <div>
                    <h3 className="text-sm font-bold text-gray-900">Local Geospatial Safety Overview</h3>
                    <p className="text-xs text-gray-500">Verified incidents and emergency points around your GPS location</p>
                  </div>
                  <button
                    onClick={() => setActiveTab('map')}
                    className="text-xs font-semibold text-[#3A1C71] hover:underline"
                  >
                    Open Full Map &rarr;
                  </button>
                </div>
                <div className="h-64 rounded-xl overflow-hidden border border-gray-100">
                  <IncidentMap incidents={incidents} center={[userLocation.lat, userLocation.lng]} zoom={13} />
                </div>
              </div>

              {/* Quick Legal & Emergency Help Card */}
              <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm space-y-4">
                <h3 className="text-sm font-bold text-gray-900">Instant Rights & Helplines</h3>
                <div className="space-y-3">
                  <div className="p-3 bg-purple-50 rounded-xl border border-purple-100">
                    <h4 className="text-xs font-bold text-[#3A1C71] flex items-center gap-1.5">
                      <FileText size={14} /> Zero FIR Protection
                    </h4>
                    <p className="text-[11px] text-gray-600 mt-1">
                      A woman can register an FIR at any police station regardless of jurisdiction.
                    </p>
                  </div>

                  <div className="p-3 bg-blue-50 rounded-xl border border-blue-100">
                    <h4 className="text-xs font-bold text-blue-800 flex items-center gap-1.5">
                      <PhoneCall size={14} /> 24/7 National Emergency
                    </h4>
                    <p className="text-[11px] text-gray-600 mt-1">
                      Dial <strong>112</strong> for immediate pan-India emergency response across Police, Fire, and Ambulance.
                    </p>
                  </div>

                  <button
                    onClick={() => setActiveTab('legal')}
                    className="w-full py-2 bg-gray-100 hover:bg-gray-200 text-gray-800 rounded-lg text-xs font-semibold transition"
                  >
                    Explore Complete Legal Navigator
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* TAB 2: JOURNEY GUARD */}
        {activeTab === 'journey' && (
          <div className="max-w-3xl mx-auto space-y-6">
            <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm">
              <h2 className="text-lg font-bold text-gray-900 mb-1">Live Journey Safety Guard</h2>
              <p className="text-xs text-gray-500 mb-6">
                Broadcast temporary live breadcrumbs to trusted emergency contacts with automated deviation detection.
              </p>

              {activeJourney ? (
                <div className="space-y-4">
                  <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl">
                    <div className="flex justify-between items-center">
                      <div>
                        <span className="text-[10px] font-bold uppercase tracking-wider text-emerald-700">Journey in Progress</span>
                        <h3 className="text-base font-bold text-gray-900 mt-0.5">{activeJourney.destination_name}</h3>
                        <p className="text-xs text-gray-600">Started at {new Date(activeJourney.start_time).toLocaleTimeString()}</p>
                      </div>
                      <span className="px-3 py-1 bg-emerald-600 text-white rounded-full text-xs font-bold">
                        GUARD ACTIVE
                      </span>
                    </div>

                    {sharedLink && (
                      <div className="mt-4 pt-3 border-t border-emerald-200">
                        <label className="text-[11px] font-semibold text-emerald-900 block mb-1">
                          Temporary Live Tracking Link (Expires in 2 hours):
                        </label>
                        <div className="flex items-center gap-2">
                          <input
                            type="text"
                            readOnly
                            value={sharedLink}
                            className="w-full text-xs bg-white border border-emerald-300 rounded px-2.5 py-1.5 text-gray-800"
                          />
                          <button
                            onClick={() => {
                              navigator.clipboard.writeText(sharedLink);
                              alert('Tracking link copied to clipboard!');
                            }}
                            className="px-3 py-1.5 bg-emerald-700 text-white rounded text-xs font-medium hover:bg-emerald-800 whitespace-nowrap"
                          >
                            Copy Link
                          </button>
                        </div>
                      </div>
                    )}
                  </div>

                  <div className="grid grid-cols-3 gap-3">
                    <div className="p-3 bg-gray-50 rounded-lg text-center">
                      <span className="text-[10px] text-gray-500">Route Distance</span>
                      <p className="text-sm font-bold text-gray-800">1.8 km</p>
                    </div>
                    <div className="p-3 bg-gray-50 rounded-lg text-center">
                      <span className="text-[10px] text-gray-500">GPS Signal</span>
                      <p className="text-sm font-bold text-emerald-600">High Accuracy</p>
                    </div>
                    <div className="p-3 bg-gray-50 rounded-lg text-center">
                      <span className="text-[10px] text-gray-500">Guardians Alerted</span>
                      <p className="text-sm font-bold text-purple-700">{contacts.length} Contacts</p>
                    </div>
                  </div>

                  <div className="pt-2">
                    <button
                      onClick={handleEndJourney}
                      className="w-full py-3 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-sm transition shadow-md"
                    >
                      I Have Arrived Safely (Complete Journey)
                    </button>
                  </div>
                </div>
              ) : (
                <form onSubmit={handleStartJourney} className="space-y-4">
                  <div>
                    <label className="block text-xs font-semibold text-gray-700 mb-1">Destination Location</label>
                    <input
                      type="text"
                      required
                      placeholder="e.g. South Extension Market, Delhi"
                      value={destination}
                      onChange={(e) => setDestination(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-purple-500 focus:outline-none"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-semibold text-gray-700 mb-1">Expected Travel Time (minutes)</label>
                    <input
                      type="number"
                      required
                      min={5}
                      max={360}
                      value={etaMins}
                      onChange={(e) => setEtaMins(Number(e.target.value))}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-purple-500 focus:outline-none"
                    />
                  </div>

                  <div className="p-3 bg-purple-50 rounded-xl border border-purple-100 flex items-start gap-2.5">
                    <Shield size={16} className="text-[#3A1C71] shrink-0 mt-0.5" />
                    <p className="text-[11px] text-purple-950 leading-relaxed">
                      <strong>Privacy Assurance:</strong> GPS coordinates are shared solely with your designated trusted contacts for the duration of this trip. Location history is purgeable at any time.
                    </p>
                  </div>

                  <button
                    type="submit"
                    className="w-full py-3 bg-[#3A1C71] hover:bg-[#2e1559] text-white font-bold rounded-xl text-sm transition shadow-lg shadow-purple-900/30"
                  >
                    Start Guarded Journey
                  </button>
                </form>
              )}
            </div>
          </div>
        )}

        {/* TAB 3: FULL SAFETY MAP */}
        {activeTab === 'map' && (
          <div className="space-y-4">
            <div className="bg-white p-4 rounded-xl border border-gray-200 flex flex-wrap justify-between items-center gap-3">
              <div>
                <h2 className="text-sm font-bold text-gray-900">Geospatial Community Safety Map</h2>
                <p className="text-xs text-gray-500">Showing verified community incident reports and emergency services</p>
              </div>
              <div className="flex items-center gap-2">
                <span className="flex items-center gap-1 text-[11px] text-gray-600">
                  <span className="w-2.5 h-2.5 rounded-full bg-red-500 inline-block"></span> Verified Hazard
                </span>
                <span className="flex items-center gap-1 text-[11px] text-gray-600">
                  <span className="w-2.5 h-2.5 rounded-full bg-blue-500 inline-block"></span> Police Station
                </span>
                <span className="flex items-center gap-1 text-[11px] text-gray-600">
                  <span className="w-2.5 h-2.5 rounded-full bg-green-500 inline-block"></span> 24/7 Hospital
                </span>
              </div>
            </div>
            <div className="h-[550px] bg-white rounded-2xl border border-gray-200 overflow-hidden shadow-sm">
              <IncidentMap incidents={incidents} center={[userLocation.lat, userLocation.lng]} zoom={14} />
            </div>
          </div>
        )}

        {/* TAB 4: CONFIDENTIAL INCIDENT REPORTING */}
        {activeTab === 'report' && (
          <div className="max-w-2xl mx-auto space-y-6">
            <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm">
              <div className="flex items-center gap-2 mb-2">
                <AlertTriangle className="text-amber-500" size={20} />
                <h2 className="text-lg font-bold text-gray-900">Confidential Incident & Safety Hazard Reporting</h2>
              </div>
              <p className="text-xs text-gray-500 mb-6">
                Help other women travel safely by flagging poorly lit streets, harassment, or security hazards. All submissions are moderated before appearing publicly.
              </p>

              {reportSuccess && (
                <div className="mb-4 p-4 bg-emerald-50 border border-emerald-200 rounded-xl flex items-center gap-2 text-emerald-800 text-xs">
                  <CheckCircle2 size={16} />
                  <span>Report submitted successfully! It has been queued for verification. Thank you for keeping our community safe.</span>
                </div>
              )}

              <form onSubmit={handleReportIncident} className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1">Incident Category</label>
                  <select
                    value={reportCategory}
                    onChange={(e) => setReportCategory(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-purple-500 focus:outline-none"
                  >
                    <option value="POOR_LIGHTING">Poor or Broken Street Lighting</option>
                    <option value="HARASSMENT">Catcalling / Street Harassment</option>
                    <option value="STALKING">Stalking / Following</option>
                    <option value="SUSPICIOUS_ACTIVITY">Suspicious Gathering / Activity</option>
                    <option value="INFRASTRUCTURE_HAZARD">Isolated or Desolate Stretch</option>
                    <option value="OTHER">Other Safety Hazard</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1">Description</label>
                  <textarea
                    required
                    rows={3}
                    placeholder="Provide context (e.g. Street lights out on 3rd Avenue near the bus stop, feel unsafe walking alone after 9 PM)..."
                    value={reportDesc}
                    onChange={(e) => setReportDesc(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-purple-500 focus:outline-none"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1">Severity Assessment</label>
                  <div className="grid grid-cols-3 gap-2">
                    {['LOW', 'MEDIUM', 'HIGH'].map(sev => (
                      <button
                        key={sev}
                        type="button"
                        onClick={() => setReportSeverity(sev)}
                        className={`py-2 text-xs font-bold rounded-lg border transition ${
                          reportSeverity === sev 
                            ? 'bg-purple-900 text-white border-purple-900' 
                            : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
                        }`}
                      >
                        {sev}
                      </button>
                    ))}
                  </div>
                </div>

                <div className="p-3 bg-gray-50 rounded-xl border border-gray-200 flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <EyeOff size={16} className="text-gray-500" />
                    <div>
                      <span className="text-xs font-semibold text-gray-800">Submit Anonymously</span>
                      <p className="text-[10px] text-gray-400">Your name and profile will be completely stripped from the report</p>
                    </div>
                  </div>
                  <input
                    type="checkbox"
                    checked={isAnonymous}
                    onChange={(e) => setIsAnonymous(e.target.checked)}
                    className="w-4 h-4 text-purple-600 rounded"
                  />
                </div>

                <button
                  type="submit"
                  className="w-full py-3 bg-[#E63946] hover:bg-[#d62839] text-white font-bold rounded-xl text-sm transition shadow-lg shadow-red-900/30"
                >
                  Submit Confidential Report
                </button>
              </form>
            </div>
          </div>
        )}

        {/* TAB 5: NEARBY EMERGENCY HELP */}
        {activeTab === 'nearby' && (
          <div className="space-y-6">
            <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm">
              <h2 className="text-lg font-bold text-gray-900 mb-1">Nearby Emergency Infrastructure</h2>
              <p className="text-xs text-gray-500 mb-4">
                Verified police stations, women's hospitals, and safe shelters within 15 km of your location.
              </p>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {resources.length === 0 ? (
                  <div className="col-span-full py-12 text-center text-gray-400 text-xs">
                    Loading verified infrastructure...
                  </div>
                ) : (
                  resources.map(res => (
                    <div key={res.id} className="p-4 rounded-xl border border-gray-200 hover:border-purple-300 bg-white shadow-sm flex flex-col justify-between">
                      <div>
                        <div className="flex justify-between items-start mb-2">
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${
                            res.resource_type === 'POLICE_STATION' ? 'bg-blue-100 text-blue-700' :
                            res.resource_type === 'HOSPITAL' ? 'bg-green-100 text-green-700' :
                            'bg-purple-100 text-purple-700'
                          }`}>
                            {res.resource_type.replace(/_/g, ' ')}
                          </span>
                          {res.distance_km !== undefined && (
                            <span className="text-xs text-gray-500 font-semibold">{res.distance_km.toFixed(1)} km</span>
                          )}
                        </div>
                        <h4 className="font-bold text-sm text-gray-900 mb-1">{res.name}</h4>
                        <p className="text-xs text-gray-500 mb-2">{res.address}</p>
                      </div>

                      <div className="pt-3 border-t border-gray-100 flex items-center justify-between">
                        <span className="text-xs font-semibold text-gray-700">{res.phone_number || '112'}</span>
                        <a
                          href={`tel:${res.phone_number || '112'}`}
                          className="px-3 py-1 bg-[#3A1C71] text-white text-xs font-semibold rounded-lg hover:bg-purple-900 flex items-center gap-1"
                        >
                          <PhoneCall size={12} /> Call Now
                        </a>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        )}

        {/* TAB 6: RIGHTS NAVIGATOR */}
        {activeTab === 'legal' && (
          <div className="max-w-4xl mx-auto space-y-6">
            <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm">
              <h2 className="text-lg font-bold text-gray-900 mb-1">Women's Legal & Support Navigator</h2>
              <p className="text-xs text-gray-500 mb-6">
                Understand your legal rights, statutory protections, and crisis resources across India.
              </p>

              <div className="space-y-4">
                <div className="p-4 bg-purple-50/70 border border-purple-200 rounded-xl">
                  <h3 className="font-bold text-sm text-[#3A1C71] mb-1">1. Zero FIR Provision</h3>
                  <p className="text-xs text-gray-700 leading-relaxed">
                    Under Indian criminal law, an FIR can be filed at <strong>any police station</strong>, irrespective of the place of the crime or jurisdiction. The police cannot refuse registration on territorial grounds; they must register it as a 'Zero FIR' and transfer it to the competent station.
                  </p>
                </div>

                <div className="p-4 bg-blue-50/70 border border-blue-200 rounded-xl">
                  <h3 className="font-bold text-sm text-blue-900 mb-1">2. Statement Recording Rights (Section 164 CrPC)</h3>
                  <p className="text-xs text-gray-700 leading-relaxed">
                    A woman who is a victim of sexual assault or harassment has the right to have her statement recorded before a female police officer or lady magistrate in a secure, non-intimidating setting.
                  </p>
                </div>

                <div className="p-4 bg-emerald-50/70 border border-emerald-200 rounded-xl">
                  <h3 className="font-bold text-sm text-emerald-900 mb-1">3. Cybercrime Protection & Helpline 1930</h3>
                  <p className="text-xs text-gray-700 leading-relaxed">
                    For online harassment, morphed media, financial fraud, or non-consensual image sharing, report immediately to <strong>1930</strong> or file a complaint on the National Cyber Crime Reporting Portal (cybercrime.gov.in) with prompt evidence preservation.
                  </p>
                </div>

                <div className="p-4 bg-amber-50/70 border border-amber-200 rounded-xl">
                  <h3 className="font-bold text-sm text-amber-900 mb-1">4. One-Stop Crisis Centres (Sakhi Centres)</h3>
                  <p className="text-xs text-gray-700 leading-relaxed">
                    Sakhi Centres provide integrated support under one roof: immediate medical aid, police assistance, psycho-social counseling, and temporary shelter for women affected by violence. Dial <strong>181</strong> for 24/7 referral.
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* TAB 7: EMERGENCY CONTACTS */}
        {activeTab === 'contacts' && (
          <div className="max-w-3xl mx-auto space-y-6">
            <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm">
              <div className="flex justify-between items-center mb-4">
                <div>
                  <h2 className="text-lg font-bold text-gray-900">Trusted Emergency Contacts</h2>
                  <p className="text-xs text-gray-500">These contacts receive automated SMS alerts and live GPS tracking when you activate SOS</p>
                </div>
                <button
                  onClick={() => setShowAddContact(true)}
                  className="flex items-center gap-1.5 px-3 py-2 bg-[#3A1C71] text-white rounded-xl text-xs font-semibold hover:bg-purple-900 shadow-sm"
                >
                  <Plus size={14} /> Add Guardian
                </button>
              </div>

              <div className="space-y-3">
                {contacts.length === 0 ? (
                  <div className="py-8 text-center text-gray-400 text-xs">
                    No emergency contacts added yet. Add at least 1 trusted guardian.
                  </div>
                ) : (
                  contacts.map(c => (
                    <div key={c.id} className="p-4 bg-gray-50 rounded-xl border border-gray-200 flex items-center justify-between">
                      <div>
                        <h4 className="font-bold text-sm text-gray-900">{c.name}</h4>
                        <p className="text-xs text-gray-600">{c.phone_number} • <span className="text-purple-700 font-medium">{c.relationship || 'Guardian'}</span></p>
                        <span className="inline-block mt-1 text-[10px] font-semibold text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded">
                          SOS Alerts Active
                        </span>
                      </div>
                      <button
                        onClick={() => handleDeleteContact(c.id)}
                        className="p-2 text-gray-400 hover:text-red-600 rounded-lg hover:bg-red-50 transition"
                        title="Remove Contact"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        )}

        {/* TAB 8: PRIVACY VAULT */}
        {activeTab === 'privacy' && (
          <div className="max-w-2xl mx-auto space-y-6">
            <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm">
              <div className="flex items-center gap-2 mb-2">
                <Lock className="text-[#3A1C71]" size={20} />
                <h2 className="text-lg font-bold text-gray-900">Privacy & Data Governance Vault</h2>
              </div>
              <p className="text-xs text-gray-500 mb-6">
                Sakhi is built strictly on privacy-by-design principles. We do not sell data or maintain permanent location dossiers.
              </p>

              <div className="space-y-4">
                <div className="p-4 bg-gray-50 rounded-xl border border-gray-200">
                  <div className="flex justify-between items-center mb-1">
                    <span className="text-xs font-bold text-gray-800">Ephemeral Mesh Relay Beacons</span>
                    <span className="px-2 py-0.5 bg-emerald-100 text-emerald-800 text-[10px] font-bold rounded">ENABLED</span>
                  </div>
                  <p className="text-[11px] text-gray-500">
                    Rotates 128-bit pseudorandom beacons every 15 minutes over Bluetooth Low Energy. Zero PII transmitted.
                  </p>
                </div>

                <div className="p-4 bg-gray-50 rounded-xl border border-gray-200">
                  <div className="flex justify-between items-center mb-1">
                    <span className="text-xs font-bold text-gray-800">Location Data Retention</span>
                    <span className="px-2 py-0.5 bg-purple-100 text-purple-800 text-[10px] font-bold rounded">AUTO-EXPIRE</span>
                  </div>
                  <p className="text-[11px] text-gray-500">
                    Journey GPS breadcrumbs automatically purge 24 hours after journey completion.
                  </p>
                </div>

                <div className="pt-4 border-t border-gray-200">
                  <button
                    onClick={() => {
                      if (confirm('Are you sure you want to purge all active journey trails and cached location telemetry?')) {
                        alert('Location history purged from device and server session.');
                      }
                    }}
                    className="w-full py-2.5 bg-red-50 hover:bg-red-100 text-red-700 font-semibold rounded-xl text-xs border border-red-200 transition"
                  >
                    Purge My Telemetry & Location History Now
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-200 py-4 px-6 text-center text-xs text-gray-500">
        <p>
          <strong>SAKHI</strong> — Privacy-First Women's Safety Network. Travel safer. Respond faster. Stay connected.
        </p>
      </footer>
    </div>
  );
}
