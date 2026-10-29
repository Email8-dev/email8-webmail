// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Email8:Webmail
// SPDX-License-Identifier: Apache-2.0

// Contacts basics (story 6.1) - ContactCard/get over JMAP.

import 'package:flutter/material.dart';
import '../app_context.dart';
import '../theme.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Map<String, dynamic>>? _contacts;

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
        ['ContactCard/get', {'ids': null}, 'k0'],
      ], using: [
        'urn:ietf:params:jmap:core',
        'urn:ietf:params:jmap:carddav',
      ]);
      final contacts = <Map<String, dynamic>>[];
      for (final r in responses) {
        if (r is List && r.length > 1 && r[0] == 'ContactCard/get') {
          final args = r[1] as Map<String, dynamic>;
          contacts.addAll((args['list'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>());
        }
      }
      if (mounted) setState(() => _contacts = contacts);
    } catch (_) {
      if (mounted) setState(() => _contacts = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _contacts;
    if (contacts == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (contacts.isEmpty) {
      return const Center(
          key: Key('contacts-empty'),
          child: Text('No contacts yet'));
    }
    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: ListView.builder(
        key: const Key('contacts-list'),
        itemCount: contacts.length,
        itemBuilder: (context, i) {
          final c = contacts[i];
          final name = (c['name'] as String?) ??
              (c['fullName'] as String?) ??
              '(unnamed)';
          return ListTile(
            key: Key('contact-$i'),
            leading: CircleAvatar(child: Text(name.isEmpty ? '?' : name[0])),
            title: Text(name, style: Sentin8Text.bodyMedium),
          );
        },
      ),
    );
  }
}