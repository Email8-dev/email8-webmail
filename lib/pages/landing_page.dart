// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Email8:Webmail
// SPDX-License-Identifier: Apache-2.0

// Webmail landing page — delegates to sentin8's LandingPage.
import 'package:flutter/material.dart';
import 'package:sentin8/sentin8.dart' as s8;
import '../app_context.dart';

/// Landing page shown when the user is not signed in.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appContext = WebmailContextProvider.of(context);
    if (appContext == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return s8.LandingPage(
      runtimeContext: appContext.runtimeContext,
      auth: appContext.auth,
      descriptionText: 'Your mail, calendar, and contacts — '
          'securely hosted on Sentin8.',
    );
  }
}
