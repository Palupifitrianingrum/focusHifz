import 'package:flutter/material.dart';
import 'app_state.dart';
import 'pages/tabs.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const focusHifzApp());
}

class focusHifzApp extends StatelessWidget {
  const focusHifzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => MaterialApp(
        title: 'flowHifz',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: app.themeMode,
        home: const Shell(),
      ),
    );
  }
}
