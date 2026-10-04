import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';

class DevBadgeBanner extends StatelessWidget {
  const DevBadgeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.instance.showDevBadge) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 12,
      right: 12,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        color: Colors.redAccent.shade700,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.developer_mode, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text(
                'DEV',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
