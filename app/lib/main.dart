import 'package:flutter/material.dart';
import 'app_state.dart';
import 'pages/tabs.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HifzFlowApp());
}

class HifzFlowApp extends StatelessWidget {
  const HifzFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => MaterialApp(
        title: 'HifzFlow',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: app.themeMode,
        home: const Shell(),
      ),
    );
  }
}
