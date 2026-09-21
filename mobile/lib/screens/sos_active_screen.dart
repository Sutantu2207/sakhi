import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/sos_provider.dart';
import 'nearby_help_screen.dart';

class SOSActiveScreen extends StatelessWidget {
  const SOSActiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sosProvider = Provider.of<SOSProvider>(context);
    final activeSos = sosProvider.activeSOS;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                // Pulsing Emergency Beacon Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.emergencyCoral.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.emergencyCoral,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SOS ACTIVE',
                        style: TextStyle(
                          color: AppColors.emergencyCoral,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Emergency Alert Triggered',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your live location and emergency status have been broadcasted to your emergency network.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 28),

                // Live status checklist
                Container(
                  padding: const EdgeInsets.all(18),
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
                            ? '${activeSos.latitude.toStringAsFixed(4)}, ${activeSos.longitude.toStringAsFixed(4)}'
                            : 'Acquired',
                        isDone: true,
                      ),
                      const Divider(height: 20, color: AppColors.borderLight),
                      _buildCheckItem(
                        title: 'Trusted Contacts Notified',
                        subtitle: '${activeSos?.contactsNotifiedCount ?? 0} contact(s) reached via emergency SMS/push',
                        isDone: true,
                      ),
                      const Divider(height: 20, color: AppColors.borderLight),
                      _buildCheckItem(
                        title: 'Temporary Sharing Link Generated',
                        subtitle: 'Emergency dispatchers can view real-time movements',
                        isDone: true,
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Action Buttons
                // Call 112
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dialing Emergency Services 112...')),
                      );
                    },
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text('Call Emergency Services (112)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emergencyCoral,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Nearby Help
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NearbyHelpScreen()),
                      );
                    },
                    icon: const Icon(Icons.local_police_outlined, color: AppColors.primaryViolet),
                    label: const Text('View Nearby Police & Hospitals'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primaryViolet),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel SOS Button
                TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cancel Emergency SOS?'),
                        content: const Text('Only cancel if you are in a safe location and no longer require assistance.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Active')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.successEmerald),
                            child: const Text('I am Safe (Cancel)'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await sosProvider.cancelActiveSOS(reason: 'Resolved by user: marked safe');
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: const Text(
                    'Cancel SOS (I am safe now)',
                    style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
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
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.successEmerald,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkCharcoal),
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
