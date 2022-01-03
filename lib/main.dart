import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  final Color primaryColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        backgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: primaryColor,
          primary: primaryColor,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(primary: Colors.black),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        backgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: primaryColor,
          primary: primaryColor,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(primary: Colors.white),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
