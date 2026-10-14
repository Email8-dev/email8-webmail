// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Email8:Webmail
// SPDX-License-Identifier: Apache-2.0

// Email8:Webmail services — BFF proxy access layer.
//
// All backend access goes through Sentin8:BFF `/proxy/email8-store/...`
// (JMAP) — tokens never reach the client. `BffApiClient` and
// `ApiResponse` are re-exported from the shared sentin8 package.

// Re-export shared types from the package.
export 'package:sentin8/sentin8.dart' show BffApiClient, ApiResponse;

import 'package:sentin8/sentin8.dart';

/// Centralized service registry for Webmail.
///
/// The Store service exposes the JMAP surface (`POST /jmap`,
/// `GET /jmap/session`, upload/download) — everything routes through it.
class WebmailServices {
  final BffApiClient store;

  WebmailServices._({required this.store});

  /// Create WebmailServices from runtime context + auth state.
  factory WebmailServices({
    required String bffBaseUrl,
    String? csrfToken,
    String? correlationId,
  }) {
    final base = bffBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return WebmailServices._(
      store: BffApiClient(
        bffBaseUrl: base,
        serviceName: 'email8-store',
        csrfToken: csrfToken,
        correlationId: correlationId,
      ),
    );
  }

  /// One JMAP request batch (`POST /proxy/email8-store/jmap`).
  /// Returns the decoded `methodResponses` list, or throws on transport
  /// failure (per-call errors surface inside the responses).
  Future<List<dynamic>> jmap(
    List<List<dynamic>> methodCalls, {
    List<String> using = const ['urn:ietf:params:jmap:core', 'urn:ietf:params:jmap:mail'],
  }) async {
    final resp = await store.post(
      '/jmap',
      body: {
        'using': using,
        'methodCalls': methodCalls,
      },
    );
    if (!resp.isSuccess) {
      throw JmapException('jmap request failed: ${resp.statusCode}');
    }
    final data = resp.data as Map<String, dynamic>?;
    return (data?['methodResponses'] as List<dynamic>? ?? []);
  }

  /// `Email/query` → ids for a filter (helper over the batch API).
  Future<List<String>> queryEmailIds(Map<String, dynamic> filter,
      {int position = 0, int limit = 50}) async {
    final responses = await jmap([
      ['Email/query', {'filter': filter, 'position': position, 'limit': limit}, 'q0'],
    ]);
    for (final r in responses) {
      if (r is List && r.length > 1 && r[0] == 'Email/query') {
        final args = r[1] as Map<String, dynamic>;
        return (args['ids'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
      }
    }
    return [];
  }

  /// `Email/get` with the properties webmail renders.
  Future<List<Map<String, dynamic>>> getEmails(List<String> ids) async {
    if (ids.isEmpty) return [];
    final responses = await jmap([
      [
        'Email/get',
        {
          'ids': ids,
          'properties': [
            'id', 'mailboxIds', 'subject', 'from', 'to', 'receivedAt',
            'preview', 'keywords', 'hasAttachment', 'sentAt', 'size',
          ],
        },
        'g0',
      ],
    ]);
    for (final r in responses) {
      if (r is List && r.length > 1 && r[0] == 'Email/get') {
        final args = r[1] as Map<String, dynamic>;
        return (args['list'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
      }
    }
    return [];
  }

  /// `Mailbox/get` → the account's mailbox list.
  Future<List<Map<String, dynamic>>> getMailboxes() async {
    final responses = await jmap([
      ['Mailbox/get', {'ids': null}, 'm0'],
    ]);
    for (final r in responses) {
      if (r is List && r.length > 1 && r[0] == 'Mailbox/get') {
        final args = r[1] as Map<String, dynamic>;
        return (args['list'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
      }
    }
    return [];
  }
}

/// A JMAP transport-level failure (HTTP non-2xx).
class JmapException implements Exception {
  final String message;
  JmapException(this.message);
  @override
  String toString() => message;
}