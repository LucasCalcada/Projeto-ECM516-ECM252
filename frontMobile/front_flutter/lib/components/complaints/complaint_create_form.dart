import 'package:flutter/material.dart';

import '../../types/complaint.dart';
import '../../types/complaint_failure.dart';
import '../../lang/complaint_strings.dart';
import 'complaint_feedback.dart';

class ComplaintCreateForm extends StatefulWidget {
  const ComplaintCreateForm({
    required this.onCreate,
    required this.mutationFailure,
    required this.strings,
    required this.onDirty,
    required this.onCancel,
    required this.onCreated,
    super.key,
  });
  final Future<bool> Function(
    String title,
    String description, {
    required String category,
  })
  onCreate;
  final ComplaintFailure? mutationFailure;
  final ComplaintStrings strings;
  final ValueChanged<bool> onDirty;
  final VoidCallback onCancel;
  final VoidCallback onCreated;
  @override
  State<ComplaintCreateForm> createState() => ComplaintCreateFormState();
}

class ComplaintCreateFormState extends State<ComplaintCreateForm> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _titleFocus = FocusNode();
  final _categoryFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  String? _category;
  bool _busy = false;
  void _dirty() => widget.onDirty(
    _title.text.isNotEmpty || _description.text.isNotEmpty || _category != null,
  );
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _titleFocus.dispose();
    _categoryFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_form.currentState!.validate()) {
      if (_title.text.trim().isEmpty || _title.text.trim().length > 200) {
        _titleFocus.requestFocus();
      } else if (_category == null) {
        _categoryFocus.requestFocus();
      } else {
        _descriptionFocus.requestFocus();
      }
      return;
    }
    setState(() => _busy = true);
    final success = await widget.onCreate(
      _title.text,
      _description.text,
      category: _category!,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (success) {
      _form.currentState?.reset();
      _title.clear();
      _description.clear();
      setState(() => _category = null);
      widget.onDirty(false);
      widget.onCreated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return complaintPanel(
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                strings.text('createTitle'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const ValueKey('complaint-subject'),
              controller: _title,
              focusNode: _titleFocus,
              enabled: !_busy,
              autofocus: true,
              maxLength: 200,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _dirty(),
              decoration: InputDecoration(
                labelText: strings.text('subjectLabel'),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? strings.text('requiredSubject')
                  : value.trim().length > 200 || value.contains('\u0000')
                  ? strings.text('limitTitle')
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const ValueKey('complaint-category'),
              focusNode: _categoryFocus,
              isExpanded: true,
              decoration: InputDecoration(labelText: strings.text('category')),
              items: [
                for (final category in complaintCategories)
                  DropdownMenuItem(
                    value: category,
                    child: Text(strings.text('category_$category')),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (value) {
                      setState(() => _category = value);
                      _dirty();
                    },
              validator: (value) =>
                  value == null ? strings.text('failureValidation') : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('complaint-description'),
              controller: _description,
              focusNode: _descriptionFocus,
              enabled: !_busy,
              minLines: 5,
              maxLines: 12,
              maxLength: 10000,
              onChanged: (_) => _dirty(),
              decoration: InputDecoration(
                labelText: strings.text('descriptionLabel'),
                alignLabelWithHint: true,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? strings.text('requiredDescription')
                  : value.trim().length > 10000 || value.contains('\u0000')
                  ? strings.text('limitDescription')
                  : null,
            ),
            const SizedBox(height: 16),
            complaintFeedback(strings.text('privateNotice')),
            if (widget.mutationFailure != null) ...[
              const SizedBox(height: 12),
              complaintFeedback(
                strings.failure(widget.mutationFailure),
                error: true,
              ),
            ],
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy ? null : widget.onCancel,
                  child: Text(strings.text('cancel')),
                ),
                FilledButton(
                  key: const ValueKey('submit-complaint'),
                  onPressed: _busy ? null : _submit,
                  child: Text(strings.text(_busy ? 'saving' : 'submit')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
