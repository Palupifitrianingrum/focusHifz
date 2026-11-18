import 'package:flutter/material.dart';
import 'app_state.dart';
import 'pages/tabs.dart';
import 'quran_api.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.load(); // nama, tema, qari, dan posisi baca yang tersimpan
  await QuranApi.warmCache();
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
