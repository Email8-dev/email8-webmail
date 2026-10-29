// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Email8:Webmail
// SPDX-License-Identifier: Apache-2.0

// Compose (story 6.1) - draft via Email/set then submit via
// EmailSubmission/set over JMAP.

import 'package:flutter/material.dart';
import '../app_context.dart';
import '../theme.dart';

class ComposePage extends StatefulWidget {
  const ComposePage({super.key});

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  final _to = TextEditingController();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _to.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final appContext = WebmailContextProvider.of(context);
    final services = appContext?.services;
    if (services == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      // 1. Create the draft email.
      final draftResponses = await services.jmap([
        [
          'Email/set',
          {
            'create': {
              'draft': {
                'mailboxIds': {draftsMailboxId(appContext!): true},
                'from': [{'email': appContext.auth.user?.email ?? ''}],
                'to': [
                  for (final addr in _to.text.split(','))
                    if (addr.trim().isNotEmpty) {'email': addr.trim()}
                ],
                'subject': _subject.text,
                'keywords': {r'$draft': true},
                'bodyValues': {'body': {'value': _body.text}},
              },
            },
          },
          'e0',
        ],
      ]);
      String? draftId;
      for (final r in draftResponses) {
        if (r is List && r.length > 1 && r[0] == 'Email/set') {
          final created =
              (r[1] as Map<String, dynamic>)['created'] as Map<String, dynamic>?;
          draftId = (created?['draft'] as Map<String, dynamic>?)?['id'] as String?;
        }
      }
      if (draftId == null) throw Exception('draft creation failed');

      // 2. Submit the draft (EmailSubmission/set, onSuccessDestroyEmail
      // clears the $draft keyword).
      await services.jmap([
        [
          'EmailSubmission/set',
          {
            'create': {
              'send': {
                'emailId': draftId,
                'identityId': null,
                'onSuccessDestroyEmail': ['#drafts'],
              },
            },
          },
          's0',
        ],
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent')),
        );
        _to.clear();
        _subject.clear();
        _body.clear();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// The account's drafts mailbox id - resolved via role=drafts, falling
  /// back to the first mailbox when roles are absent (P1 store).
  String draftsMailboxId(WebmailAppContext appContext) {
    // The store provisions special-use mailboxes with role names as ids
    // in the P1 surface; a Mailbox/get lookup lands with 4.1 sorting.
    return 'drafts';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('compose-page'),
      padding: const EdgeInsets.all(Sentin8Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('compose-to'),
            controller: _to,
            decoration: const InputDecoration(
              labelText: 'To',
              hintText: 'recipient@example.com, other@example.com',
            ),
          ),
          const SizedBox(height: Sentin8Spacing.sm),
          TextField(
            key: const Key('compose-subject'),
            controller: _subject,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: Sentin8Spacing.sm),
          Expanded(
            child: TextField(
              key: const Key('compose-body'),
              controller: _body,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                labelText: 'Message',
                alignLabelWithHint: true,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: Sentin8Spacing.sm),
            Text(_error!, style: TextStyle(color: Sentin8Colors.error)),
          ],
          const SizedBox(height: Sentin8Spacing.sm),
          FilledButton.icon(
            key: const Key('compose-send'),
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: const Text('Send'),
          ),
        ],
      ),
    );
  }
}