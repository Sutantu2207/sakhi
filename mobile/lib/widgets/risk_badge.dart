import 'package:flutter/material.dart';
import '../core/constants.dart';

class RiskBadge extends StatelessWidget {
  final String category;
  final bool isCompact;

  const RiskBadge({
    super.key,
    required this.category,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    Color dotColor;
    String label;

    switch (category) {
      case 'higher_reported_risk':
        bg = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        dotColor = AppColors.emergencyCoral;
        label = 'Higher reported risk';
        break;
      case 'moderate_reported_risk':
        bg = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        dotColor = AppColors.warningAmber;
        label = 'Moderate reported risk';
        break;
      case 'lower_reported_risk':
      default:
        bg = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        dotColor = AppColors.successEmerald;
        label = 'Lower reported risk';
        break;
    }

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
