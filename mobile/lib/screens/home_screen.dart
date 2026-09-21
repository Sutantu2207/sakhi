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
import 'emergency_help_screen.dart';
import 'decision_support_screen.dart';
import 'profile_screen.dart';

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

  void _showShareLocationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.share_location, color: AppColors.primaryViolet, size: 24),
                SizedBox(width: 10),
                Text('Share My Live Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Generates a secure temporary link. Your trusted guardians can track your live movement until the link expires.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            const Text('SELECT DURATION:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildShareDurationChip(ctx, '15 Min'),
                const SizedBox(width: 8),
                _buildShareDurationChip(ctx, '30 Min'),
                const SizedBox(width: 8),
                _buildShareDurationChip(ctx, '1 Hour'),
                const SizedBox(width: 8),
                _buildShareDurationChip(ctx, 'Until I stop'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.primaryViolet,
                      content: Text('Temporary tracking session activated and sent to Safety Circle.'),
                    ),
                  );
                },
                icon: const Icon(Icons.link, size: 16),
                label: const Text('ACTIVATE SECURE SHARING'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareDurationChip(BuildContext ctx, String label) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: const BorderSide(color: AppColors.borderLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showStartJourneyDialog(BuildContext context) {
    final destController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Start Safe Journey', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sakhi monitors your travel path, tracks environmental reported-risk along your route, and alerts your safety circle.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: destController,
              decoration: const InputDecoration(
                labelText: 'Destination (e.g. Connaught Place, Home)',
                prefixIcon: Icon(Icons.pin_drop_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Pre-journey Safety Context:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: AppColors.successEmerald),
                SizedBox(width: 4),
                Text('Nearby Infrastructure: Police (1.2 km) • Hospital (2.1 km)', style: TextStyle(fontSize: 11, color: AppColors.darkCharcoal)),
              ],
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
                destinationName: dest.isEmpty ? 'Safe Travel Route' : dest,
              );
              if (context.mounted && ok) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JourneyScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryViolet,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Guarded Journey'),
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Brand & Safety Status Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()}, ${user?.fullName.split(' ').first ?? 'Friend'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sosProvider.isSOSActive ? AppColors.emergencyCoral : AppColors.successEmerald,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            sosProvider.isSOSActive ? 'SOS ALERT ACTIVE' : 'YOUR SAFETY STATUS: NORMAL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: sosProvider.isSOSActive ? AppColors.emergencyCoral : AppColors.successEmerald,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.softLavender,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_outline, color: AppColors.primaryViolet, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. SOS Alert Banner if ongoing
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
                        BoxShadow(
                          color: AppColors.emergencyCoral.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'EMERGENCY SOS ACTIVE — View & Call',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 3. Active Journey Card if ongoing
              if (journeyProvider.activeJourney != null) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JourneyScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryViolet,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GUARDED JOURNEY ACTIVE',
                              style: TextStyle(color: AppColors.softLavender, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              journeyProvider.activeJourney!.destinationName ?? 'Live Route',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 4. Hero Emergency SOS Section
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Are you safe right now?',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    SOSButton(
                      onTap: () => _handleSOSTap(context),
                      size: 142,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap or Press & Hold for Emergency Response',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. Emergency Actions Grid
              Row(
                children: [
                  Expanded(
                    child: _buildEmergencyActionButton(
                      context,
                      title: 'EMERGENCY HELP',
                      subtitle: 'Dial 112, 181, 1930, 1098',
                      icon: Icons.phone_in_talk,
                      color: AppColors.emergencyCoral,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EmergencyHelpScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildEmergencyActionButton(
                      context,
                      title: 'MY SAFETY CIRCLE',
                      subtitle: '${auth.contacts.length} Guardians Connected',
                      icon: Icons.people_outline,
                      color: AppColors.primaryViolet,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildEmergencyActionButton(
                      context,
                      title: 'SHARE MY LOCATION',
                      subtitle: 'Temporary link with TTL',
                      icon: Icons.share_location,
                      color: const Color(0xFF0077B6),
                      onTap: () => _showShareLocationModal(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildEmergencyActionButton(
                      context,
                      title: 'START SAFE JOURNEY',
                      subtitle: 'GPS trail & Check-ins',
                      icon: Icons.navigation_outlined,
                      color: const Color(0xFF2A9D8F),
                      onTap: () => _showStartJourneyDialog(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              _buildEmergencyActionButton(
                context,
                title: 'HELP NEAR ME (POLICE & HOSPITALS)',
                subtitle: '24/7 Verified emergency points within 15 km',
                icon: Icons.local_police_outlined,
                color: const Color(0xFFE76F51),
                isFullWidth: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NearbyHelpScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 6. Guided Decision Support Pathway
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DecisionSupportScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryViolet.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryViolet.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.help_outline, color: AppColors.primaryViolet, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "I DON'T KNOW WHAT TO DO",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryViolet),
                            ),
                            Text(
                              'Guided walkthrough for stalking, harassment, or threats',
                              style: TextStyle(fontSize: 11, color: AppColors.darkCharcoal),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primaryViolet),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 7. Contextual Environmental Risk Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Area Contextual Risk Intelligence',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
                          ),
                          RiskBadge(
                            category: risk?.riskCategory ?? 'lower_reported_risk',
                            isCompact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        risk?.summary ?? 'Environmental assessment based on verified reports and infrastructure proximity.',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 8. Communication Status & Network Telemetry Component
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.wifi, size: 14, color: AppColors.successEmerald),
                        SizedBox(width: 4),
                        Text('Internet: Online', style: TextStyle(fontSize: 10, color: AppColors.darkCharcoal, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.gps_fixed, size: 14, color: AppColors.successEmerald),
                        SizedBox(width: 4),
                        Text('GPS: High Accuracy', style: TextStyle(fontSize: 10, color: AppColors.darkCharcoal, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.hub, size: 14, color: Color(0xFF0077B6)),
                        SizedBox(width: 4),
                        Text('Mesh: Standby', style: TextStyle(fontSize: 10, color: AppColors.darkCharcoal, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyActionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.darkCharcoal),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isFullWidth)
              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
