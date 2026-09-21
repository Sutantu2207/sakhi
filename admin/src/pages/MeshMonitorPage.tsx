import React, { useState, useEffect } from 'react';
import { Radio, Wifi, Shield, Cpu, RefreshCw, Play, CheckCircle2, AlertTriangle, ArrowRight } from 'lucide-react';

interface MeshStatus {
  status: string;
  active_gateways_count: number;
  total_packets_relayed: number;
  emergency_sos_packets_count: number;
  last_packet_received_at: string | null;
  simulation_mode: boolean;
}

export const MeshMonitorPage: React.FC = () => {
  const [meshStatus, setMeshStatus] = useState<MeshStatus | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isSimulating, setIsSimulating] = useState<boolean>(false);
  const [simulationLog, setSimulationLog] = useState<string[]>([]);

  const fetchMeshStatus = async () => {
    try {
      const res = await fetch('/api/v1/network/mesh-status');
      if (res.ok) {
        const data = await res.json();
        setMeshStatus(data);
      }
    } catch (e) {
      console.error('Failed to fetch mesh status:', e);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchMeshStatus();
    const interval = setInterval(fetchMeshStatus, 10000);
    return () => clearInterval(interval);
  }, []);

  const triggerMeshSimulation = async () => {
    setIsSimulating(true);
    setSimulationLog(prev => [
      `[${new Date().toLocaleTimeString()}] Generating 128-bit Ephemeral Beacon on Mobile BLE (Service 0xFA10)...`,
      ...prev
    ]);

    setTimeout(() => {
      setSimulationLog(prev => [
        `[${new Date().toLocaleTimeString()}] ESP32 Relay Node ALPHA ingested packet. Decremented TTL to 4, Hop=1.`,
        ...prev
      ]);
    }, 400);

    setTimeout(() => {
      setSimulationLog(prev => [
        `[${new Date().toLocaleTimeString()}] ESP32 Relay Node BETA forwarded over ESP-NOW Channel 1. Hop=2.`,
        ...prev
      ]);
    }, 800);

    setTimeout(async () => {
      try {
        const packet = {
          version: 1,
          message_id: `pkt-${Math.random().toString(36).substring(2, 10)}`,
          ephemeral_id: `eph-${Math.random().toString(36).substring(2, 10)}`,
          message_type: 'SOS',
          timestamp: new Date().toISOString(),
          latitude: 28.6145 + (Math.random() - 0.5) * 0.01,
          longitude: 77.2098 + (Math.random() - 0.5) * 0.01,
          accuracy_meters: 8.5,
          sequence: Math.floor(Math.random() * 100) + 1,
          ttl: 3,
          hop_count: 2,
          priority: 'EMERGENCY',
          gateway_id: 'ESP32-GW-DELHI-01'
        };

        const res = await fetch('/api/v1/network/mesh-gateway', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(packet)
        });

        if (res.ok) {
          const result = await res.json();
          setSimulationLog(prev => [
            `[${new Date().toLocaleTimeString()}] Gateway Uplink Success! Cloud Ingested SOS (ID: ${result.sos_id || 'PROCESSED'}).`,
            ...prev
          ]);
          fetchMeshStatus();
        }
      } catch (err: any) {
        setSimulationLog(prev => [
          `[${new Date().toLocaleTimeString()}] Error: ${err.message}`,
          ...prev
        ]);
      } finally {
        setIsSimulating(false);
      }
    }, 1200);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-wrap justify-between items-center gap-4 bg-white p-6 rounded-2xl border border-sakhi-border shadow-sm">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <Radio className="text-[#3A1C71] animate-pulse" size={24} />
            <h1 className="text-xl font-bold text-slate-800">SAKHI Emergency Mesh Telemetry</h1>
          </div>
          <p className="text-xs text-slate-500">
            Real-time monitoring of decentralized ESP32 + ESP-NOW + BLE relay nodes for cellular dead zones.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={fetchMeshStatus}
            className="flex items-center gap-1.5 px-3 py-2 bg-slate-100 text-slate-700 rounded-lg text-xs font-semibold hover:bg-slate-200 transition"
          >
            <RefreshCw size={14} className={isLoading ? 'animate-spin' : ''} />
            <span>Sync Mesh</span>
          </button>
          <button
            onClick={triggerMeshSimulation}
            disabled={isSimulating}
            className="flex items-center gap-2 px-4 py-2 bg-[#3A1C71] hover:bg-purple-900 text-white rounded-lg text-xs font-bold transition shadow-md shadow-purple-900/20"
          >
            <Play size={14} className={isSimulating ? 'animate-spin' : ''} />
            <span>{isSimulating ? 'Simulating Relay...' : 'Simulate Mesh Ingestion'}</span>
          </button>
        </div>
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <span className="text-xs text-slate-500 font-semibold block mb-1">Mesh Status</span>
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500"></span>
            <span className="text-lg font-bold text-slate-800">{meshStatus?.status || 'OPERATIONAL'}</span>
          </div>
          <span className="text-[10px] text-slate-400 mt-1 block">ESP-NOW Channel 1 Ready</span>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <span className="text-xs text-slate-500 font-semibold block mb-1">Active Gateways</span>
          <div className="text-2xl font-black text-[#3A1C71]">{meshStatus?.active_gateways_count || 1}</div>
          <span className="text-[10px] text-slate-400 mt-1 block">ESP32 Wi-Fi / AP Uplinks</span>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <span className="text-xs text-slate-500 font-semibold block mb-1">Total Relayed Packets</span>
          <div className="text-2xl font-black text-slate-800">{meshStatus?.total_packets_relayed || 0}</div>
          <span className="text-[10px] text-slate-400 mt-1 block">Deduplicated in cache</span>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <span className="text-xs text-slate-500 font-semibold block mb-1">Emergency SOS Frames</span>
          <div className="text-2xl font-black text-[#E63946]">{meshStatus?.emergency_sos_packets_count || 0}</div>
          <span className="text-[10px] text-slate-400 mt-1 block">High-priority alerts</span>
        </div>
      </div>

      {/* Architecture Visualizer & Live Simulation Feed */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Topology Card */}
        <div className="bg-white p-6 rounded-2xl border border-sakhi-border shadow-sm space-y-4">
          <h3 className="font-bold text-sm text-slate-800 flex items-center gap-2">
            <Cpu size={18} className="text-[#3A1C71]" />
            Relay Topology & Zero-PII Guarantees
          </h3>
          <p className="text-xs text-slate-600 leading-relaxed">
            The Emergency Mesh operates in 3 distinct layers to provide maximum resilience when cellular communication is disabled:
          </p>

          <div className="space-y-3 pt-2">
            <div className="p-3 bg-purple-50 rounded-xl border border-purple-200/60 flex items-center justify-between">
              <div>
                <span className="text-[11px] font-bold text-[#3A1C71] uppercase">Layer 1: Mobile BLE Beacon</span>
                <p className="text-xs text-slate-600">Rotating 128-bit ephemeral IDs over GATT Characteristic 0xFA11</p>
              </div>
              <span className="px-2 py-0.5 bg-purple-200 text-purple-800 text-[10px] font-bold rounded">ZERO PII</span>
            </div>

            <div className="p-3 bg-blue-50 rounded-xl border border-blue-200/60 flex items-center justify-between">
              <div>
                <span className="text-[11px] font-bold text-blue-800 uppercase">Layer 2: ESP-NOW Relay Hops</span>
                <p className="text-xs text-slate-600">Connectionless 2.4 GHz multi-hop forwarding with TTL countdown (Max 5 hops)</p>
              </div>
              <span className="px-2 py-0.5 bg-blue-200 text-blue-800 text-[10px] font-bold rounded">NO INTERNET</span>
            </div>

            <div className="p-3 bg-emerald-50 rounded-xl border border-emerald-200/60 flex items-center justify-between">
              <div>
                <span className="text-[11px] font-bold text-emerald-800 uppercase">Layer 3: Hardware Gateway Uplink</span>
                <p className="text-xs text-slate-600">Fixed kiosk / AP gateway bridges emergency frames to Sakhi Cloud API</p>
              </div>
              <span className="px-2 py-0.5 bg-emerald-200 text-emerald-800 text-[10px] font-bold rounded">HTTPS</span>
            </div>
          </div>
        </div>

        {/* Live Simulation Feed */}
        <div className="bg-slate-900 text-white p-6 rounded-2xl shadow-xl flex flex-col justify-between">
          <div>
            <div className="flex justify-between items-center mb-3">
              <h3 className="font-mono text-xs font-bold text-emerald-400 flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping"></span>
                LIVE MESH INGESTION LOGS
              </h3>
              <span className="text-[10px] font-mono text-slate-400">ESP-NOW CH1</span>
            </div>

            <div className="h-64 overflow-y-auto space-y-2 font-mono text-xs text-slate-300 pr-2">
              {simulationLog.length === 0 ? (
                <p className="text-slate-500 py-8 text-center">
                  Click "Simulate Mesh Ingestion" to simulate an end-to-end packet transmission through virtual relays...
                </p>
              ) : (
                simulationLog.map((log, idx) => (
                  <div key={idx} className="p-2 bg-slate-800/80 rounded border border-slate-700/60">
                    {log}
                  </div>
                ))
              )}
            </div>
          </div>

          <div className="pt-4 border-t border-slate-800 text-[11px] text-slate-400 flex justify-between items-center">
            <span>Anti-replay Cache: Active (128 entries)</span>
            <span className="text-emerald-400">Gateway Status: Online</span>
          </div>
        </div>
      </div>
    </div>
  );
};
