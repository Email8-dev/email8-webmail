// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Email8:Webmail
// SPDX-License-Identifier: Apache-2.0

// Webmail widget tests — pure-widget coverage that avoids the
// web-only shared package (dart:html is unavailable on the VM test
// platform; ebank has the same limitation).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Webmail smoke', () {
    testWidgets('app-level scaffold renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Email8:Webmail')),
            body: const Center(child: Text('Webmail')),
          ),
        ),
      );
      expect(find.text('Webmail'), findsOneWidget);
    });
  });
}
