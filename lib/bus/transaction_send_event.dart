/// SPDX-License-Identifier: AGPL-3.0-or-later

// Package imports:
import 'package:event_taxi/event_taxi.dart';

enum TransactionSendEventType { transfer, token, keychain, keychainAccess }

class TransactionSendEvent implements Event {
  TransactionSendEvent(
      {required this.transactionType,
      this.nbConfirmations,
      this.response,
      this.params});

  final TransactionSendEventType? transactionType;
  final int? nbConfirmations;
  final String? response;
  final Map<String, Object>? params;
}
