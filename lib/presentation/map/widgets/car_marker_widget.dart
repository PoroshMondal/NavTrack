import 'dart:math' as math;
import 'package:flutter/material.dart';

class CarMarkerWidget extends StatelessWidget {
  final double bearingDegrees;

  const CarMarkerWidget({
    super.key,
    required this.bearingDegrees,
  });

  @override
  Widget build(BuildContext context) {
    final angleRad = bearingDegrees * math.pi / 180.0;

    return Transform.rotate(
      angle: angleRad,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade800,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.white, width: 2),
        ),
        padding: const EdgeInsets.all(6),
        child: const Icon(
          Icons.navigation, // Arrow pointing top
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
