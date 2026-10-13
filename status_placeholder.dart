import 'package:flutter/material.dart';

/// Honest placeholder for features that are planned but not yet implemented.
class StatusPlaceholder extends StatelessWidget {
  const StatusPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.status,
  });

  final IconData icon;
  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                colors: [scheme.primary, scheme.secondary],
              ).createShader(rect),
              child: Icon(icon, size: 72, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              status,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
