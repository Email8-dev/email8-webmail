// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Email8:Webmail
// SPDX-License-Identifier: Apache-2.0

// Calendar basics (story 6.1) — CalendarEvent/get over JMAP.

import 'package:flutter/material.dart';
import '../app_context.dart';
import '../theme.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<Map<String, dynamic>>? _events;

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
        ['CalendarEvent/get', {'ids': null}, 'c0'],
      ], using: [
        'urn:ietf:params:jmap:core',
        'urn:ietf:params:jmap:calendars',
      ]);
      final events = <Map<String, dynamic>>[];
      for (final r in responses) {
        if (r is List && r.length > 1 && r[0] == 'CalendarEvent/get') {
          final args = r[1] as Map<String, dynamic>;
          events.addAll((args['list'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>());
        }
      }
      if (mounted) setState(() => _events = events);
    } catch (_) {
      if (mounted) setState(() => _events = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;
    if (events == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (events.isEmpty) {
      return const Center(
          key: Key('calendar-empty'),
          child: Text('No calendar events. Invitations you receive by '
              'email appear here automatically.'));
    }
    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: ListView.builder(
        key: const Key('calendar-list'),
        itemCount: events.length,
        itemBuilder: (context, i) {
          final ev = events[i];
          final title = (ev['title'] as String?) ?? (ev['uid'] as String?) ?? '(untitled)';
          return ListTile(
            key: Key('calendar-event-$i'),
            leading: const Icon(Icons.event),
            title: Text(title, style: Sentin8Text.bodyMedium),
            subtitle: Text(_fmt(ev)),
            onTap: () {},
          );
        },
      ),
    );
  }

  String _fmt(Map<String, dynamic> ev) {
    final start = ev['start'] ?? ev['dtstart'];
    final end = ev['end'] ?? ev['dtend'];
    if (start != null) return '$start${end != null ? ' → $end' : ''}';
    return '';
  }
}