import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/safety_provider.dart';
import '../services/location_service.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  String _category = 'POOR_LIGHTING';
  String _severity = 'MEDIUM';
  final _descController = TextEditingController();
  bool _isAnonymous = true;
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = [
    {'key': 'POOR_LIGHTING', 'label': 'Poor Street Lighting'},
    {'key': 'HARASSMENT', 'label': 'Street Harassment'},
    {'key': 'STALKING', 'label': 'Suspicious Stalking / Tailing'},
    {'key': 'UNSAFE_AREA', 'label': 'Isolated / Unsafe Area'},
    {'key': 'ASSAULT', 'label': 'Physical Assault'},
    {'key': 'CYBERCRIME', 'label': 'Online Harassment / Cybercrime'},
    {'key': 'OTHER', 'label': 'Other Safety Concern'},
  ];

  Future<void> _submit() async {
    final desc = _descController.text.trim();
    if (desc.isEmpty || desc.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a brief description of the concern.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final pos = await LocationService.getCurrentLocation();
      final safetyProvider = Provider.of<SafetyProvider>(context, listen: false);

      final ok = await safetyProvider.submitIncident(
        category: _category,
        severity: _severity,
        description: desc,
        latitude: pos.latitude,
        longitude: pos.longitude,
        isAnonymous: _isAnonymous,
      );

      if (!mounted) return;

      if (ok) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Report Submitted', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              'Thank you for helping keep the community safe. Your report has been submitted to moderators for verification.',
              style: TextStyle(fontSize: 13),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit report. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Safety Concern')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What happened or what did you observe?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
              ),
              const SizedBox(height: 10),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Incident Category',
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c['key'], child: Text(c['label']!));
                }).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),

              // Severity
              const Text(
                'Perceived Severity Level',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'].map((sev) {
                  final isSelected = _severity == sev;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Text(sev, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.darkCharcoal)),
                        selected: isSelected,
                        selectedColor: sev == 'CRITICAL' || sev == 'HIGH' ? AppColors.emergencyCoral : AppColors.primaryViolet,
                        onSelected: (_) => setState(() => _severity = sev),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Description
              const Text(
                'Details & Location Description',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe what occurred, landmarks, lighting, or specific safety concerns...',
                ),
              ),
              const SizedBox(height: 20),

              // Anonymous Switch
              Card(
                child: SwitchListTile(
                  title: const Text('Submit Anonymously', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Your name and profile will not be linked to this report.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  value: _isAnonymous,
                  activeColor: AppColors.primaryViolet,
                  onChanged: (val) => setState(() => _isAnonymous = val),
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Confidential Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
