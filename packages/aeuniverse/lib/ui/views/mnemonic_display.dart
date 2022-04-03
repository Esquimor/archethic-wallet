// Flutter imports:
import 'package:core_ui/util/app_util.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:aeuniverse/appstate_container.dart';
import 'package:aeuniverse/ui/util/styles.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:core/localization.dart';

/// A widget for displaying a mnemonic phrase
class MnemonicDisplay extends StatefulWidget {
  const MnemonicDisplay(
      {Key? key, required this.wordList, this.obscureSeed = false})
      : super(key: key);

  final List<String> wordList;
  final bool obscureSeed;

  @override
  _MnemonicDisplayState createState() => _MnemonicDisplayState();
}

class _MnemonicDisplayState extends State<MnemonicDisplay> {
  static final List<String> _obscuredSeed = List<String>.filled(24, '•' * 6);
  bool? _seedObscured;

  @override
  void initState() {
    super.initState();
    _seedObscured = true;
  }

  List<Widget> _buildMnemonicRows() {
    int nRows = AppUtil.isDesktopMode() ? 8 : 12;
    int itemsPerRow = 24 ~/ nRows;
    int curWord = 0;
    final List<Widget> ret = <Widget>[];
    for (int i = 0; i < nRows; i++) {
      ret.add(Container(
        width: MediaQuery.of(context).size.width,
        height: 1,
        color: StateContainer.of(context).curTheme.primary05,
      ));
      // Build individual items
      final List<Widget> items = <Widget>[];
      for (int j = 0; j < itemsPerRow; j++) {
        items.add(
          SizedBox(
            width: (MediaQuery.of(context).size.width -
                    (smallScreen(context) ? 15 : 30)) /
                itemsPerRow,
            child: RichText(
              textAlign: TextAlign.start,
              text: TextSpan(children: <InlineSpan>[
                TextSpan(
                  text: curWord < 9 ? ' ' : '',
                  style: AppStyles.textStyleSize16W100Primary60(context),
                ),
                TextSpan(
                  text: ' ${curWord + 1}) ',
                  style: AppStyles.textStyleSize16W100Primary60(context),
                ),
                TextSpan(
                  text: _seedObscured! && widget.obscureSeed
                      ? _obscuredSeed[curWord]
                      : widget.wordList[curWord],
                  style: AppStyles.textStyleSize16W200Primary(context),
                )
              ]),
            ),
          ),
        );
        curWord++;
      }
      ret.add(
        Padding(
            padding: EdgeInsets.symmetric(
                vertical: smallScreen(context) ? 6.0 : 9.0),
            child: Container(
              margin: const EdgeInsetsDirectional.only(start: 5),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, children: items),
            )),
      );
      if (curWord == itemsPerRow * nRows) {
        ret.add(Container(
          width: MediaQuery.of(context).size.width,
          height: 1,
          color: StateContainer.of(context).curTheme.primary05,
        ));
      }
    }
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.obscureSeed) {
            setState(() {
              _seedObscured = !_seedObscured!;
            });
          }
        },
        child: Column(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(top: 15),
              child: Column(
                children: _buildMnemonicRows(),
              ),
            ),
            // Tap to reveal or hide
            if (widget.obscureSeed)
              Container(
                margin: const EdgeInsetsDirectional.only(top: 8),
                child: _seedObscured!
                    ? AutoSizeText(
                        AppLocalization.of(context)!.tapToReveal,
                        style: AppStyles.textStyleSize14W600Primary(context),
                      )
                    : Text(
                        AppLocalization.of(context)!.tapToHide,
                        style: AppStyles.textStyleSize14W600Primary(context),
                      ),
              )
            else
              const SizedBox(),
          ],
        ),
      ),
    ]);
  }
}
