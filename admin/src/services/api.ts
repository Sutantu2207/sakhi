import { 
  OverviewStats, Incident, SOSEvent, EmergencyResource, 
  SupportResource, AuditLogItem, IncidentStatus, SOSStatus 
} from '../types';

const API_BASE = '/api/v1';

export class AdminApi {
  private static getToken(): string | null {
    return localStorage.getItem('sakhi_admin_token');
  }

  public static setToken(token: string) {
    localStorage.setItem('sakhi_admin_token', token);
  }

  public static clearToken() {
    localStorage.removeItem('sakhi_admin_token');
  }

  private static async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const token = this.getToken();
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(options.headers as Record<string, string> || {})
    };

    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const response = await fetch(`${API_BASE}${endpoint}`, {
      ...options,
      headers
    });

    if (response.status === 401) {
      this.clearToken();
      window.dispatchEvent(new Event('auth_expired'));
      throw new Error('Session expired or unauthorized');
    }

    if (!response.ok) {
      const err = await response.json().catch(() => ({ detail: 'Network request failed' }));
      throw new Error(err.detail || `Error ${response.status}`);
    }

    if (response.status === 204) {
      return null as unknown as T;
    }

    return response.json();
  }

  // Auth
  static async login(email: string, password: string) {
    const data = await this.request<{ access_token: string; role: string; full_name: string }>(
      '/auth/login',
      {
        method: 'POST',
        body: JSON.stringify({ email, password })
      }
    );
    if (data.role !== 'ADMIN' && data.role !== 'MODERATOR') {
      throw new Error('Access denied: Admin credentials required.');
    }
    this.setToken(data.access_token);
    return data;
  }

  // Overview
  static async getOverview(): Promise<OverviewStats> {
    return this.request<OverviewStats>('/admin/overview');
  }

  // Incidents
  static async getIncidents(status?: IncidentStatus): Promise<Incident[]> {
    const query = status ? `?status=${status}` : '';
    return this.request<Incident[]>(`/admin/incidents${query}`);
  }

  static async moderateIncident(id: string, status: IncidentStatus, moderator_notes?: string): Promise<Incident> {
    return this.request<Incident>(`/admin/incidents/${id}/moderate`, {
      method: 'PUT',
      body: JSON.stringify({ status, moderator_notes })
    });
  }

  // SOS
  static async getSOSEvents(status?: SOSStatus): Promise<SOSEvent[]> {
    const query = status ? `?status=${status}` : '';
    return this.request<SOSEvent[]>(`/admin/sos${query}`);
  }

  static async acknowledgeSOS(id: string): Promise<SOSEvent> {
    return this.request<SOSEvent>(`/admin/sos/${id}/acknowledge`, {
      method: 'PUT'
    });
  }

  static async resolveSOS(id: string, admin_notes: string): Promise<SOSEvent> {
    return this.request<SOSEvent>(`/admin/sos/${id}/resolve`, {
      method: 'PUT',
      body: JSON.stringify({ admin_notes })
    });
  }

  // Resources
  static async getEmergencyResources(): Promise<EmergencyResource[]> {
    return this.request<EmergencyResource[]>('/admin/resources/emergency');
  }

  static async addEmergencyResource(resource: Partial<EmergencyResource>): Promise<EmergencyResource> {
    return this.request<EmergencyResource>('/admin/resources/emergency', {
      method: 'POST',
      body: JSON.stringify(resource)
    });
  }

  static async deleteEmergencyResource(id: string): Promise<void> {
    return this.request<void>(`/admin/resources/emergency/${id}`, {
      method: 'DELETE'
    });
  }

  static async getSupportResources(): Promise<SupportResource[]> {
    return this.request<SupportResource[]>('/admin/resources/support');
  }

  static async addSupportResource(resource: Partial<SupportResource>): Promise<SupportResource> {
    return this.request<SupportResource>('/admin/resources/support', {
      method: 'POST',
      body: JSON.stringify(resource)
    });
  }

  // Audit Logs
  static async getAuditLogs(limit: number = 50): Promise<AuditLogItem[]> {
    return this.request<AuditLogItem[]>(`/admin/audit-logs?limit=${limit}`);
  }
}

export class UserApi {
  private static getToken(): string | null {
    return localStorage.getItem('sakhi_user_token');
  }

  public static setToken(token: string) {
    localStorage.setItem('sakhi_user_token', token);
  }

  public static clearToken() {
    localStorage.removeItem('sakhi_user_token');
  }

  private static async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const token = this.getToken();
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(options.headers as Record<string, string> || {})
    };

    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const response = await fetch(`${API_BASE}${endpoint}`, {
      ...options,
      headers
    });

    if (response.status === 401) {
      this.clearToken();
      window.dispatchEvent(new Event('user_auth_expired'));
      throw new Error('User session expired or unauthorized');
    }

    if (!response.ok) {
      const err = await response.json().catch(() => ({ detail: 'Network request failed' }));
      throw new Error(err.detail || `Error ${response.status}`);
    }

    if (response.status === 204) {
      return null as unknown as T;
    }

    return response.json();
  }

  static async login(email: string, password: string) {
    const data = await this.request<{ access_token: string; role: string; full_name: string }>(
      '/auth/login',
      {
        method: 'POST',
        body: JSON.stringify({ email, password })
      }
    );
    this.setToken(data.access_token);
    return data;
  }

  static async register(userData: { email: string; password: string; full_name: string; phone_number?: string }) {
    return this.request('/auth/register', {
      method: 'POST',
      body: JSON.stringify(userData)
    });
  }

  static async getProfile() {
    return this.request<any>('/auth/me');
  }

  static async getContacts() {
    return this.request<any[]>('/contacts');
  }

  static async addContact(contact: { name: string; phone_number: string; relationship?: string; notify_sos?: boolean }) {
    return this.request<any>('/contacts', {
      method: 'POST',
      body: JSON.stringify(contact)
    });
  }

  static async deleteContact(id: string) {
    return this.request<void>(`/contacts/${id}`, {
      method: 'DELETE'
    });
  }

  static async triggerSOS(latitude: number, longitude: number, accuracy_meters: number = 10.0) {
    return this.request<any>('/sos/trigger', {
      method: 'POST',
      body: JSON.stringify({ latitude, longitude, accuracy_meters })
    });
  }

  static async resolveSOS(id: string, notes: string = 'User marked safe') {
    return this.request<any>(`/sos/${id}/resolve`, {
      method: 'POST',
      body: JSON.stringify({ notes })
    });
  }

  static async getActiveSOS() {
    return this.request<any>('/sos/active');
  }

  static async startJourney(params: {
    origin_latitude: number;
    origin_longitude: number;
    destination_latitude?: number;
    destination_longitude?: number;
    destination_name?: string;
    expected_duration_minutes?: number;
  }) {
    return this.request<any>('/journeys/start', {
      method: 'POST',
      body: JSON.stringify(params)
    });
  }

  static async sendJourneyLocation(journeyId: string, latitude: number, longitude: number, speed_kmh?: number) {
    return this.request<any>(`/journeys/${journeyId}/location`, {
      method: 'POST',
      body: JSON.stringify({ latitude, longitude, speed_kmh })
    });
  }

  static async endJourney(journeyId: string) {
    return this.request<any>(`/journeys/${journeyId}/end`, {
      method: 'POST'
    });
  }

  static async getActiveJourney() {
    return this.request<any>('/journeys/active');
  }

  static async getNearbyIncidents(lat: number, lng: number, radiusKm: number = 10) {
    return this.request<any[]>(`/incidents/nearby?latitude=${lat}&longitude=${lng}&radius_km=${radiusKm}`);
  }

  static async reportIncident(data: {
    category: string;
    description: string;
    latitude: number;
    longitude: number;
    severity?: string;
    is_anonymous?: boolean;
    photo_url?: string;
  }) {
    return this.request<any>('/incidents', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  }

  static async getNearbyResources(lat: number, lng: number, resourceType?: string, radiusKm: number = 15) {
    const typeParam = resourceType ? `&resource_type=${resourceType}` : '';
    return this.request<any[]>(`/resources/nearby?latitude=${lat}&longitude=${lng}&radius_km=${radiusKm}${typeParam}`);
  }

  static async getAreaRisk(lat: number, lng: number) {
    return this.request<any>(`/risk/evaluate?latitude=${lat}&longitude=${lng}`);
  }
}

