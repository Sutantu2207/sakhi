import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/sos_provider.dart';

class CountdownDialog extends StatelessWidget {
  final VoidCallback onTriggered;

  const CountdownDialog({super.key, required this.onTriggered});

  @override
  Widget build(BuildContext context) {
    return Consumer<SOSProvider>(
      builder: (context, sosProvider, _) {
        return PopScope(
          canPop: false,
          onPopInvoked: (_) => sosProvider.cancelCountdown(),
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.emergencyCoral.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.emergencyCoral,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Activating Emergency SOS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Emergency services and your trusted contacts will be notified with your live GPS location.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Countdown circle
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.emergencyCoral,
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${sosProvider.countdownSeconds}',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: AppColors.emergencyCoral,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cancel / Abort button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        sosProvider.cancelCountdown();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: AppColors.darkCharcoal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel SOS (False Alarm)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
