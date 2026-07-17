import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ScoreCard extends StatelessWidget {
  final int score; // 0-100
  final String? label;
  final Color? backgroundColor;

  const ScoreCard({
    Key? key,
    required this.score,
    this.label,
    this.backgroundColor,
  }) : super(key: key);

  Color _getScoreColor() {
    if (score >= 90) return AppColors.verdeConfirma;
    if (score >= 75) return Colors.lightGreen;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return AppColors.vermelhoAlerta;
  }

  String _getScoreLabel() {
    if (score >= 90) return 'Excelente! 🌟';
    if (score >= 75) return 'Muito bom! ✅';
    if (score >= 60) return 'Bom 👍';
    if (score >= 40) return 'Precisa melhorar 🔄';
    return 'Crítico 🚨';
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor();

    return Card(
      color: backgroundColor ?? scoreColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (label != null)
              Text(
                label!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            if (label != null) const SizedBox(height: 12),
            Text(
              '$score%',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getScoreLabel(),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: score / 100,
              backgroundColor: scoreColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }
}
