// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Email8:Webmail
// SPDX-License-Identifier: Apache-2.0

// Webmail app context - central runtime state.
// Holds the AppRuntimeContext, AuthProvider, and WebmailServices;
// provides them to the widget tree via an InheritedWidget.
//
// Mirrors the bank8 app-context pattern (auth state drives services).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'package:sentin8/sentin8.dart'
    show AppRuntimeContext, BffAuthProvider, AppUser, generateCorrelationId;
import 'services.dart';

// Backward-compatible aliases over the shared BFF auth provider.
typedef AuthProvider = BffAuthProvider;
typedef WebmailUser = AppUser;

/// Central app context that ties together runtime context, auth, and
/// services.
class WebmailAppContext extends ChangeNotifier {
  final AppRuntimeContext runtimeContext;
  final AuthProvider auth;
  WebmailServices? services;
  final String correlationId;

  WebmailAppContext._({
    required this.runtimeContext,
    required this.auth,
    required this.correlationId,
  }) {
    auth.addListener(_onAuthChanged);
    _updateServices();
  }

  /// Create the app context after bootstrap.
  static Future<WebmailAppContext> create(
      AppRuntimeContext runtimeContext) async {
    final corrId = generateCorrelationId();
    final auth = AuthProvider(
      bffBaseUrl: runtimeContext.bffBaseUrl,
      authDomain: runtimeContext.authDomain,
    );
    // Wire up redirect callback for web (window.location.href).
    auth.onRedirect = (String url) {
      web.window.location.href = url;
    };
    await auth.init();
    return WebmailAppContext._(
      runtimeContext: runtimeContext,
      auth: auth,
      correlationId: corrId,
    );
  }

  void _onAuthChanged() {
    _updateServices();
    notifyListeners();
  }

  void _updateServices() {
    services = WebmailServices(
      bffBaseUrl: runtimeContext.bffBaseUrl,
      csrfToken: auth.csrfToken,
      correlationId: correlationId,
    );
  }

  @override
  void dispose() {
    auth.removeListener(_onAuthChanged);
    auth.dispose();
    super.dispose();
  }
}

/// StatefulWidget providing WebmailAppContext to the widget tree.
class WebmailContextProvider extends StatefulWidget {
  final AppRuntimeContext runtimeContext;
  final Widget child;

  const WebmailContextProvider({
    super.key,
    required this.runtimeContext,
    required this.child,
  });

  @override
  State<WebmailContextProvider> createState() =>
      _WebmailContextProviderState();

  static WebmailAppContext? of(BuildContext context) {
    final inh =
        context.dependOnInheritedWidgetOfExactType<_WebmailContextInherited>();
    return inh?.context;
  }
}

class _WebmailContextProviderState extends State<WebmailContextProvider> {
  WebmailAppContext? _context;

  @override
  void initState() {
    super.initState();
    _initContext();
  }

  Future<void> _initContext() async {
    final ctx = await WebmailAppContext.create(widget.runtimeContext);
    if (mounted) {
      setState(() {
        _context = ctx;
      });
    }
  }

  @override
  void dispose() {
    _context?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_context == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _WebmailContextInherited(
      context: _context!,
      child: widget.child,
    );
  }
}

class _WebmailContextInherited extends InheritedWidget {
  final WebmailAppContext context;

  const _WebmailContextInherited({required this.context, required super.child});

  @override
  bool updateShouldNotify(_WebmailContextInherited old) =>
      context != old.context;
}