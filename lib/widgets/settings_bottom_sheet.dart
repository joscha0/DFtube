import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class SettingsBottomSheet extends StatefulWidget {
  InAppWebViewController? webViewController;
  SettingsBottomSheet({
    Key? key,
    required this.webViewController,
  }) : super(key: key);

  @override
  _SettingsBottomSheetState createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  late bool hide;

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Theme.of(context).backgroundColor,
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    "DFtube",
                    style: Theme.of(context).textTheme.headline4,
                  ),
                  SwitchListTile(
                    title: const Text('hide'),
                    value: hide,
                    onChanged: (bool value) {
                      setState(() {
                        hide = value;
                      });
                      // controller.setHide("cssHide", value);
                      // widget.webViewController
                      // ?.injectCSSCode(source: controller.getHideCss());
                      widget.webViewController?.reload();
                    },
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}
