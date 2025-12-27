import 'package:flutter/material.dart';

class CustomProgressBar extends StatelessWidget {
  final int current;
  final int target;
  final Color color;

  const CustomProgressBar({
    super.key,
    required this.current,
    required this.target,
    this.color = const Color(0xFF6C63FF),
  });

  @override
  Widget build(BuildContext context) {
    // Yüzde hesabı (0.0 ile 1.0 arası)
    double percentage = target == 0 ? 0 : (current / target);
    if (percentage > 1) percentage = 1; // %100'ü geçmesin

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$current dk",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "$target dk hedef",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
