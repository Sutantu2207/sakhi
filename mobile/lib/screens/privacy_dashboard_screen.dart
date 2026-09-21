import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/journey_provider.dart';

class PrivacyDashboardScreen extends StatefulWidget {
  const PrivacyDashboardScreen({super.key});

  @override
  State<PrivacyDashboardScreen> createState() => _PrivacyDashboardScreenState();
}

class _PrivacyDashboardScreenState extends State<PrivacyDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final journeyProvider = Provider.of<JourneyProvider>(context);
    final user = auth.currentUser;

    final isOptedIn = user?.safetyNetworkOptIn ?? false;
    final retentionDays = user?.locationRetentionDays ?? 7;
    final hasActiveShare = journeyProvider.activeShare != null && !journeyProvider.activeShare!.isRevoked;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Privacy & Data Control')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Privacy philosophy banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline, color: AppColors.primaryViolet, size: 20),
                      SizedBox(width: 8),
                      Text('Privacy-First Design', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sakhi minimizes data collection. Live GPS coordinates are only processed during active journeys and emergencies, never sold, and never exposed publicly.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Controls
            const Text('Community & Location Controls', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Community Safety Network', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text(
                      'Contribute to approximate neighborhood presence. Zero identity or coordinates broadcasted.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    value: isOptedIn,
                    activeColor: AppColors.primaryViolet,
                    onChanged: (val) async {
                      await auth.updatePrivacySettings(safetyNetworkOptIn: val);
                    },
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  ListTile(
                    title: const Text('Temporary Journey Sharing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(
                      hasActiveShare ? 'Active sharing session in progress' : 'No active session running',
                      style: TextStyle(fontSize: 11, color: hasActiveShare ? AppColors.successEmerald : AppColors.textMuted),
                    ),
                    trailing: hasActiveShare
                        ? ElevatedButton(
                            onPressed: () {
                              journeyProvider.endJourney();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emergencyCoral,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            child: const Text('Revoke', style: TextStyle(fontSize: 11)),
                          )
                        : null,
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  ListTile(
                    title: const Text('GPS Trail Retention Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('Summaries auto-expire after $retentionDays days', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    trailing: DropdownButton<int>(
                      value: retentionDays,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 3, child: Text('3 Days', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 7, child: Text('7 Days', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 14, child: Text('14 Days', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 30, child: Text('30 Days', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (val) async {
                        if (val != null) {
                          await auth.updatePrivacySettings(locationRetentionDays: val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Account Data Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.emergencyCoral),
                title: const Text('Delete Account & History', style: TextStyle(color: AppColors.emergencyCoral, fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Purges all emergency contacts, journey records, and profile data immediately.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Account?'),
                      content: const Text('This action is permanent and removes all your verified emergency contacts and travel history.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await auth.logout();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Account session purged.')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyCoral),
                          child: const Text('Delete'),
                        ),
                      ],
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
}
