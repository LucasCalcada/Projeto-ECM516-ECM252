import 'package:flutter/material.dart';

import '../../lang/app_localizations.dart';
import '../../types/api_failure.dart';

class RequestFeedback extends StatelessWidget {
  const RequestFeedback({super.key, this.failure, this.message, this.onRetry});

  final ApiFailure? failure;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              failure == null ? message! : strings.error(failure!),
              style: TextStyle(
                color: failure == null
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.error,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(strings.text('retry')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
