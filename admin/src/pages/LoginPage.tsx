import React, { useState } from 'react';
import { AdminApi } from '../services/api';
import { Shield, Lock, Mail, AlertCircle } from 'lucide-react';

interface LoginProps {
  onLoginSuccess: () => void;
}

export const LoginPage: React.FC<LoginProps> = ({ onLoginSuccess }) => {
  const [email, setEmail] = useState('admin@sakhi.network');
  const [password, setPassword] = useState('Admin@Sakhi2026');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      await AdminApi.login(email, password);
      onLoginSuccess();
    } catch (err: any) {
      setError(err.message || 'Login failed. Please check credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4">
      <div className="max-w-md w-full bg-white rounded-2xl shadow-2xl p-8 space-y-6">
        {/* Brand Header */}
        <div className="text-center space-y-2">
          <div className="w-14 h-14 bg-gradient-to-tr from-[#3A1C71] to-[#6A3FB5] rounded-2xl flex items-center justify-center mx-auto shadow-lg shadow-purple-950/30">
            <Shield className="w-8 h-8 text-white" />
          </div>
          <h2 className="text-2xl font-bold text-slate-800 tracking-tight">SAKHI ADMIN</h2>
          <p className="text-xs text-slate-500 font-medium">Central Operations & Incident Moderation</p>
        </div>

        {error && (
          <div className="p-3 bg-red-50 border border-red-200 text-red-700 text-xs rounded-lg flex items-center gap-2">
            <AlertCircle className="w-4 h-4 flex-shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4 text-xs">
          <div>
            <label className="block text-slate-700 font-semibold mb-1.5">Official Admin Email</label>
            <div className="relative">
              <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full pl-9 pr-3 py-2.5 bg-slate-50 border border-slate-200 rounded-lg text-slate-800 focus:outline-none focus:ring-2 focus:ring-sakhi-violet/40 font-medium"
                placeholder="admin@sakhi.network"
              />
            </div>
          </div>

          <div>
            <label className="block text-slate-700 font-semibold mb-1.5">Password</label>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full pl-9 pr-3 py-2.5 bg-slate-50 border border-slate-200 rounded-lg text-slate-800 focus:outline-none focus:ring-2 focus:ring-sakhi-violet/40 font-medium"
                placeholder="••••••••••••"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 bg-sakhi-violet hover:bg-[#4A2491] text-white font-bold rounded-lg shadow-md shadow-purple-900/20 transition-all text-xs flex items-center justify-center gap-2"
          >
            {loading ? 'Authenticating...' : 'Sign In to Operations Console'}
          </button>
        </form>

        <div className="bg-slate-50 p-3 rounded-lg border border-slate-200 text-[11px] text-slate-600">
          <p className="font-semibold text-slate-800 mb-0.5">Development Environment Note:</p>
          <p>Seeded credentials prefilled: <span className="font-mono text-purple-700 font-semibold">admin@sakhi.network</span> / <span className="font-mono text-purple-700 font-semibold">Admin@Sakhi2026</span></p>
        </div>

        {/* Switch to User / Citizen Portal */}
        <div className="pt-2 text-center">
          <button
            type="button"
            onClick={() => {
              window.location.search = '?mode=user';
            }}
            className="w-full py-2.5 bg-gradient-to-r from-red-600 to-purple-600 hover:from-red-700 hover:to-purple-700 text-white font-bold rounded-lg text-xs shadow-md transition"
          >
            Switch to Citizen / User Safety Dashboard &rarr;
          </button>
        </div>
      </div>
    </div>
  );
};
