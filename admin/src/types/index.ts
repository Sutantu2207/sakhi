export type IncidentCategory = 
  | 'HARASSMENT' 
  | 'STALKING' 
  | 'ASSAULT' 
  | 'THEFT' 
  | 'POOR_LIGHTING' 
  | 'UNSAFE_AREA' 
  | 'CYBERCRIME' 
  | 'OTHER';

export type IncidentSeverity = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
export type IncidentStatus = 'PENDING' | 'VERIFIED' | 'REJECTED' | 'RESOLVED';
export type SOSStatus = 'CREATED' | 'ACTIVE' | 'ACKNOWLEDGED' | 'RESOLVED' | 'CANCELLED' | 'EXPIRED';

export interface Incident {
  id: string;
  reporter_id?: string | null;
  is_anonymous: boolean;
  category: IncidentCategory;
  severity: IncidentSeverity;
  description: string;
  incident_time: string;
  latitude: number;
  longitude: number;
  status: IncidentStatus;
  moderator_notes?: string | null;
  created_at: string;
}

export interface SOSEvent {
  id: string;
  user_id: string;
  status: SOSStatus;
  latitude: number;
  longitude: number;
  address_approx?: string | null;
  triggered_at: string;
  resolved_at?: string | null;
  contacts_notified_count: number;
  notification_status: string;
  admin_notes?: string | null;
  responder_id?: string | null;
}

export interface OverviewStats {
  active_journeys: number;
  active_sos: number;
  incidents_today: number;
  total_incidents: number;
  resolved_incidents: number;
  pending_moderation: number;
  total_users: number;
  verified_resources: number;
  categories_breakdown: Record<string, number>;
  status_breakdown: Record<string, number>;
  system_status: string;
}

export interface EmergencyResource {
  id: string;
  name: string;
  category: 'POLICE' | 'HOSPITAL' | 'FIRE_STATION' | 'SAFE_PLACE' | 'WOMEN_SHELTER';
  phone: string;
  address: string;
  latitude: number;
  longitude: number;
  is_verified: boolean;
  operating_hours: string;
  created_at: string;
}

export interface SupportResource {
  id: string;
  category: 'LEGAL' | 'DOMESTIC_ABUSE' | 'CYBERCRIME' | 'PSYCHOLOGICAL' | 'HELPLINE' | 'POSH';
  title: string;
  organization: string;
  phone?: string | null;
  website?: string | null;
  description: string;
  jurisdiction: string;
  actionable_steps?: string | null;
  created_at: string;
}

export interface AuditLogItem {
  id: string;
  action: string;
  resource_type: string;
  resource_id?: string | null;
  user_id?: string | null;
  details?: string | null;
  ip_address?: string | null;
  timestamp: string;
}
