import 'package:flutter/material.dart';

import '../../lang/app_localizations.dart';
import '../../types/communication_post.dart';

class PostContent extends StatefulWidget {
  const PostContent({super.key, required this.post});

  final CommunicationPost post;

  @override
  State<PostContent> createState() => _PostContentState();
}

class _PostContentState extends State<PostContent> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.post.title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Text(
        widget.post.description,
        maxLines: _expanded ? null : 3,
        overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      if (widget.post.description.isNotEmpty)
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(
            AppLocalizations.of(context)
                .text(_expanded ? 'home.readLess' : 'home.readMore'),
          ),
        ),
    ],
  );
}
