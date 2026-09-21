import 'package:flutter/material.dart';
import '../core/constants.dart';

class SOSButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const SOSButton({
    super.key,
    required this.onTap,
    this.size = 130.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Color(0xFFEF4444),
              AppColors.emergencyCoral,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.emergencyCoral.withOpacity(0.35),
              blurRadius: 24,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SOS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'EMERGENCY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
