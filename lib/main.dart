import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'constants/theme.dart';
import 'screens/main_workspace.dart';

import 'dart:html' as html;

void main() {
  // Unconventional fix: Forcefully inject CSS to lock the browser viewport via dart:html
  // This guarantees the browser canvas cannot scroll, without needing an index.html refresh.
  html.document.body?.style.overflow = 'hidden';
  html.document.documentElement?.style.overflow = 'hidden';
  html.document.body?.style.position = 'fixed';
  html.document.body?.style.width = '100vw';
  html.document.body?.style.height = '100vh';
  html.document.body?.style.margin = '0';
  html.document.body?.style.padding = '0';
  
  runApp(const OvercastApp());
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

class OvercastApp extends StatelessWidget {
  const OvercastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Overcast Clinical Analysis Engine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      scrollBehavior: AppScrollBehavior(),
      home: const MainWorkspace(),
    );
  }
}
