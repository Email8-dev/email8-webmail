// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Email8:Webmail
// SPDX-License-Identifier: Apache-2.0

// Email8:Webmail main entry point — Flutter app scaffold + Sentin8
// provider initialization.
//
// Bootstrap flow (shared platform pattern):
// 1. App starts, calls GET /v1/app/runtime/context (routed through TLS)
// 2. TLS injects X-Sentin8-App-Id, X-Sentin8-Env-Id headers
// 3. Receives AppRuntimeContext { authDomain, bffDomain, org, env }
// 4. Initializes AuthProvider with the BFF base URL
// 5. Checks BFF /auth/session for an existing session
// 6. Renders the signed-in mail shell or the landing page

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:web/web.dart' as web;
import 'theme.dart';
import 'app_context.dart';
import 'bootstrap.dart';
import 'pages/pages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Enable semantics for e2e/Playwright ARIA access.
  SemanticsBinding.instance.ensureSemantics();
  runApp(const WebmailApp());
}

/// Webmail root widget: bootstrap loader → mail shell.
class WebmailApp extends StatefulWidget {
  const WebmailApp({super.key});

  @override
  State<WebmailApp> createState() => _WebmailAppState();
}

class _WebmailAppState extends State<WebmailApp> {
  AppRuntimeContext? _runtimeContext;
  String? _bootstrapError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // Use the app's own origin so the TLS proxy injects the correct
      // X-Sentin8-Hostname header for runtime context resolution.
      final appBaseUrl = web.window.location.origin;
      final ctx = await fetchRuntimeContext(appBaseUrl: appBaseUrl);

      setState(() {
        _runtimeContext = ctx;
      });
    } catch (e) {
      setState(() {
        _bootstrapError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _runtimeContext?.themeMode == 'dark';
    return MaterialApp(
      title: _runtimeContext?.displayName ?? 'Webmail',
      theme: isDark
          ? sentin8DarkThemeForContext(_runtimeContext!)
          : (_runtimeContext != null
              ? sentin8ThemeForContext(_runtimeContext!)
              : sentin8Theme()),
      debugShowCheckedModeBanner: false,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_bootstrapError != null) {
      return BootstrapErrorPage(error: _bootstrapError!, appName: 'Webmail');
    }

    if (_runtimeContext == null) {
      return const BootstrapLoaderPage(appName: 'Webmail');
    }

    return WebmailContextProvider(
      runtimeContext: _runtimeContext!,
      child: const WebmailShell(),
    );
  }
}