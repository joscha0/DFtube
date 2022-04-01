import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:uni_links/uni_links.dart';

class HomeController extends GetxController {
  final String url = "https://m.youtube.com/";
  final GlobalKey webViewKey = GlobalKey();

  bool isPortrait = true;

  late InAppWebViewController webViewController;

  RxBool hasInternet = true.obs;

  Uri get defaultUrl =>
      Get.isPlatformDarkMode ? Uri.parse(url + "?theme=dark") : Uri.parse(url);
  late StreamSubscription _sub;

  final box = GetStorage();
  RxBool get hide => RxBool(box.read("cssHide") ?? true);

  RxBool isConnected = false.obs;
  late final StreamSubscription<InternetConnectionStatus> listener;

  void setHide(String key, bool value) {
    box.write(key, value);
  }

  void setConnectionStatus() async {
    isConnected.value = await InternetConnectionChecker().hasConnection;
    listener = InternetConnectionChecker().onStatusChange.listen(
      (InternetConnectionStatus status) {
        switch (status) {
          case InternetConnectionStatus.connected:
            isConnected.value = true;
            break;
          case InternetConnectionStatus.disconnected:
            // isConnected.value = false;
            break;
        }
      },
    );
  }

  @override
  void onInit() async {
    setConnectionStatus();
    super.onInit();
    initUniLinks();
  }

  @override
  void onClose() {
    super.onClose();
    _sub.cancel();
  }

  Future<void> initUniLinks() async {
    String? initialUrl;
    try {
      initialUrl = await getInitialLink();
      if (initialUrl != null) {
        webViewController.loadUrl(
            urlRequest: URLRequest(
                url: Get.isPlatformDarkMode
                    ? Uri.parse(initialUrl + "&theme=dark")
                    : Uri.parse(initialUrl)));
      }
    } on PlatformException {}
    _sub = linkStream.listen((String? uri) {
      log(uri.toString());
      if (uri != null) {
        webViewController.loadUrl(
            urlRequest: URLRequest(
                url: Get.isPlatformDarkMode
                    ? Uri.parse(uri + "&theme=dark")
                    : Uri.parse(uri)));
      }
    }, onError: (err) {});
  }

  void updateDislike(
      InAppWebViewController webController, String? title) async {
    Uri url = await webViewController.getUrl() ?? Uri();
    log(url.toString());
    Map<String, dynamic> data = await getData(url.toString());
    String source = "";
    if (data.isNotEmpty) {
      source = """
      document.querySelector(".slim-video-action-bar-actions").children[0].querySelector(".button-renderer-text").innerText = "${data['likes']}";
   document.querySelector(".slim-video-action-bar-actions").children[1].querySelector(".button-renderer-text").innerText = "${data['dislikes']}";
  """;
    }
    // try to update the dislike text 10 times
    for (int i = 0; i < 10; i++) {
      if (hasInternet.value) {
        await webViewController.evaluateJavascript(source: source);
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<Map<String, dynamic>> getData(String url) async {
    Map<String, dynamic> data = {};
    String baseUrl = "https://returnyoutubedislikeapi.com/votes?videoId=";
    List<String> parts = url.split("watch?v=");
    if (parts.length > 1) {
      String id = parts[1];
      Uri uri = Uri.parse(baseUrl + id);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      }
    }
    return data;
  }

  void exitFullscreen(InAppWebViewController webController) {
    if (isPortrait) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    // like label will get updated on fullscreen so need to reupdate
    updateDislike(webController, '');
  }

  void enterFullscreen(
      InAppWebViewController webController, BuildContext context) {
    isPortrait = context.orientation == Orientation.portrait;
    if (isPortrait) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    }
  }

  Future<bool> goBack() async {
    if (await webViewController.canGoBack()) {
      log('back');
      webViewController.goBack();
    } else {
      Get.dialog(AlertDialog(
        title: const Text('Do you want to exit'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            child: const Text('Yes'),
          ),
        ],
      ));
    }
    return false;
  }

  String cssHide = """
/* remove bottom app bar home and trending */
.pivot-w2w, .pivot-trending, .pivot-explore, .pivot-shorts{
    display: none!important;

}

/* increase width app bar buttons */
.pivot-subs{
width: 50%;
    position: absolute;
    left: 0;
    padding-top: 5px;
}
.pivot-library{
    width: 50%;
    position: absolute;
    left: 50%;
    padding-top: 5px;
}

/* hide home feed */
div[tab-identifier="FEwhat_to_watch"] {
    display: none!important;
}


/* hide featured feed */
ytm-item-section-renderer[data-content-type="related"] {
    display: none!important;
}
""";

  String getHideCss() {
    String css = "";

    // if (hide.value) {
    css += cssHide;
    // }
    return css;
  }
}
