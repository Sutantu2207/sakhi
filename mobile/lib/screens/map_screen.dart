import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/safety_provider.dart';
import '../widgets/risk_badge.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _selectedFilter = 'INCIDENTS'; // INCIDENTS, POLICE, HOSPITALS

  @override
  Widget build(BuildContext context) {
    final safety = Provider.of<SafetyProvider>(context);
    final incidents = safety.nearbyIncidents;
    final resources = safety.emergencyResources;
    final risk = safety.currentRisk;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety & Infrastructure Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryViolet),
            onPressed: () => safety.refreshSafetyContext(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Risk Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Active Area Assessment:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  RiskBadge(category: risk?.riskCategory ?? 'lower_reported_risk', isCompact: true),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),

            // Layer Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Row(
                children: [
                  _buildLayerChip('INCIDENTS', 'Verified Incidents (${incidents.length})'),
                  const SizedBox(width: 8),
                  _buildLayerChip('POLICE', 'Police Posts'),
                  const SizedBox(width: 8),
                  _buildLayerChip('HOSPITALS', 'Hospitals'),
                ],
              ),
            ),

            // Map list representation with coordinates and details
            Expanded(
              child: _selectedFilter == 'INCIDENTS'
                  ? (incidents.isNotEmpty
                      ? ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: incidents.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final inc = incidents[i];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          inc.category.replaceAll('_', ' '),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkCharcoal),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.warningAmber.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            inc.severity,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warningAmber),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(inc.description, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${inc.latitude.toStringAsFixed(4)}, ${inc.longitude.toStringAsFixed(4)}',
                                          style: const TextStyle(fontSize: 11, fontFeatures: [FontFeature.tabularFigures()], color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : const Center(child: Text('No verified incidents in this area', style: TextStyle(color: AppColors.textMuted))))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: resources
                          .where((r) => _selectedFilter == 'POLICE' ? r.category == 'POLICE' : r.category == 'HOSPITAL')
                          .length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final res = resources
                            .where((r) => _selectedFilter == 'POLICE' ? r.category == 'POLICE' : r.category == 'HOSPITAL')
                            .toList()[i];
                        return Card(
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (_selectedFilter == 'POLICE' ? AppColors.primaryViolet : AppColors.emergencyCoral).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _selectedFilter == 'POLICE' ? Icons.local_police_rounded : Icons.local_hospital_rounded,
                                color: _selectedFilter == 'POLICE' ? AppColors.primaryViolet : AppColors.emergencyCoral,
                              ),
                            ),
                            title: Text(res.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('${res.address}\nPhone: ${res.phone}', style: const TextStyle(fontSize: 11)),
                            trailing: res.distanceKm != null
                                ? Text('${res.distanceKm!.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryViolet : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primaryViolet : AppColors.borderLight),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.darkCharcoal,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
