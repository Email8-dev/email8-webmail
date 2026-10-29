// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Email8:Webmail
// SPDX-License-Identifier: Apache-2.0

// Message list (story 6.1) - Email/query + Email/get over JMAP for one
// mailbox, unread bold, tap → detail.

import 'package:flutter/material.dart';
import '../app_context.dart';
import '../theme.dart';
import '../url_router_shim.dart';

class MessageListPage extends StatefulWidget {
  final String mailboxId;
  const MessageListPage({super.key, required this.mailboxId});

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  List<Map<String, dynamic>>? _messages;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MessageListPage old) {
    super.didUpdateWidget(old);
    if (old.mailboxId != widget.mailboxId) _load();
  }

  Future<void> _load() async {
    final appContext = WebmailContextProvider.of(context);
    final services = appContext?.services;
    if (services == null) return;
    try {
      final ids = await services.queryEmailIds({
        'inMailbox': widget.mailboxId,
      }, limit: 100);
      final messages = await services.getEmails(ids);
      if (mounted) setState(() => _messages = messages);
    } catch (e) {
      if (mounted) setState(() => _messages = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages;
    if (messages == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (messages.isEmpty) {
      return const Center(child: Text('No messages'));
    }
    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: ListView.builder(
        key: const Key('message-list'),
        itemCount: messages.length,
        itemBuilder: (context, i) {
          final m = messages[i];
          final keywords = (m['keywords'] as Map<String, dynamic>? ?? {});
          final unread = !keywords.containsKey(r'$seen');
          final from = (m['from'] as Map<String, dynamic>? ?? {});
          final subject = (m['subject'] as String?) ?? '(no subject)';
          return ListTile(
            key: Key('message-${m['id']}'),
            leading: Icon(
              unread ? Icons.mark_email_unread : Icons.mark_email_read,
              color: unread ? Sentin8Colors.primary : null,
            ),
            title: Text(
              (from['name'] as String?) ?? (from['email'] as String?) ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: unread
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : Sentin8Text.bodyMedium,
            ),
            subtitle: Text(
              (m['preview'] as String?) ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              _timeLabel(m['receivedAt'] as String?),
              style: Sentin8Text.labelSmall,
            ),
            onTap: () => navigateTo('/message/${m['id']}'),
          );
        },
      ),
    );
  }

  String _timeLabel(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      final local = dt.toLocal();
      final now = DateTime.now();
      if (local.day == now.day && local.month == now.month) {
        return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      }
      return '${local.day}/${local.month}';
    } catch (_) {
      return '';
    }
  }
}