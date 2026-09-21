import React, { useState, useEffect } from 'react';
import { EmergencyResource, SupportResource } from '../types';
import { AdminApi } from '../services/api';
import { Building2, Plus, Trash2, Phone, MapPin, ExternalLink, ShieldCheck } from 'lucide-react';

export const ResourcesPage: React.FC = () => {
  const [activeSubTab, setActiveSubTab] = useState<'emergency' | 'support'>('emergency');
  const [emergencyResources, setEmergencyResources] = useState<EmergencyResource[]>([]);
  const [supportResources, setSupportResources] = useState<SupportResource[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [showAddModal, setShowAddModal] = useState<boolean>(false);

  // Form state for new emergency resource
  const [newName, setNewName] = useState('');
  const [newCategory, setNewCategory] = useState<'POLICE' | 'HOSPITAL' | 'FIRE_STATION' | 'SAFE_PLACE' | 'WOMEN_SHELTER'>('POLICE');
  const [newPhone, setNewPhone] = useState('');
  const [newAddress, setNewAddress] = useState('');
  const [newLat, setNewLat] = useState('28.6315');
  const [newLon, setNewLon] = useState('77.2167');

  const loadData = async () => {
    setLoading(true);
    try {
      const [em, sp] = await Promise.all([
        AdminApi.getEmergencyResources(),
        AdminApi.getSupportResources()
      ]);
      setEmergencyResources(em);
      setSupportResources(sp);
    } catch (err: any) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await AdminApi.addEmergencyResource({
        name: newName,
        category: newCategory,
        phone: newPhone,
        address: newAddress,
        latitude: parseFloat(newLat),
        longitude: parseFloat(newLon),
        is_verified: true,
        operating_hours: '24/7'
      });
      setShowAddModal(false);
      setNewName('');
      setNewPhone('');
      setNewAddress('');
      loadData();
    } catch (err: any) {
      alert(`Error creating resource: ${err.message}`);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this resource?')) return;
    try {
      await AdminApi.deleteEmergencyResource(id);
      loadData();
    } catch (err: any) {
      alert(`Error deleting resource: ${err.message}`);
    }
  };

  return (
    <div className="space-y-5">
      {/* Tab Switcher & Action */}
      <div className="bg-white p-4 rounded-xl border border-slate-200/80 shadow-sm flex items-center justify-between">
        <div className="flex items-center gap-2">
          <button
            onClick={() => setActiveSubTab('emergency')}
            className={`px-4 py-2 rounded-lg text-xs font-bold transition-all ${
              activeSubTab === 'emergency'
                ? 'bg-sakhi-violet text-white shadow-sm'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            Emergency Infrastructure ({emergencyResources.length})
          </button>
          <button
            onClick={() => setActiveSubTab('support')}
            className={`px-4 py-2 rounded-lg text-xs font-bold transition-all ${
              activeSubTab === 'support'
                ? 'bg-sakhi-violet text-white shadow-sm'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            Legal & Support Directory ({supportResources.length})
          </button>
        </div>

        {activeSubTab === 'emergency' && (
          <button
            onClick={() => setShowAddModal(true)}
            className="flex items-center gap-1.5 px-3.5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-bold transition-colors shadow-sm"
          >
            <Plus className="w-4 h-4" />
            <span>Add Emergency Station</span>
          </button>
        )}
      </div>

      {/* Emergency Resources View */}
      {activeSubTab === 'emergency' && (
        <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs text-slate-600">
              <thead className="bg-slate-50 border-b border-slate-200 text-slate-700 uppercase font-semibold text-[11px] tracking-wider">
                <tr>
                  <th className="py-3 px-4">Resource Name</th>
                  <th className="py-3 px-4">Category</th>
                  <th className="py-3 px-4">Emergency Phone</th>
                  <th className="py-3 px-4">Address</th>
                  <th className="py-3 px-4">Operating Hours</th>
                  <th className="py-3 px-4 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {emergencyResources.map((r) => (
                  <tr key={r.id} className="hover:bg-slate-50/70">
                    <td className="py-3.5 px-4 font-bold text-slate-800 flex items-center gap-2">
                      <ShieldCheck className="w-4 h-4 text-emerald-600 flex-shrink-0" />
                      <span>{r.name}</span>
                    </td>
                    <td className="py-3.5 px-4">
                      <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-purple-50 text-sakhi-violet border border-purple-200">
                        {r.category.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 font-mono font-medium text-slate-800">{r.phone}</td>
                    <td className="py-3.5 px-4 text-slate-600 max-w-xs truncate">{r.address}</td>
                    <td className="py-3.5 px-4 text-slate-500">{r.operating_hours}</td>
                    <td className="py-3.5 px-4 text-right">
                      <button
                        onClick={() => handleDelete(r.id)}
                        className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors"
                        title="Delete Resource"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Support Resources View */}
      {activeSubTab === 'support' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {supportResources.map((sp) => (
            <div key={sp.id} className="bg-white p-5 rounded-xl border border-slate-200/80 shadow-sm space-y-3">
              <div className="flex items-start justify-between">
                <div>
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-blue-50 text-blue-700 border border-blue-200 uppercase">
                    {sp.category.replace('_', ' ')}
                  </span>
                  <h4 className="font-bold text-slate-800 text-sm mt-1">{sp.title}</h4>
                  <p className="text-xs text-slate-500 font-medium">{sp.organization}</p>
                </div>
                {sp.website && (
                  <a
                    href={sp.website}
                    target="_blank"
                    rel="noreferrer"
                    className="p-1.5 text-slate-400 hover:text-sakhi-violet rounded-lg"
                  >
                    <ExternalLink className="w-4 h-4" />
                  </a>
                )}
              </div>

              <p className="text-xs text-slate-600 line-clamp-2">{sp.description}</p>

              {sp.phone && (
                <div className="flex items-center gap-2 text-xs font-mono font-bold text-slate-800 bg-slate-50 p-2 rounded-lg border border-slate-200">
                  <Phone className="w-3.5 h-3.5 text-emerald-600" />
                  <span>{sp.phone}</span>
                </div>
              )}

              {sp.actionable_steps && (
                <div className="text-[11px] text-slate-600 bg-slate-50/80 p-2.5 rounded-lg border border-slate-200/60 whitespace-pre-line font-medium">
                  {sp.actionable_steps}
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Add Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <h3 className="font-bold text-slate-800 text-base">Add Verified Emergency Facility</h3>
            <form onSubmit={handleAdd} className="space-y-3 text-xs">
              <div>
                <label className="block text-slate-700 font-medium mb-1">Facility Name</label>
                <input
                  type="text"
                  required
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  placeholder="e.g. Metro Police Booth"
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-700 font-medium mb-1">Category</label>
                  <select
                    value={newCategory}
                    onChange={(e: any) => setNewCategory(e.target.value)}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg"
                  >
                    <option value="POLICE">Police Station</option>
                    <option value="HOSPITAL">Hospital</option>
                    <option value="SAFE_PLACE">Safe Place</option>
                    <option value="WOMEN_SHELTER">Women Shelter</option>
                    <option value="FIRE_STATION">Fire Station</option>
                  </select>
                </div>
                <div>
                  <label className="block text-slate-700 font-medium mb-1">Emergency Phone</label>
                  <input
                    type="text"
                    required
                    value={newPhone}
                    onChange={(e) => setNewPhone(e.target.value)}
                    placeholder="112 or Landline"
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg"
                  />
                </div>
              </div>
              <div>
                <label className="block text-slate-700 font-medium mb-1">Address / Landmark</label>
                <input
                  type="text"
                  required
                  value={newAddress}
                  onChange={(e) => setNewAddress(e.target.value)}
                  placeholder="Street / Sector"
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-700 font-medium mb-1">Latitude</label>
                  <input
                    type="number"
                    step="any"
                    required
                    value={newLat}
                    onChange={(e) => setNewLat(e.target.value)}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg"
                  />
                </div>
                <div>
                  <label className="block text-slate-700 font-medium mb-1">Longitude</label>
                  <input
                    type="number"
                    step="any"
                    required
                    value={newLon}
                    onChange={(e) => setNewLon(e.target.value)}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg"
                  />
                </div>
              </div>

              <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-4 py-2 text-slate-600 font-semibold hover:bg-slate-100 rounded-lg"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-sakhi-violet text-white font-bold rounded-lg shadow-sm"
                >
                  Save Resource
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
