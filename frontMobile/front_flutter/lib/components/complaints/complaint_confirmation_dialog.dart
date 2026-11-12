import 'package:flutter/material.dart';

import '../../lang/complaint_strings.dart';

Future<bool> showComplaintConfirmation(
  BuildContext context,
  ComplaintStrings strings,
  Listenable changes, {
  required String title,
  required String body,
  required String action,
  required bool Function() isValid,
}) async {
  bool closing = false;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0x99000000),
        builder: (dialogContext) => AnimatedBuilder(
          animation: changes,
          builder: (context, _) {
            final valid = isValid();
            if (!valid && !closing) {
              closing = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (dialogContext.mounted &&
                    ModalRoute.of(dialogContext)?.isCurrent == true) {
                  Navigator.pop(dialogContext, false);
                }
              });
            }
            return AlertDialog(
              title: Text(strings.text(title)),
              content: Text(strings.text(body)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(strings.text('cancel')),
                ),
                FilledButton(
                  onPressed: valid
                      ? () => Navigator.pop(dialogContext, true)
                      : null,
                  child: Text(strings.text(action)),
                ),
              ],
            );
          },
        ),
      ) ??
      false;
}
