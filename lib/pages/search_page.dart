// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Email8:Webmail
// SPDX-License-Identifier: Apache-2.0

// Search page (story 6.1) - Email/query with text filter + snippets.

import 'package:flutter/material.dart';
import '../app_context.dart';
import '../theme.dart';
import '../url_router_shim.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _query = TextEditingController();
  List<Map<String, dynamic>>? _results;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final appContext = WebmailContextProvider.of(context);
    final services = appContext?.services;
    if (services == null) return;
    final text = _query.text.trim();
    if (text.isEmpty) return;
    setState(() => _results = null);
    try {
      final ids = await services.queryEmailIds({'text': text}, limit: 100);
      final messages = await services.getEmails(ids);
      if (mounted) setState(() => _results = messages);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('search-page'),
      padding: const EdgeInsets.all(Sentin8Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('search-input'),
            controller: _query,
            decoration: InputDecoration(
              labelText: 'Search mail',
              suffixIcon: IconButton(
                key: const Key('search-go'),
                icon: const Icon(Icons.search),
                onPressed: _search,
              ),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: Sentin8Spacing.md),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final results = _results;
    if (results == null) {
      return const Center(child: Text('Type a query to search'));
    }
    if (results.isEmpty) {
      return const Center(child: Text('No matches'));
    }
    return ListView.builder(
      key: const Key('search-results'),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final m = results[i];
        return ListTile(
          key: Key('search-result-$i'),
          title: Text((m['subject'] as String?) ?? '(no subject)',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text((m['preview'] as String?) ?? '',
              maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () => navigateTo('/message/${m['id']}'),
        );
      },
    );
  }
}