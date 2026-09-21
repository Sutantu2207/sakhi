import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/journey_provider.dart';
import '../providers/sos_provider.dart';
import '../providers/safety_provider.dart';
import '../widgets/sos_button.dart';
import '../widgets/risk_badge.dart';
import '../widgets/countdown_dialog.dart';
import 'journey_screen.dart';
import 'sos_active_screen.dart';
import 'nearby_help_screen.dart';
import 'incident_report_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _handleSOSTap(BuildContext context) {
    final sosProvider = Provider.of<SOSProvider>(context, listen: false);
    sosProvider.initiateSOSCountdown(
      onComplete: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SOSActiveScreen()),
        );
      },
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CountdownDialog(
        onTriggered: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SOSActiveScreen()),
          );
        },
      ),
    );
  }

  void _showStartJourneyDialog(BuildContext context) {
    final destController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Travel Journey', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sakhi monitors your travel path, tracks contextual environmental risk, and enables temporary live sharing.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: destController,
              decoration: const InputDecoration(
                labelText: 'Destination (e.g. Home, College)',
                prefixIcon: Icon(Icons.pin_drop_outlined, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final dest = destController.text.trim();
              Navigator.pop(ctx);
              final journeyProvider = Provider.of<JourneyProvider>(context, listen: false);
              final ok = await journeyProvider.startJourney(
                destinationName: dest.isEmpty ? 'Travel Route' : dest,
              );
              if (context.mounted && ok) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JourneyScreen()),
                );
              }
            },
            child: const Text('Start Tracking'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final journeyProvider = Provider.of<JourneyProvider>(context);
    final safetyProvider = Provider.of<SafetyProvider>(context);
    final sosProvider = Provider.of<SOSProvider>(context);

    final user = auth.currentUser;
    final risk = safetyProvider.currentRisk;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()}, ${user?.fullName.split(' ').first ?? 'Friend'}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Your safety companion',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.softLavender,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.shield, color: AppColors.primaryViolet, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Active SOS Banner if already active
              if (sosProvider.isSOSActive) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SOSActiveScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyCoral,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: AppColors.emergencyCoral.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.white),
                            SizedBox(width: 10),
                            Text('SOS ALERT ACTIVE — View Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Active Journey Card if ongoing
              if (journeyProvider.activeJourney != null) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JourneyScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryViolet,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('JOURNEY IN PROGRESS', style: TextStyle(color: AppColors.softLavender, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            const SizedBox(height: 4),
                            Text(
                              journeyProvider.activeJourney!.destinationName ?? 'Live Route',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Current Area Reported Risk Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Current Area Reported Risk',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
                          ),
                          RiskBadge(
                            category: risk?.riskCategory ?? 'lower_reported_risk',
                            isCompact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        risk?.summary ?? 'Based on available verified reports and emergency infrastructure.',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                      ),
                      if (risk?.contributingFactors != null && risk!.contributingFactors.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '• ${risk.contributingFactors.first}',
                          style: const TextStyle(fontSize: 11, color: AppColors.darkCharcoal, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // SOS Emergency Button
              Center(
                child: SOSButton(
                  onTap: () => _handleSOSTap(context),
                  size: 136,
                ),
              ),
              const SizedBox(height: 28),

              // Quick Action Cards Grid
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'Start Journey',
                      subtitle: 'Real-time safety trail',
                      icon: Icons.directions_walk_rounded,
                      color: AppColors.primaryViolet,
                      onTap: () => _showStartJourneyDialog(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'Report Incident',
                      subtitle: 'Street harassment / lighting',
                      icon: Icons.report_problem_outlined,
                      color: AppColors.warningAmber,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const IncidentReportScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'Nearby Help',
                      subtitle: 'Police & Hospitals',
                      icon: Icons.local_police_outlined,
                      color: AppColors.emergencyCoral,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NearbyHelpScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'Safety Network',
                      subtitle: '${safetyProvider.nearbyNetworkCount} nearby users',
                      icon: Icons.hub_outlined,
                      color: AppColors.successEmerald,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.primaryViolet,
                            content: Text(
                              user?.safetyNetworkOptIn == true
                                  ? '${safetyProvider.nearbyNetworkCount} opted-in participants in your vicinity.'
                                  : 'Opt into Safety Network in Privacy Settings to join community presence.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkCharcoal),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
