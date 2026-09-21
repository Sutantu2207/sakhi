import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/journey_provider.dart';
import '../providers/safety_provider.dart';
import '../widgets/risk_badge.dart';
import 'nearby_help_screen.dart';

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  void _showShareDialog(BuildContext context, JourneyProvider journeyProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share My Live Journey', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select duration for temporary live-location sharing. The link will expire automatically.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ...[15, 30, 60].map((mins) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.timer_outlined, color: AppColors.primaryViolet),
                  title: Text('$mins Minutes', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final ok = await journeyProvider.createShare(durationMinutes: mins);
                    if (context.mounted && ok && journeyProvider.activeShare != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primaryViolet,
                          content: Text('Temporary link created: ${journeyProvider.activeShare!.shareToken}'),
                        ),
                      );
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journeyProvider = Provider.of<JourneyProvider>(context);
    final safetyProvider = Provider.of<SafetyProvider>(context);
    final journey = journeyProvider.activeJourney;

    if (journey == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Journey Safety')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_walk, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('No Active Journey', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Start a journey from the Home tab to begin real-time safety tracking.', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    final durationMins = DateTime.now().difference(journey.startTime).inMinutes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Journey Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primaryViolet),
            onPressed: () => _showShareDialog(context, journeyProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Top Stats Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                journey.destinationName ?? 'Safe Travel Route',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Started ${journey.startTime.hour.toString().padLeft(2, '0')}:${journey.startTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successEmerald.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('ACTIVE', style: TextStyle(color: AppColors.successEmerald, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: AppColors.borderLight),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Distance', '${journey.totalDistanceKm.toStringAsFixed(2)} km'),
                          _buildStatItem('Elapsed', '$durationMins min'),
                          _buildStatItem('GPS Status', 'High Accuracy'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Area Risk Indicator Along Route
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Route Risk Indicator', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          RiskBadge(category: safetyProvider.currentRisk?.riskCategory ?? 'lower_reported_risk', isCompact: true),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline, color: AppColors.primaryViolet, size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Contextual Risk', style: TextStyle(fontWeight: FontWeight.bold)),
                              content: Text(
                                safetyProvider.currentRisk?.summary ?? 'Risk evaluated based on verified local incident data.',
                                style: const TextStyle(fontSize: 13),
                              ),
                              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Active Sharing Banner if enabled
              if (journeyProvider.activeShare != null && !journeyProvider.activeShare!.isRevoked) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.softLavender.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryViolet.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, color: AppColors.primaryViolet, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Temporary live sharing active. Auto-expires upon journey end.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primaryViolet),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NearbyHelpScreen()),
                        );
                      },
                      icon: const Icon(Icons.local_police_outlined, size: 18),
                      label: const Text('Nearby Help'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showShareDialog(context, journeyProvider),
                      icon: const Icon(Icons.share_location, size: 18),
                      label: const Text('Share Link'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // End Journey Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final ok = await journeyProvider.endJourney();
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Journey completed safely.')),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkCharcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('End Journey Safely'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkCharcoal)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}
