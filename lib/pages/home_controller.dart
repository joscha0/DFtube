import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class HomeController extends GetxController {
  final String url = "https://m.youtube.com/";
  final GlobalKey webViewKey = GlobalKey();

  bool isPortrait = true;

  late InAppWebViewController webViewController;

  late StreamSubscription<ConnectivityResult> subscription;

  RxBool hasInternet = true.obs;

  @override
  void onInit() async {
    super.onInit();
    ConnectivityResult connectivityResult =
        await (Connectivity().checkConnectivity());
    hasInternet.value = connectivityResult != ConnectivityResult.none;
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        hasInternet.value = true;
        subscription.cancel();
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    subscription.cancel();
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
}
