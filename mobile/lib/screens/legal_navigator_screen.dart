import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/safety_provider.dart';
import '../models/resource.dart';

class LegalNavigatorScreen extends StatelessWidget {
  const LegalNavigatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final safetyProvider = Provider.of<SafetyProvider>(context);
    final resources = safetyProvider.supportResources;

    return Scaffold(
      appBar: AppBar(title: const Text('Legal & Emergency Support')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Disclaimer Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.softLavender.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryViolet.withOpacity(0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.primaryViolet, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Official legal and helpline directory. Sakhi provides informational navigation toward authorized resources, not formal legal counsel.',
                      style: TextStyle(fontSize: 11, color: AppColors.primaryViolet, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Emergency Direct Dialers
            const Text('National Emergency Helplines', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildQuickDialCard(context, '112', 'Emergency Police / Medical', AppColors.emergencyCoral),
                const SizedBox(width: 10),
                _buildQuickDialCard(context, '1091', 'Women in Distress', AppColors.primaryViolet),
                const SizedBox(width: 10),
                _buildQuickDialCard(context, '1930', 'National Cybercrime', AppColors.warningAmber),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Actionable Rights & Support Categories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ...resources.map((res) => _buildResourceDetailCard(context, res)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDialCard(BuildContext context, String number, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dialing $number ($label)...')),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              Text(number, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceDetailCard(BuildContext context, SupportResource res) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
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
                    color: AppColors.primaryViolet.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    res.category.replaceAll('_', ' '),
                    style: const TextStyle(color: AppColors.primaryViolet, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(res.jurisdiction, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 8),
            Text(res.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkCharcoal)),
            const SizedBox(height: 2),
            Text(res.organization, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(res.description, style: const TextStyle(fontSize: 12, color: AppColors.darkCharcoal, height: 1.4)),

            if (res.actionableSteps != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  res.actionableSteps!,
                  style: const TextStyle(fontSize: 11, color: AppColors.darkCharcoal, height: 1.4),
                ),
              ),
            ],

            if (res.phone != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling helpline ${res.phone}...')),
                  );
                },
                icon: const Icon(Icons.phone, size: 14),
                label: Text('Call Helpline (${res.phone})', style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  side: const BorderSide(color: AppColors.primaryViolet),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
