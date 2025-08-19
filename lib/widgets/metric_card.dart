// lib/widgets/dashboard/metric_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isLive;
  final Color? liveColor;
  final Gradient? gradient;

  const MetricCard({
    Key? key,
    required this.title,
    required this.value,
    required this.change,
    this.isLive = false,
    this.liveColor,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontSize: 14,
                    color: gradient != null
                        ? Colors.white70
                        : Colors.grey.shade600),
              ),
              if (isLive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: liveColor ?? Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Live',
                      style: TextStyle(
                          fontSize: 10,
                          color: liveColor != null ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: gradient != null ? Colors.white : null)),
          const SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(
                fontSize: 12,
                color: gradient != null ? Colors.white70 : Colors.grey),
          ),
        ],
      ),
    );
  }
}