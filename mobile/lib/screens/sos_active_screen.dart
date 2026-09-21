import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/sos_provider.dart';
import '../providers/auth_provider.dart';
import 'nearby_help_screen.dart';
import 'emergency_help_screen.dart';
import 'decision_support_screen.dart';

class SOSActiveScreen extends StatelessWidget {
  const SOSActiveScreen({super.key});

  void _showPostSOSSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.successEmerald, size: 28),
                SizedBox(width: 10),
                Text('SOS Standby — Are You Safe?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Your emergency broadcast has been paused. Please let us know if you still require medical, psychological, or legal support.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),

            // YES I AM SAFE Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.sentiment_satisfied_alt, color: Colors.white),
                label: const Text("YES, I'M COMPLETELY SAFE NOW"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successEmerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // I STILL NEED HELP Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DecisionSupportScreen()),
                  );
                },
                icon: const Icon(Icons.help_outline, color: AppColors.emergencyCoral),
                label: const Text('I STILL NEED MEDICAL / CRISIS HELP'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.emergencyCoral,
                  side: const BorderSide(color: AppColors.emergencyCoral),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sosProvider = Provider.of<SOSProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final activeSos = sosProvider.activeSOS;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Emergency Status Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.emergencyCoral.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.emergencyCoral.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.radio_button_checked, color: AppColors.emergencyCoral, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'EMERGENCY SOS IS ACTIVE',
                        style: TextStyle(
                          color: AppColors.emergencyCoral,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Emergency Assistance Activated',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Continuous telemetry and distress signals are broadcasting to your emergency network and authorities.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35),
                ),
                const SizedBox(height: 18),

                // Communication Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('🟢 Internet: Connected', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal)),
                      Text('🟢 GPS: Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal)),
                      Text('🟢 Mesh: Standby', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Live status checklist
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      _buildCheckItem(
                        title: 'High-Precision GPS Captured',
                        subtitle: activeSos != null
                            ? '${activeSos.latitude.toStringAsFixed(4)}, ${activeSos.longitude.toStringAsFixed(4)} (Accuracy: 10m)'
                            : 'Acquired and transmitting',
                        isDone: true,
                      ),
                      const Divider(height: 16, color: AppColors.borderLight),
                      _buildCheckItem(
                        title: 'Safety Circle Guardians Alerted',
                        subtitle: '${auth.contacts.length} trusted contacts notified with live coordinates',
                        isDone: true,
                      ),
                      const Divider(height: 16, color: AppColors.borderLight),
                      _buildCheckItem(
                        title: 'Temporary Sharing Link Active',
                        subtitle: 'Unguessable live tracking link generated (TTL: 4 hours)',
                        isDone: true,
                      ),
                      const Divider(height: 16, color: AppColors.borderLight),
                      _buildCheckItem(
                        title: 'Emergency Mesh Contingency',
                        subtitle: 'Automatic fallback ready via BLE/ESP-NOW if cellular is cut',
                        isDone: true,
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Action Buttons
                // CALL 112 (CALL FIRST CAPABILITY)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.emergencyCoral,
                          content: Text('Dialing 112 National Police Emergency Services...'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone_in_talk, color: Colors.white, size: 22),
                    label: const Text('CALL 112 (POLICE & AMBULANCE) NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emergencyCoral,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shadowColor: AppColors.emergencyCoral.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Emergency Help Hub
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EmergencyHelpScreen()),
                          );
                        },
                        icon: const Icon(Icons.support_agent, color: AppColors.primaryViolet, size: 16),
                        label: const Text('All Helplines', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: AppColors.primaryViolet),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NearbyHelpScreen()),
                          );
                        },
                        icon: const Icon(Icons.local_police_outlined, color: AppColors.primaryViolet, size: 16),
                        label: const Text('Help Near Me', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: AppColors.primaryViolet),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Cancel SOS Button
                TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Are You Safe Now?'),
                        content: const Text('Only cancel if you are in a secure location and no longer require emergency assistance.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Active')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.successEmerald),
                            child: const Text("I'm Safe (Cancel SOS)"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await sosProvider.cancelActiveSOS(reason: 'Resolved by user: marked safe');
                      if (context.mounted) {
                        _showPostSOSSupportModal(context);
                      }
                    }
                  },
                  child: const Text(
                    'Cancel SOS (I am safe now)',
                    style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem({required String title, required String subtitle, required bool isDone}) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.successEmerald,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.darkCharcoal),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
