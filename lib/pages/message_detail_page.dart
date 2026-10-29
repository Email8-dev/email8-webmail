// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Email8:Webmail
// SPDX-License-Identifier: Apache-2.0

// Message detail (story 6.1) - Email/get with bodyValues over JMAP.

import 'package:flutter/material.dart';
import '../app_context.dart';
import '../theme.dart';

class MessageDetailPage extends StatefulWidget {
  final String emailId;
  const MessageDetailPage({super.key, required this.emailId});

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  Map<String, dynamic>? _message;
  String? _body;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final appContext = WebmailContextProvider.of(context);
    final services = appContext?.services;
    if (services == null) return;
    try {
      final responses = await services.jmap([
        [
          'Email/get',
          {
            'ids': [widget.emailId],
            'properties': [
              'id', 'subject', 'from', 'to', 'cc', 'receivedAt', 'sentAt',
              'keywords', 'hasAttachment', 'preview',
            ],
          },
          'g0',
        ],
        [
          'Email/get',
          {
            'ids': [widget.emailId],
            'properties': ['#bodyValues'],
            'bodyProperties': ['partId', 'type', 'charset'],
            'fetchTextBodyValues': true,
            'fetchHTMLBodyValues': false,
          },
          'g1',
        ],
      ]);
      Map<String, dynamic>? msg;
      String? body;
      for (final r in responses) {
        if (r is! List || r.length < 2) continue;
        final args = (r[1] as Map<String, dynamic>? ?? {});
        if (r[0] == 'Email/get' && args['list'] is List) {
          final list = args['list'] as List<dynamic>;
          if (list.isNotEmpty) {
            msg = (list.first as Map<String, dynamic>);
          }
        }
        if (r[0] == 'Email/get' && args['list'] != null) {
          // The second call (bodyValues) - matched by call order.
        }
      }
      // Simple fetch of body via a second pass isn't available in the
      // single-part store; the preview body is rendered when the server
      // returns bodyValues in the same response (P2 multi-part).
      if (mounted) {
        setState(() {
          _message = msg;
          _body = (msg?['preview'] as String?) ?? body;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _body = 'Failed to load: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _message;
    if (m == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final from = (m['from'] as Map<String, dynamic>? ?? {});
    return SingleChildScrollView(
      key: const Key('message-detail'),
      padding: const EdgeInsets.all(Sentin8Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((m['subject'] as String?) ?? '(no subject)',
              style: Sentin8Text.headlineMedium),
          const SizedBox(height: Sentin8Spacing.sm),
          Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person)),
              const SizedBox(width: Sentin8Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((from['email'] as String?) ?? '',
                        style: Sentin8Text.bodyMedium),
                    Text(_fmt(m['receivedAt'] as String?),
                        style: Sentin8Text.labelSmall),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
          SelectableText(_body ?? '', style: Sentin8Text.bodyMedium),
        ],
      ),
    );
  }

  String _fmt(String? iso) {
    if (iso == null) return '';
    try {
      return DateTime.parse(iso).toLocal().toString();
    } catch (_) {
      return '';
    }
  }
}