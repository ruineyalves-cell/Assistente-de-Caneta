import 'package:flutter/material.dart';

class StreakBadge extends StatelessWidget {
  final int days;
  final String? title;

  const StreakBadge({
    Key? key,
    required this.days,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepPurple.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (title != null)
              Text(
                title!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            if (title != null) const SizedBox(height: 8),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple.withOpacity(0.2),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 28)),
                    Text(
                      '$days',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              days == 1 ? '$days dia' : '$days dias',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Mantendo o ritmo!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
