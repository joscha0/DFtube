import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isConnected = false;
  late final StreamSubscription<InternetConnectionStatus> listener;

  final String url = "https://m.youtube.com/";
  final GlobalKey webViewKey = GlobalKey();

  bool isPortrait = true;

  late InAppWebViewController webViewController;

  Uri get defaultUrl =>
      SchedulerBinding.instance!.window.platformBrightness == Brightness.dark
          ? Uri.parse(url + "?theme=dark")
          : Uri.parse(url);

  @override
  void initState() {
    setConnectionStatus();
    super.initState();
  }

  void setConnectionStatus() async {
    isConnected = await InternetConnectionChecker().hasConnection;
    listener = InternetConnectionChecker().onStatusChange.listen(
      (InternetConnectionStatus status) {
        switch (status) {
          case InternetConnectionStatus.connected:
            setState(() {
              isConnected = true;
            });
            break;
          case InternetConnectionStatus.disconnected:
            print(webViewController.getUrl());
            // setState(() {
            isConnected = false;
            // });
            break;
        }
      },
    );
  }

  Future<bool> goBack(BuildContext context) async {
    if (await webViewController.canGoBack()) {
      log('back');
      webViewController.goBack();
    } else {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: const Text('Do you want to exit'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
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

  void updateDislike(
      InAppWebViewController webController, String? title) async {
    Uri url = await webViewController.getUrl() ?? Uri();
    log(url.toString());
    if (isConnected) {
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
    isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    if (isPortrait) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    }
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => goBack(context),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
        ),
        body: isConnected
            ? InAppWebView(
                key: webViewKey,
                initialUrlRequest: URLRequest(url: defaultUrl),
                onWebViewCreated: (webController) {
                  webViewController = webController;
                },
                onTitleChanged: updateDislike,
                onExitFullscreen: exitFullscreen,
                onEnterFullscreen: (webController) {
                  enterFullscreen(webController, context);
                },
                onLoadStop: (webController, url) async {
                  String css = getHideCss();
                  await webViewController.injectCSSCode(source: css);
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
  }
}
