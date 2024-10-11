import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'gui/main_page.dart';

const double fontSize = 23.5;
Color mainColor = const Color(0xff193838);
Color mainColor2 = const Color(0x36363636);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yet Another Note App',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: mainColor, brightness: Brightness.light),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
            toolbarHeight: 70.0,
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
            centerTitle: true,
            titleTextStyle: const TextStyle(fontSize: fontSize)),
        textSelectionTheme: const TextSelectionThemeData(
            cursorColor: (Color.fromARGB(255, 2, 7, 41)), selectionHandleColor: Color.fromARGB(255, 40, 53, 147)),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: mainColor2, brightness: Brightness.dark),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
            toolbarHeight: 70.0,
            backgroundColor: mainColor2,
            foregroundColor: Colors.white,
            centerTitle: true,
            titleTextStyle: const TextStyle(fontSize: fontSize)),
        textSelectionTheme: const TextSelectionThemeData(
            cursorColor: (Color.fromARGB(255, 159, 162, 182)),
            selectionHandleColor: Color.fromARGB(255, 123, 127, 129)),
      ),
      home: const MainPage(),
    );
  }
}

void showToast(String message) {
  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: const Color.fromARGB(134, 0, 0, 0),
      textColor: Colors.white,
      fontSize: 14.0);
}

class Note {
  final int id;
  final String title;
  final String content;
  final String modificationDate;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.modificationDate,
  });

  @override
  String toString() {
    return '{id: $id, title: $title, content: $content, modificationDate: $modificationDate}';
  }
}
