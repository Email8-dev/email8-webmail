// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Email8:Webmail
// SPDX-License-Identifier: Apache-2.0

// Mailbox list (story 6.1) — Mailbox/get over JMAP, special-use icons.

import 'package:flutter/material.dart';
import '../app_context.dart';
import '../theme.dart';
import '../url_router_shim.dart';

class MailboxListPage extends StatefulWidget {
  const MailboxListPage({super.key});

  @override
  State<MailboxListPage> createState() => _MailboxListPageState();
}

class _MailboxListPageState extends State<MailboxListPage> {
  List<Map<String, dynamic>>? _mailboxes;

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
      final boxes = await services.getMailboxes();
      if (mounted) setState(() => _mailboxes = boxes);
    } catch (e) {
      if (mounted) setState(() => _mailboxes = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boxes = _mailboxes;
    if (boxes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (boxes.isEmpty) {
      return const Center(child: Text('No mailboxes yet'));
    }
    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: ListView.builder(
        key: const Key('mailbox-list'),
        itemCount: boxes.length,
        itemBuilder: (context, i) {
          final b = boxes[i];
          final role = (b['role'] as String?) ?? '';
          final name = (b['name'] as String?) ?? '(unnamed)';
          return ListTile(
            key: Key('mailbox-$role'),
            leading: Icon(_iconForRole(role)),
            title: Text(name, style: Sentin8Text.bodyMedium),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => navigateTo('/mailbox/${b['id']}'),
          );
        },
      ),
    );
  }

  IconData _iconForRole(String role) => switch (role) {
        'inbox' => Icons.inbox,
        'drafts' => Icons.drafts,
        'sent' => Icons.send,
        'trash' => Icons.delete_outline,
        'junk' => Icons.warning_amber_outlined,
        'archive' => Icons.archive_outlined,
        _ => Icons.folder_outlined,
      };
}