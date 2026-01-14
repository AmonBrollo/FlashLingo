import 'package:flutter/material.dart';

class FinishedDeckCard extends StatelessWidget {
  final String message;
  final VoidCallback? onBackToDeck;
  
  const FinishedDeckCard({
    super.key, 
    required this.message,
    this.onBackToDeck,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 50,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 32),
          
          // Back to decks button
          if (onBackToDeck != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onBackToDeck,
                icon: const Icon(Icons.arrow_back),
                label: const Text(
                  'Back to Decks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}