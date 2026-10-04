import 'package:flutter/material.dart';

class NavigationControls extends StatelessWidget {
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onReset;
  final ValueChanged<double>? onSpeedChanged;
  final double speedMultiplier;
  final double remainingDistanceMeters;
  final double remainingDurationSeconds;
  final bool isNavigating;
  final bool isPaused;
  final bool hasRoute;

  const NavigationControls({
    super.key,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onReset,
    this.onSpeedChanged,
    required this.speedMultiplier,
    required this.remainingDistanceMeters,
    required this.remainingDurationSeconds,
    required this.isNavigating,
    required this.isPaused,
    required this.hasRoute,
  });

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remMins = minutes % 60;
      return '${hours}h ${remMins}m';
    }
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Route metrics bar (Distance & ETA)
            if (hasRoute) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Remaining Distance',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDistance(remainingDistanceMeters),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Container(height: 30, width: 1, color: Colors.grey.shade300),
                  Column(
                    children: [
                      const Text(
                        'Remaining Time',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDuration(remainingDurationSeconds),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
            ],

            // Action controls (Start, Pause/Resume, Reset, Speed)
            Row(
              children: [
                // Speed Selector Chips
                Wrap(
                  spacing: 4,
                  children: [1.0, 2.0, 5.0].map((speed) {
                    final isSelected = speedMultiplier == speed;
                    return ChoiceChip(
                      label: Text('${speed.toInt()}x'),
                      selected: isSelected,
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => onSpeedChanged?.call(speed),
                    );
                  }).toList(),
                ),

                const Spacer(),

                // Reset Button
                if (hasRoute) ...[
                  IconButton(
                    onPressed: onReset,
                    icon: const Icon(Icons.replay),
                    tooltip: 'Reset Navigation',
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                ],

                // Start / Pause / Resume Primary Button
                if (!isNavigating && !isPaused)
                  ElevatedButton.icon(
                    onPressed: hasRoute ? onStart : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else if (isNavigating)
                  ElevatedButton.icon(
                    onPressed: onPause,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else if (isPaused)
                  ElevatedButton.icon(
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
