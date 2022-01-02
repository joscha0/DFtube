import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

import 'home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetX<HomeController>(
      init: HomeController(),
      builder: (controller) {
        return WillPopScope(
          onWillPop: controller.goBack,
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 0,
            ),
            body: controller.hasInternet.value
                ? InAppWebView(
                    key: controller.webViewKey,
                    initialUrlRequest: URLRequest(url: controller.defaultUrl),
                    onWebViewCreated: (webController) {
                      controller.webViewController = webController;
                    },
                    onTitleChanged: controller.updateDislike,
                    onExitFullscreen: controller.exitFullscreen,
                    onEnterFullscreen: (webController) {
                      controller.enterFullscreen(webController, context);
                    },
                    onLoadStop: (webController, url) async {
                      String css = controller.getHideCss();
                      await controller.webViewController
                          .injectCSSCode(source: css);
                    },
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                      ),
                      const CircularProgressIndicator(
                        color: Colors.red,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('No internet connection'),
                      ),
                    ],
                  ),
            // floatingActionButton: Padding(
            //   padding: const EdgeInsets.only(bottom: 28.0),
            //   child: FloatingActionButton.small(
            //     onPressed: () {
            //       Get.bottomSheet(
            //         SettingsBottomSheet(
            //             webViewController: controller.webViewController),
            //       );
            //     },
            //     child: const Icon(Icons.settings),
            //   ),
            // ),
          ),
        );
      },
    );
  }
}
