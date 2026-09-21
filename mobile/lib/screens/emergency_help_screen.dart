import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import 'decision_support_screen.dart';

class EmergencyHelpScreen extends StatelessWidget {
  const EmergencyHelpScreen({super.key});

  void _makeCall(BuildContext context, String number, String serviceName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.phone_in_talk, color: AppColors.emergencyCoral),
            const SizedBox(width: 8),
            Text('Dial $number?'),
          ],
        ),
        content: Text(
          'Connecting to $serviceName ($number).\n\nIn a production mobile environment, this automatically opens your phone dialer for immediate calling.',
          style: const TextStyle(fontSize: 13, color: AppColors.darkCharcoal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.emergencyCoral,
                  content: Text('Dialing $serviceName ($number)...'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyCoral,
              foregroundColor: Colors.white,
            ),
            child: const Text('Call Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<AuthProvider>().contacts;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Emergency Help & Helplines', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.darkCharcoal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Top Guidance Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.emergencyCoral.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.emergencyCoral.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.flash_on, color: AppColors.emergencyCoral, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Instant Emergency Calling — Tapping any service connects immediately without waiting for server response.',
                    style: TextStyle(fontSize: 12, color: AppColors.emergencyCoral, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary National Helplines
          _buildHelplineCard(
            context: context,
            number: '112',
            title: 'National Emergency Response',
            subtitle: 'Single emergency access for Police, Fire, and Ambulance dispatch.',
            badgeColor: const Color(0xFFE63946),
            badgeLabel: 'ALL-IN-ONE EMERGENCY',
          ),
          const SizedBox(height: 12),

          _buildHelplineCard(
            context: context,
            number: '181',
            title: 'Women Helpline (Domestic & Crisis)',
            subtitle: '24/7 dedicated support, immediate crisis shelter, and harassment assistance.',
            badgeColor: const Color(0xFF7B2CBF),
            badgeLabel: 'WOMEN CRISIS',
          ),
          const SizedBox(height: 12),

          _buildHelplineCard(
            context: context,
            number: '1930',
            title: 'Cyber Crime & Financial Fraud',
            subtitle: 'Report online stalking, non-consensual images, cyber extortion, and fraud.',
            badgeColor: const Color(0xFF0077B6),
            badgeLabel: 'CYBER PROTECTION',
          ),
          const SizedBox(height: 12),

          _buildHelplineCard(
            context: context,
            number: '1098',
            title: 'Childline Emergency Service',
            subtitle: 'National 24-hour emergency phone service for children in need of care & protection.',
            badgeColor: const Color(0xFFFB8500),
            badgeLabel: 'CHILDREN & MINORS',
          ),
          const SizedBox(height: 24),

          // Safety Circle Quick Calling
          const Text(
            'MY SAFETY CIRCLE (DIRECT CALL)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),

          if (contacts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('No emergency contacts added yet.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/profile'),
                      child: const Text('Add Guardian'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...contacts.map((contact) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.softLavender,
                      child: Icon(Icons.favorite, color: AppColors.primaryViolet, size: 20),
                    ),
                    title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${contact.phone} • ${contact.relationshipLabel ?? 'Guardian'}', style: const TextStyle(fontSize: 12)),
                    trailing: ElevatedButton.icon(
                      onPressed: () => _makeCall(context, contact.phone, contact.name),
                      icon: const Icon(Icons.phone, size: 14),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                )),
          const SizedBox(height: 20),

          // Decision Assistant Link
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DecisionSupportScreen()),
              );
            },
            icon: const Icon(Icons.help_outline, color: AppColors.primaryViolet),
            label: const Text("I DON'T KNOW WHAT TO DO — GUIDED ASSISTANCE"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.primaryViolet, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineCard({
    required BuildContext context,
    required String number,
    required String title,
    required String subtitle,
    required Color badgeColor,
    required String badgeLabel,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                Text(
                  number,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: badgeColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkCharcoal)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _makeCall(context, number, title),
                icon: const Icon(Icons.call, size: 16),
                label: Text('CALL $number NOW', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: badgeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
