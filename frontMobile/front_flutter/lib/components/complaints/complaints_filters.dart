import 'package:flutter/material.dart';

import '../../types/complaint.dart';
import '../../lang/complaint_strings.dart';

class ComplaintsFilters extends StatelessWidget {
  const ComplaintsFilters({
    super.key,
    required this.strings,
    required this.status,
    required this.category,
    required this.busy,
    required this.onStatus,
    required this.onCategory,
  });
  final ComplaintStrings strings;
  final ComplaintStatus? status;
  final String? category;
  final bool busy;
  final ValueChanged<ComplaintStatus?> onStatus;
  final ValueChanged<String?> onCategory;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth < 500 ? constraints.maxWidth : 240.0;
      return Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          SizedBox(
            width: width,
            child: DropdownButtonFormField<ComplaintStatus>(
              key: ValueKey('status-$status'),
              initialValue: status,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: strings.text('filterLabel'),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(strings.text('all'))),
                for (final value in ComplaintStatus.values.where(
                  (value) => value != ComplaintStatus.unknown,
                ))
                  DropdownMenuItem(
                    value: value,
                    child: Text(strings.text(value.name)),
                  ),
              ],
              onChanged: busy ? null : onStatus,
            ),
          ),
          SizedBox(
            width: width,
            child: DropdownButtonFormField<String>(
              key: ValueKey('category-$category'),
              initialValue: category,
              isExpanded: true,
              decoration: InputDecoration(labelText: strings.text('category')),
              items: [
                DropdownMenuItem(value: null, child: Text(strings.text('all'))),
                for (final value in complaintCategories)
                  DropdownMenuItem(
                    value: value,
                    child: Text(strings.text('category_$value')),
                  ),
              ],
              onChanged: busy ? null : onCategory,
            ),
          ),
        ],
      );
    },
  );
}
