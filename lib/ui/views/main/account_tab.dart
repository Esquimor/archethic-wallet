import 'package:aewallet/application/account/providers.dart';
import 'package:aewallet/application/blog.dart';
import 'package:aewallet/application/connectivity_status.dart';
import 'package:aewallet/application/contact.dart';
import 'package:aewallet/application/market_price.dart';
import 'package:aewallet/application/settings/settings.dart';
import 'package:aewallet/application/settings/theme.dart';
import 'package:aewallet/ui/views/blog/last_articles_list.dart';
import 'package:aewallet/ui/views/main/components/app_update_button.dart';
import 'package:aewallet/ui/views/main/components/menu_widget_wallet.dart';
import 'package:aewallet/ui/views/main/home_page.dart';
import 'package:aewallet/ui/views/tokens_fungibles/layouts/fungibles_tokens_list.dart';
import 'package:aewallet/ui/views/transactions/transaction_recent_list.dart';
import 'package:aewallet/ui/widgets/balance/balance_infos.dart';
import 'package:aewallet/ui/widgets/components/refresh_indicator.dart';
import 'package:aewallet/util/get_it_instance.dart';
import 'package:aewallet/util/haptic_util.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class AccountTab extends ConsumerWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(ThemeProviders.selectedTheme);
    final preferences = ref.watch(SettingsProviders.settings);
    final connectivityStatusProvider = ref.watch(connectivityStatusProviders);

    return Column(
      children: [
        Expanded(
          /// REFRESH
          child: ArchethicRefreshIndicator(
            onRefresh: () => Future<void>.sync(() async {
              sl.get<HapticUtil>().feedback(
                    FeedbackType.light,
                    preferences.activeVibrations,
                  );

              final connectivityStatusProvider =
                  ref.read(connectivityStatusProviders);
              if (connectivityStatusProvider ==
                  ConnectivityStatus.isDisconnected) {
                return;
              }

              await ref
                  .read(AccountProviders.selectedAccount.notifier)
                  .refreshRecentTransactions();
              ref
                ..invalidate(BlogProviders.fetchArticles)
                ..invalidate(ContactProviders.fetchContacts)
                ..invalidate(MarketPriceProviders.currencyMarketPrice);
            }),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: Stack(
                children: [
                  Column(
                    children: <Widget>[
                      /// BACKGROUND IMAGE
                      Container(
                        height: MediaQuery.of(context).size.height,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                              theme.background2Small!,
                            ),
                            fit: BoxFit.fitHeight,
                            opacity: 0.7,
                          ),
                        ),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top + 10,
                              bottom: 50,
                            ),
                            child: Column(
                              children: <Widget>[
                                /// BALANCE
                                const BalanceInfos(),
                                const SizedBox(
                                  height: 10,
                                ),

                                /// PRICE CHART
                                if (preferences.showPriceChart &&
                                    connectivityStatusProvider ==
                                        ConnectivityStatus.isConnected)
                                  const Stack(
                                    children: <Widget>[
                                      BalanceInfosChart(),
                                    ],
                                  )
                                else
                                  const SizedBox(),

                                /// KPI
                                if (preferences.showPriceChart &&
                                    connectivityStatusProvider ==
                                        ConnectivityStatus.isConnected)
                                  const BalanceInfosKpi()
                                else
                                  const SizedBox(),

                                Divider(
                                  height: 1,
                                  color:
                                      theme.backgroundDarkest!.withOpacity(0.1),
                                ),

                                const SizedBox(
                                  height: 15,
                                ),
                                const MenuWidgetWallet(),
                                const SizedBox(
                                  height: 15,
                                ),
                                Divider(
                                  height: 1,
                                  color:
                                      theme.backgroundDarkest!.withOpacity(0.1),
                                ),
                                const ExpandablePageView(
                                  children: [
                                    TxList(),
                                    FungiblesTokensListWidget(),
                                  ],
                                ),

                                /// BLOG
                                if (connectivityStatusProvider ==
                                    ConnectivityStatus.isConnected)
                                  const LastArticles(),
                                const SizedBox(
                                  height: 30,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const AppUpdateButton(),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
