import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/safety_provider.dart';
import '../models/resource.dart';

class NearbyHelpScreen extends StatefulWidget {
  const NearbyHelpScreen({super.key});

  @override
  State<NearbyHelpScreen> createState() => _NearbyHelpScreenState();
}

class _NearbyHelpScreenState extends State<NearbyHelpScreen> {
  String _selectedCategory = 'ALL';

  @override
  Widget build(BuildContext context) {
    final safetyProvider = Provider.of<SafetyProvider>(context);
    final allResources = safetyProvider.emergencyResources;

    final filtered = allResources.filter((r) {
      if (_selectedCategory == 'ALL') return true;
      return r.category == _selectedCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Emergency Help'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryViolet),
            onPressed: () => safetyProvider.refreshSafetyContext(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All Resources'),
                  _buildFilterChip('POLICE', 'Police Stations'),
                  _buildFilterChip('HOSPITAL', 'Hospitals & Trauma'),
                  _buildFilterChip('WOMEN_SHELTER', 'One-Stop Centers'),
                  _buildFilterChip('SAFE_PLACE', 'Safe Havens'),
                ],
              ),
            ),

            // Resource List
            Expanded(
              child: filtered.isNotEmpty
                  ? ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final res = filtered[index];
                        return _buildResourceCard(context, res);
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No verified facilities in this filter', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Try selecting All Resources.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = key),
        selectedColor: AppColors.primaryViolet,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.darkCharcoal,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        checkmarkColor: Colors.white,
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? AppColors.primaryViolet : AppColors.borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildResourceCard(BuildContext context, EmergencyResource res) {
    IconData icon;
    Color iconColor;

    switch (res.category) {
      case 'POLICE':
        icon = Icons.local_police_rounded;
        iconColor = AppColors.primaryViolet;
        break;
      case 'HOSPITAL':
        icon = Icons.local_hospital_rounded;
        iconColor = AppColors.emergencyCoral;
        break;
      case 'WOMEN_SHELTER':
        icon = Icons.health_and_safety_rounded;
        iconColor = AppColors.successEmerald;
        break;
      default:
        icon = Icons.shield_rounded;
        iconColor = AppColors.warningAmber;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              res.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkCharcoal),
                            ),
                          ),
                          if (res.distanceKm != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Text(
                                '${res.distanceKm!.toStringAsFixed(1)} km',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(res.address, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text('Hours: ${res.operatingHours}', style: const TextStyle(fontSize: 11, color: AppColors.successEmerald, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.borderLight),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling ${res.name}: ${res.phone}')),
                      );
                    },
                    icon: const Icon(Icons.phone, size: 16),
                    label: Text('Call ${res.phone}', style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.primaryViolet),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening GPS navigation to ${res.name}')),
                      );
                    },
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('Directions', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension ListFilter<T> on List<T> {
  List<T> filter(bool Function(T) test) {
    final result = <T>[];
    for (var element in this) {
      if (test(element)) result.add(element);
    }
    return result;
  }
}
