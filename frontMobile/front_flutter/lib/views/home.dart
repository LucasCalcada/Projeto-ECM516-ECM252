import 'package:flutter/material.dart';

import '../components/home/posts_section.dart';
import '../components/shared/request_feedback.dart';
import '../helpers/communication_service.dart';
import '../lang/app_localizations.dart';
import '../types/api_failure.dart';
import '../types/communication_post.dart';
import '../types/user_session.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.service,
    required this.session,
    required this.onSessionExpired,
  });

  final CommunicationService service;
  final UserSession session;
  final VoidCallback onSessionExpired;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CommunicationPost>? _posts;
  bool _loading = false;
  ApiFailure? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await widget.service.listPosts(widget.session);
      if (mounted) setState(() => _posts = posts);
    } catch (error) {
      if (!mounted) return;
      final failure = error is ApiException
          ? error.failure
          : ApiFailure.unexpected;
      if (failure == ApiFailure.unauthorized) {
        widget.onSessionExpired();
      } else {
        setState(() => _error = failure);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            key: const PageStorageKey('home-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.session.buildingName.isEmpty
                            ? strings.text('selector.unnamedBuilding')
                            : widget.session.buildingName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(strings.text('home.subtitle')),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const Key('refresh-home'),
                          onPressed: _loading ? null : _load,
                          icon: const Icon(Icons.refresh),
                          label: Text(strings.text('refresh')),
                        ),
                      ),
                      if (_loading) const LinearProgressIndicator(),
                      if (_error != null)
                        RequestFeedback(failure: _error, onRetry: _load),
                    ],
                  ),
                ),
              ),
              if (_posts != null) ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: PostsSection(
                    posts: _posts!
                        .where((post) => post.eventAt == null)
                        .toList(),
                    events: false,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: PostsSection(
                    posts: _posts!
                        .where((post) => post.eventAt != null)
                        .toList(),
                    events: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
