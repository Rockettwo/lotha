import 'package:flutter/material.dart';
import 'dart:core';

import 'TranslatorPage.dart';

void main() => runApp(Lotha());

class Lotha extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final appTitle = 'Lotha';

    return new MaterialApp(
      title: appTitle,
      theme: new ThemeData(primarySwatch: Colors.blue, textTheme: TextTheme()),
      home: new TranslatorPage(),
    );
  }
}
