import 'package:flutter/material.dart';

import '../../types/complaint.dart';
import '../../types/complaint_failure.dart';
import '../../lang/complaint_strings.dart';
import 'complaint_feedback.dart';
import 'complaint_status_badge.dart';

class ComplaintDetail extends StatefulWidget {
  const ComplaintDetail({
    required this.complaint,
    required this.busy,
    required this.loading,
    required this.canAct,
    required this.canRespond,
    required this.canChangeStatus,
    required this.mutationFailure,
    required this.onRespond,
    required this.onChangeStatus,
    required this.onClose,
    required this.strings,
    required this.onSuccess,
    required this.onDirty,
    super.key,
  });
  final Complaint complaint;
  final bool busy, loading, canAct, canRespond, canChangeStatus;
  final ComplaintFailure? mutationFailure;
  final Future<bool> Function(String) onRespond;
  final Future<bool> Function(ComplaintStatus) onChangeStatus;
  final Future<bool> Function(bool hasDraft) onClose;
  final ComplaintStrings strings;
  final ValueChanged<String> onSuccess;
  final ValueChanged<bool> onDirty;
  @override
  State<ComplaintDetail> createState() => ComplaintDetailState();
}

class ComplaintDetailState extends State<ComplaintDetail> {
  final _reply = TextEditingController();
  final _replyFocus = FocusNode();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _reply.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  Future<void> _respond() async {
    if (!_form.currentState!.validate()) {
      _replyFocus.requestFocus();
      return;
    }
    final success = await widget.onRespond(_reply.text);
    if (!mounted) return;
    if (success) {
      _reply.clear();
      widget.onDirty(false);
      widget.onSuccess(widget.strings.text('successReply'));
    }
  }

  Future<void> _close() async {
    final success = await widget.onClose(_reply.text.isNotEmpty);
    if (mounted && success) {
      _reply.clear();
      widget.onDirty(false);
      widget.onSuccess(widget.strings.text('successClose'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.complaint;
    final strings = widget.strings;
    final busy = widget.busy;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.loading) const LinearProgressIndicator(),
          ComplaintStatusBadge(status: item.status, strings: strings),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              item.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${strings.text('category')}: ${strings.text('category_${item.category}')}',
          ),
          const SizedBox(height: 8),
          SelectableText(
            '${strings.text('protocol')}: ${item.id}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${strings.text('createdAt')} ${strings.date(item.createdAt, context: context)}',
          ),
          const SizedBox(height: 8),
          Text(
            '${strings.text('updatedAt')} ${strings.date(item.updatedAt, context: context)}',
          ),
          complaintDetailDivider,
          Text(
            strings.text('report'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SelectableText(item.description),
          complaintDetailDivider,
          Text(
            strings.text('responseTitle'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (item.responses.isEmpty) Text(strings.text('noResponses')),
          for (final response in item.responses) ...[
            Text(
              strings.text(
                response.isAdministrative
                    ? 'responseFromBuilding'
                    : 'responseFromResidency',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SelectableText(response.message),
            const SizedBox(height: 4),
            Text(
              strings.date(response.createdAt, context: context),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
          ],
          complaintDetailDivider,
          Text(
            strings.text('history'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final change in item.history)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  ComplaintStatusBadge(status: change.status, strings: strings),
                  Text(strings.date(change.createdAt, context: context)),
                ],
              ),
            ),
          if (item.status == ComplaintStatus.closed) ...[
            const SizedBox(height: 24),
            complaintFeedback(
              strings.text('closedMessage'),
              backgroundColor: Colors.transparent,
            ),
          ],
          if (widget.mutationFailure != null) ...[
            const SizedBox(height: 16),
            complaintFeedback(
              strings.failure(widget.mutationFailure),
              error: true,
              backgroundColor: Colors.transparent,
            ),
          ],
          if (widget.canAct) ...[
            complaintDetailDivider,
            if (widget.canRespond)
              Form(
                key: _form,
                child: TextFormField(
                  key: const ValueKey('complaint-response'),
                  controller: _reply,
                  focusNode: _replyFocus,
                  enabled: !busy,
                  minLines: 4,
                  maxLines: 10,
                  maxLength: 5000,
                  onChanged: (value) => widget.onDirty(value.isNotEmpty),
                  decoration: InputDecoration(
                    labelText: strings.text('replyLabel'),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? strings.text('requiredResponse')
                      : value.trim().length > 5000 || value.contains('\u0000')
                      ? strings.text('limitResponse')
                      : null,
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (widget.canRespond)
                  FilledButton.icon(
                    key: const ValueKey('send-response'),
                    onPressed: busy ? null : _respond,
                    icon: const Icon(Icons.send_outlined, size: 16),
                    label: Text(
                      strings.text(busy ? 'sending' : 'sendResponse'),
                    ),
                  ),
                if (widget.canChangeStatus &&
                    item.status == ComplaintStatus.open)
                  TextButton(
                    onPressed: busy
                        ? null
                        : () async {
                            final success = await widget.onChangeStatus(
                              ComplaintStatus.inAnalysis,
                            );
                            if (mounted && success) {
                              widget.onSuccess(strings.text('successStatus'));
                            }
                          },
                    child: Text(strings.text('markInAnalysis')),
                  ),
                if (widget.canChangeStatus)
                  TextButton.icon(
                    key: const ValueKey('close-complaint'),
                    onPressed:
                        busy ||
                            !item.responses.any(
                              (response) => response.isAdministrative,
                            )
                        ? null
                        : _close,
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(strings.text('closeComplaint')),
                  ),
              ],
            ),
            if (widget.canChangeStatus &&
                !item.responses.any(
                  (response) => response.isAdministrative,
                )) ...[
              const SizedBox(height: 8),
              Text(strings.text('responseRequired')),
            ],
          ],
        ],
      ),
    );
  }
}
