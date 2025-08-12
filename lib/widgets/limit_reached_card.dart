import 'package:flutter/material.dart';

class LimitReachedCard extends StatelessWidget {
  final Duration timeRemaining;

  const LimitReachedCard({super.key, required this.timeRemaining});

  @override
  Widget build(BuildContext context) {
    final h = timeRemaining.inHours;
    final m = timeRemaining.inMinutes % 60;

    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_clock, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            "⏳ Limit reached",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          Text(
            "Come back in ${h}h ${m}m",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
