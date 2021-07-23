import 'package:cometmessenger/login_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chats_list.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Comet Messenger',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        cursorColor: Colors.white
      ),
      home: ChatsList(),
    );
  }
}