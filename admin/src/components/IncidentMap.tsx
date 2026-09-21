import React, { useEffect, useRef } from 'react';
import L from 'leaflet';
import { Incident } from '../types';

interface IncidentMapProps {
  incidents: Incident[];
  center?: [number, number];
  zoom?: number;
}

export const IncidentMap: React.FC<IncidentMapProps> = ({
  incidents,
  center = [28.6315, 77.2167],
  zoom = 13
}) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const markersLayerRef = useRef<L.LayerGroup | null>(null);

  useEffect(() => {
    if (!mapContainerRef.current) return;

    if (!mapInstanceRef.current) {
      const map = L.map(mapContainerRef.current).setView(center, zoom);
      
      // Free OpenStreetMap CartoDB Positron tiles for clean modern UI
      L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; OpenStreetMap contributors &copy; CARTO',
        maxZoom: 19
      }).addTo(map);

      const markersGroup = L.layerGroup().addTo(map);
      markersLayerRef.current = markersGroup;
      mapInstanceRef.current = map;
    }

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, []);

  useEffect(() => {
    if (!mapInstanceRef.current || !markersLayerRef.current) return;

    const layerGroup = markersLayerRef.current;
    layerGroup.clearLayers();

    const severityColors: Record<string, string> = {
      CRITICAL: '#E63946',
      HIGH: '#F4A261',
      MEDIUM: '#E76F51',
      LOW: '#2A9D8F'
    };

    incidents.forEach((inc) => {
      const color = severityColors[inc.severity] || '#6B7280';
      const marker = L.circleMarker([inc.latitude, inc.longitude], {
        radius: inc.severity === 'CRITICAL' ? 12 : inc.severity === 'HIGH' ? 10 : 8,
        fillColor: color,
        color: '#FFFFFF',
        weight: 2,
        opacity: 1,
        fillOpacity: 0.85
      });

      const popupContent = `
        <div style="font-family: Inter, sans-serif; padding: 4px; min-width: 180px;">
          <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 6px;">
            <span style="font-size: 11px; font-weight: 700; color: ${color}; text-transform: uppercase;">${inc.category}</span>
            <span style="font-size: 10px; background: #F1F5F9; padding: 2px 6px; border-radius: 4px; font-weight: 600;">${inc.status}</span>
          </div>
          <p style="font-size: 12px; color: #1E293B; margin: 0 0 6px 0; line-height: 1.4;">${inc.description}</p>
          <div style="font-size: 10px; color: #64748B; border-top: 1px solid #E2E8F0; padding-top: 4px;">
            Severity: <b>${inc.severity}</b> | ${new Date(inc.incident_time).toLocaleDateString()}
          </div>
        </div>
      `;

      marker.bindPopup(popupContent);
      layerGroup.addLayer(marker);
    });

    if (incidents.length > 0 && mapInstanceRef.current) {
      const group = L.featureGroup(layerGroup.getLayers() as L.Layer[]);
      try {
        mapInstanceRef.current.fitBounds(group.getBounds().pad(0.2));
      } catch {
        // bounds fallback
      }
    }
  }, [incidents]);

  return (
    <div className="w-full h-full min-h-[450px] relative rounded-xl overflow-hidden border border-slate-200 shadow-sm">
      <div ref={mapContainerRef} className="w-full h-full min-h-[450px]" />
      
      {/* Legend Overlay */}
      <div className="absolute bottom-4 right-4 bg-white/95 backdrop-blur-sm p-3 rounded-lg shadow-md border border-slate-200 text-xs z-[1000] space-y-1.5 pointer-events-auto">
        <p className="font-semibold text-slate-700 text-[11px] mb-1">Severity Indicator</p>
        <div className="flex items-center gap-2">
          <span className="w-3 h-3 rounded-full bg-[#E63946] border border-white"></span>
          <span className="text-slate-600">Critical Severity</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="w-3 h-3 rounded-full bg-[#F4A261] border border-white"></span>
          <span className="text-slate-600">High Severity</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="w-3 h-3 rounded-full bg-[#2A9D8F] border border-white"></span>
          <span className="text-slate-600">Low / Infrastructure</span>
        </div>
      </div>
    </div>
  );
};
