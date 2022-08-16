// ignore_for_file: cancel_subscriptions, always_specify_types

/// SPDX-License-Identifier: AGPL-3.0-or-later

// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:event_taxi/event_taxi.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// Project imports:
import 'package:aewallet/appstate_container.dart';
import 'package:aewallet/bus/authenticated_event.dart';
import 'package:aewallet/bus/transaction_send_event.dart';
import 'package:aewallet/localization.dart';
import 'package:aewallet/model/authentication_method.dart';
import 'package:aewallet/model/token_transfer_wallet.dart';
import 'package:aewallet/model/uco_transfer_wallet.dart';
import 'package:aewallet/ui/util/dimens.dart';
import 'package:aewallet/ui/util/routes.dart';
import 'package:aewallet/ui/util/styles.dart';
import 'package:aewallet/ui/util/ui_util.dart';
import 'package:aewallet/ui/views/authenticate/auth_factory.dart';
import 'package:aewallet/ui/views/tokens_fungibles/token_transfer_list.dart';
import 'package:aewallet/ui/views/uco/uco_transfer_list.dart';
import 'package:aewallet/ui/widgets/components/buttons.dart';
import 'package:aewallet/ui/widgets/components/dialog.dart';
import 'package:aewallet/util/confirmations/subscription_channel.dart';
import 'package:aewallet/util/get_it_instance.dart';
import 'package:aewallet/util/preferences.dart';

// Package imports:
import 'package:archethic_lib_dart/archethic_lib_dart.dart'
    show
        TransactionStatus,
        ApiService,
        Transaction,
        UCOTransfer,
        TokenTransfer,
        Keychain,
        uint8ListToHex;

class TransferConfirmSheet extends StatefulWidget {
  const TransferConfirmSheet(
      {super.key,
      required this.lastAddress,
      required this.typeTransfer,
      required this.feeEstimation,
      required this.symbol,
      this.title,
      this.ucoTransferList,
      this.tokenTransferList,
      this.message});

  final String? lastAddress;
  final String? typeTransfer;
  final String? title;
  final double? feeEstimation;
  final String? message;
  final String? symbol;
  final List<UCOTransferWallet>? ucoTransferList;
  final List<TokenTransferWallet>? tokenTransferList;

  @override
  State<TransferConfirmSheet> createState() => _TransferConfirmSheetState();
}

class _TransferConfirmSheetState extends State<TransferConfirmSheet> {
  bool? animationOpen;

  SubscriptionChannel subscriptionChannel = SubscriptionChannel();

  StreamSubscription<AuthenticatedEvent>? _authSub;
  StreamSubscription<TransactionSendEvent>? _sendTxSub;

  void _registerBus() {
    _authSub = EventTaxiImpl.singleton()
        .registerTo<AuthenticatedEvent>()
        .listen((AuthenticatedEvent event) {
      _doSend();
    });

    _sendTxSub = EventTaxiImpl.singleton()
        .registerTo<TransactionSendEvent>()
        .listen((TransactionSendEvent event) {
      if (event.response != 'ok' && event.nbConfirmations == 0) {
        // Send failed
        if (animationOpen!) {
          Navigator.of(context).pop();
        }

        UIUtil.showSnackbar(
            '${AppLocalization.of(context)!.sendError} (${event.response!})',
            context,
            StateContainer.of(context).curTheme.text!,
            StateContainer.of(context).curTheme.snackBarShadow!);
        Navigator.of(context).pop();
      } else {
        UIUtil.showSnackbar(
            event.nbConfirmations == 1
                ? AppLocalization.of(context)!
                    .transactionConfirmed1
                    .replaceAll('%1', event.nbConfirmations.toString())
                    .replaceAll('%2', event.maxConfirmations.toString())
                : AppLocalization.of(context)!
                    .transactionConfirmed
                    .replaceAll('%1', event.nbConfirmations.toString())
                    .replaceAll('%2', event.maxConfirmations.toString()),
            context,
            StateContainer.of(context).curTheme.text!,
            StateContainer.of(context).curTheme.snackBarShadow!,
            duration: const Duration(milliseconds: 5000));
        setState(() {
          StateContainer.of(context).requestUpdate();
        });
        Navigator.of(context).popUntil(RouteUtils.withNameLike('/home'));
      }
    });
  }

  void _destroyBus() {
    if (_authSub != null) {
      _authSub!.cancel();
    }
    if (_sendTxSub != null) {
      _sendTxSub!.cancel();
    }
    subscriptionChannel.close();
  }

  @override
  void initState() {
    super.initState();
    _registerBus();
    animationOpen = false;
  }

  @override
  void dispose() {
    _destroyBus();
    super.dispose();
  }

  void _showSendingAnimation(BuildContext context) {
    animationOpen = true;
    Navigator.of(context).push(AnimationLoadingOverlay(
        AnimationType.send,
        StateContainer.of(context).curTheme.animationOverlayStrong!,
        StateContainer.of(context).curTheme.animationOverlayMedium!,
        onPoppedCallback: () => animationOpen = false));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum:
          EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.035),
      child: Column(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 10),
            height: 5,
            width: MediaQuery.of(context).size.width * 0.15,
            decoration: BoxDecoration(
              color: StateContainer.of(context).curTheme.text60,
              borderRadius: BorderRadius.circular(100.0),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                  child: Column(
                    children: <Widget>[
                      Text(
                        widget.title ??
                            AppLocalization.of(context)!.transfering,
                        style: AppStyles.textStyleSize24W700EquinoxPrimary(
                            context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  child: widget.typeTransfer == 'UCO'
                      ? UCOTransferListWidget(
                          listUcoTransfer: widget.ucoTransferList,
                          feeEstimation: widget.feeEstimation,
                        )
                      : widget.typeTransfer == 'TOKEN'
                          ? TokenTransferListWidget(
                              listTokenTransfer: widget.tokenTransferList,
                              feeEstimation: widget.feeEstimation,
                              symbol: widget.symbol,
                            )
                          : const SizedBox(),
                ),
                if (widget.message!.isNotEmpty)
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(
                        left: 20, right: 20, top: 20.0, bottom: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          AppLocalization.of(context)!.sendMessageConfirmHeader,
                          style: AppStyles.textStyleSize14W600Primary(context),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          widget.message!,
                          style: AppStyles.textStyleSize14W600Primary(context),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 10.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    AppButton.buildAppButton(
                      const Key('confirm'),
                      context,
                      AppButtonType.primary,
                      AppLocalization.of(context)!.confirm,
                      Dimens.buttonTopDimens,
                      onPressed: () async {
                        final Preferences preferences =
                            await Preferences.getInstance();
                        // Authenticate
                        final AuthenticationMethod authMethod =
                            preferences.getAuthMethod();
                        bool auth = await AuthFactory.authenticate(
                            context, authMethod,
                            activeVibrations:
                                StateContainer.of(context).activeVibrations);
                        if (auth) {
                          EventTaxiImpl.singleton().fire(AuthenticatedEvent());
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    AppButton.buildAppButton(
                        const Key('cancel'),
                        context,
                        AppButtonType.primary,
                        AppLocalization.of(context)!.cancel,
                        Dimens.buttonBottomDimens, onPressed: () {
                      Navigator.of(context).pop();
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doSend() async {
    try {
      _showSendingAnimation(context);
      final String? seed = await StateContainer.of(context).getSeed();
      List<UCOTransferWallet> ucoTransferList = widget.ucoTransferList!;
      List<TokenTransferWallet> tokenTransferList = widget.tokenTransferList!;
      final String originPrivateKey = sl.get<ApiService>().getOriginKey();

      final Keychain keychain = await sl.get<ApiService>().getKeychain(seed!);
      final String service =
          'archethic-wallet-${StateContainer.of(context).appWallet!.appKeychain!.getAccountSelected()!.name!}';
      final int index = (await sl.get<ApiService>().getTransactionIndex(
              uint8ListToHex(keychain.deriveAddress(service, index: 0))))
          .chainLength!;

      final Transaction transaction =
          Transaction(type: 'transfer', data: Transaction.initData());
      for (UCOTransfer transfer in ucoTransferList) {
        transaction.addUCOTransfer(transfer.to, transfer.amount!);
      }
      for (TokenTransfer transfer in tokenTransferList) {
        transaction.addTokenTransfer(
            transfer.to, transfer.amount!, transfer.token,
            tokenId: transfer.tokenId == null ? 0 : transfer.tokenId!);
      }
      if (widget.message!.isNotEmpty) {
        transaction.setContent(widget.message!);
      }
      Transaction signedTx = keychain
          .buildTransaction(transaction, service, index)
          .originSign(originPrivateKey);

      TransactionStatus transactionStatus = TransactionStatus();

      final Preferences preferences = await Preferences.getInstance();
      await subscriptionChannel.connect(
          await preferences.getNetwork().getPhoenixHttpLink(),
          await preferences.getNetwork().getWebsocketUri());

      subscriptionChannel.addSubscriptionTransactionConfirmed(
          transaction.address!, waitConfirmations);

      transactionStatus = await sl.get<ApiService>().sendTx(signedTx);

      if (transactionStatus.status == 'invalid') {
        EventTaxiImpl.singleton().fire(TransactionSendEvent(
            transactionType: TransactionSendEventType.transfer,
            response: '',
            nbConfirmations: 0));
        subscriptionChannel.close();
      }
    } catch (e) {
      EventTaxiImpl.singleton().fire(TransactionSendEvent(
          transactionType: TransactionSendEventType.transfer,
          response: e.toString(),
          nbConfirmations: 0));
      subscriptionChannel.close();
    }
  }

  void waitConfirmations(QueryResult event) {
    int nbConfirmations = 0;
    int maxConfirmations = 0;
    if (event.data != null && event.data!['transactionConfirmed'] != null) {
      if (event.data!['transactionConfirmed']['nbConfirmations'] != null) {
        nbConfirmations =
            event.data!['transactionConfirmed']['nbConfirmations'];
      }
      if (event.data!['transactionConfirmed']['maxConfirmations'] != null) {
        maxConfirmations =
            event.data!['transactionConfirmed']['maxConfirmations'];
      }
      EventTaxiImpl.singleton().fire(TransactionSendEvent(
          transactionType: TransactionSendEventType.transfer,
          response: 'ok',
          nbConfirmations: nbConfirmations,
          maxConfirmations: maxConfirmations));
    } else {
      EventTaxiImpl.singleton().fire(
        TransactionSendEvent(
            transactionType: TransactionSendEventType.transfer,
            nbConfirmations: 0,
            maxConfirmations: 0,
            response: 'ko'),
      );
    }
    subscriptionChannel.close();
  }
}
