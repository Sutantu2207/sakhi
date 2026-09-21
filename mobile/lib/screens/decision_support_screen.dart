import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'nearby_help_screen.dart';
import 'incident_report_screen.dart';
import 'legal_navigator_screen.dart';

class DecisionSupportScreen extends StatefulWidget {
  const DecisionSupportScreen({super.key});

  @override
  State<DecisionSupportScreen> createState() => _DecisionSupportScreenState();
}

class _DecisionSupportScreenState extends State<DecisionSupportScreen> {
  int _step = 0; // 0: Immediate danger check, 1: Situation selector, 2: Action advice
  String? _selectedIssue;

  final List<Map<String, dynamic>> _situations = [
    {
      'id': 'FOLLOWED',
      'title': "I'm being followed or stalked",
      'icon': Icons.directions_walk,
      'color': Color(0xFFE63946),
      'immediateAction': 'Head directly into a well-lit shop, metro station, or crowded venue.',
      'helpline': '112',
      'helplineName': 'Police Dispatch',
      'routeTo': 'nearby',
    },
    {
      'id': 'HARASSED',
      'title': "I'm facing street harassment / catcalling",
      'icon': Icons.record_voice_over,
      'color': Color(0xFFF4A261),
      'immediateAction': 'Do not isolate yourself. Move toward authority figures (CISF/traffic police) or dial 1091.',
      'helpline': '1091',
      'helplineName': 'Women Helpline',
      'routeTo': 'report',
    },
    {
      'id': 'DOMESTIC',
      'title': 'Domestic violence or threats at home',
      'icon': Icons.home,
      'color': Color(0xFF7B2CBF),
      'immediateAction': 'Reach out to Sakhi One-Stop Crisis Centres for temporary refuge, medical care, and legal protection.',
      'helpline': '181',
      'helplineName': 'Women Crisis Helpline',
      'routeTo': 'legal',
    },
    {
      'id': 'CYBERCRIME',
      'title': 'Online blackmail, morphed images, or fraud',
      'icon': Icons.phonelink_lock,
      'color': Color(0xFF0077B6),
      'immediateAction': 'Preserve all screenshots, message timestamps, and profile URLs before blocking. Report promptly to 1930.',
      'helpline': '1930',
      'helplineName': 'National Cybercrime Helpline',
      'routeTo': 'legal',
    },
    {
      'id': 'MEDICAL',
      'title': 'I need immediate medical care',
      'icon': Icons.local_hospital,
      'color': Color(0xFF2A9D8F),
      'immediateAction': 'Locate nearest 24/7 government trauma care centre or call 112 for ambulance dispatch.',
      'helpline': '112',
      'helplineName': 'Ambulance & Trauma',
      'routeTo': 'nearby',
    },
    {
      'id': 'UNSAFE_AREA',
      'title': 'I feel unsafe walking through this dark/isolated area',
      'icon': Icons.nightlight_round,
      'color': Color(0xFF3A1C71),
      'immediateAction': 'Activate Safe Journey Guard to broadcast your live GPS to your safety circle until you reach safety.',
      'helpline': '112',
      'helplineName': 'Police',
      'routeTo': 'journey',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Guided Safety Assistance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.darkCharcoal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _step == 0 ? _buildImmediateDangerStep() : _buildSituationStep(),
      ),
    );
  }

  Widget _buildImmediateDangerStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.emergencyCoral.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shield_outlined, size: 64, color: AppColors.emergencyCoral),
        ),
        const SizedBox(height: 24),
        const Text(
          'Are you in immediate physical danger right now?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
        ),
        const SizedBox(height: 12),
        const Text(
          'If someone is actively threatening or attacking you, do not hesitate to alert authorities immediately.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 36),

        // YES Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Open Emergency Calling
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.emergencyCoral,
                  content: Text('Dialing National Emergency Police (112)...'),
                ),
              );
            },
            icon: const Icon(Icons.phone_in_talk, size: 20),
            label: const Text('YES — CALL 112 POLICE NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyCoral,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // NO Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _step = 1;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryViolet,
              side: const BorderSide(color: AppColors.primaryViolet, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text("NO — I'M SAFE FOR NOW, GUIDE ME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildSituationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What kind of situation are you facing?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select the option that best describes your situation for clear, actionable steps:',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: _situations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final sit = _situations[index];
              final Color color = sit['color'];

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showAdviceDialog(sit),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(sit['icon'], color: color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            sit['title'],
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.darkCharcoal),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAdviceDialog(Map<String, dynamic> sit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(sit['icon'], color: sit['color'], size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(sit['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text('ACTIONABLE SAFETY ADVICE:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Text(sit['immediateAction'], style: const TextStyle(fontSize: 14, color: AppColors.darkCharcoal, height: 1.4)),
            const SizedBox(height: 20),

            // Emergency Calling Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primaryViolet,
                      content: Text('Dialing ${sit['helplineName']} (${sit['helpline']})...'),
                    ),
                  );
                },
                icon: const Icon(Icons.phone, size: 16),
                label: Text('CALL ${sit['helplineName'].toUpperCase()} (${sit['helpline']})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Navigation Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (sit['routeTo'] == 'nearby') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyHelpScreen()));
                  } else if (sit['routeTo'] == 'report') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidentReportScreen()));
                  } else if (sit['routeTo'] == 'legal') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalNavigatorScreen()));
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('View Official Resources & Protection Rights'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
