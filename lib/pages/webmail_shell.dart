// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Email8:Webmail
// SPDX-License-Identifier: Apache-2.0

// Webmail shell — sidebar navigation + hash routing.
// Shows the landing page when signed out, the mail workspace when
// signed in (story 6.1).

import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;
import 'package:sentin8/sentin8.dart' show UserMenu;
import '../theme.dart';
import '../app_context.dart';
import '../url_router_shim.dart';
import 'landing_page.dart';
import 'mailbox_list_page.dart';
import 'message_list_page.dart';
import 'message_detail_page.dart';
import 'compose_page.dart';
import 'search_page.dart';
import 'calendar_page.dart';
import 'contacts_page.dart';

class WebmailShell extends StatefulWidget {
  const WebmailShell({super.key});

  @override
  State<WebmailShell> createState() => _WebmailShellState();
}

class _WebmailShellState extends State<WebmailShell> {
  String _currentRoute = '/';

  @override
  void initState() {
    super.initState();
    _currentRoute = currentRoute();
    if (kIsWeb) {
      web.window.onPopState.listen((_) {
        if (mounted) setState(() { _currentRoute = currentRoute(); });
      });
    }
  }

  void _navigate(String route) {
    setState(() {
      _currentRoute = route;
    });
    navigateTo(route);
  }

  @override
  Widget build(BuildContext context) {
    final appContext = WebmailContextProvider.of(context);
    if (appContext == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final signedIn = appContext.auth.isSignedIn;
    if (!signedIn) {
      return const LandingPage();
    }

    final destinations = const [
      ('/', 'Mail', Icons.inbox_outlined, Icons.inbox),
      ('/search', 'Search', Icons.search_outlined, Icons.search),
      ('/calendar', 'Calendar', Icons.calendar_today_outlined, Icons.calendar_today),
      ('/contacts', 'Contacts', Icons.contacts_outlined, Icons.contacts),
      ('/compose', 'Compose', Icons.edit_note_outlined, Icons.edit_note),
    ];

    final selectedIndex = destinations
        .indexWhere((d) => d.$1 == _currentRoute || _currentRoute.startsWith('${d.$1}/'));
    final effective = selectedIndex < 0 ? 0 : selectedIndex;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: Sentin8Spacing.sm),
            Text(appContext.runtimeContext.displayName,
                style: Sentin8Text.bodyLarge),
          ],
        ),
        actions: [
          UserMenu(auth: appContext.auth),
          const SizedBox(width: Sentin8Spacing.sm),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: effective,
            onDestinationSelected: (i) => _navigate(destinations[i].$1),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.$3),
                  selectedIcon: Icon(d.$4),
                  label: Text(d.$2),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _buildPage(appContext)),
        ],
      ),
    );
  }

  int get selectedIndex {
    final idx = [
      '/',
      '/search',
      '/calendar',
      '/contacts',
      '/compose',
    ].indexWhere((r) => _currentRoute == r || _currentRoute.startsWith('$r'));
    return idx;
  }

  Widget _buildPage(WebmailAppContext appContext) {
    switch (_currentRoute) {
      case '/':
        return const MailboxListPage();
      case '/search':
        return const SearchPage();
      case '/calendar':
        return const CalendarPage();
      case '/contacts':
        return const ContactsPage();
      case '/compose':
        return const ComposePage();
    }
    if (_currentRoute.startsWith('/mailbox/')) {
      final mailboxId = _currentRoute.split('/').last;
      return MessageListPage(mailboxId: mailboxId);
    }
    if (_currentRoute.startsWith('/message/')) {
      final messageId = _currentRoute.split('/').last;
      return MessageDetailPage(emailId: messageId);
    }
    return const MailboxListPage();
  }
}