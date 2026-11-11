import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

const complaintDetailDivider = Divider(
  height: 33,
  thickness: 1,
  color: HiveColors.raised,
);

Widget complaintPanel(
  Widget child, {
  Color backgroundColor = HiveColors.surface,
}) => DecoratedBox(
  decoration: BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Padding(padding: const EdgeInsets.all(16), child: child),
);
Widget complaintEmpty(
  String title,
  String body, {
  Widget? action,
  bool loading = false,
}) => Padding(
  padding: const EdgeInsets.all(24),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (loading) CircularProgressIndicator(semanticsLabel: title),
      const SizedBox(height: 16),
      Text(title, textAlign: TextAlign.center),
      if (body.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center),
      ],
      ?action,
    ],
  ),
);
Widget complaintFeedback(
  String message, {
  bool error = false,
  Widget? action,
  Color backgroundColor = HiveColors.surface,
}) => Semantics(
  liveRegion: true,
  child: complaintPanel(
    backgroundColor: backgroundColor,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              error ? Icons.error_outline : Icons.info_outline,
              color: error ? HiveColors.danger : HiveColors.secondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: error ? HiveColors.danger : HiveColors.body,
                ),
              ),
            ),
          ],
        ),
        ?action,
      ],
    ),
  ),
);
