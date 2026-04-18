import 'package:flutter/material.dart';
import 'package:yu_ni_player/yu_ni_player.dart';
import 'package:yu_ni_player/engines/video_player_kit_engine.dart';

import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  YuNiPlayerPlugin.initialize(
    YuNiPlayerConfig(
      platformEngines: {
        PlatformKey.ios: (src) => VideoPlayerKitEngine(src),
        PlatformKey.android: (src) => VideoPlayerKitEngine(src),
        PlatformKey.macos: (src) => VideoPlayerKitEngine(src),
        PlatformKey.windows: (src) => VideoPlayerKitEngine(src),
        PlatformKey.web: (src) => VideoPlayerKitEngine(src),
        PlatformKey.defaultKey: (src) => VideoPlayerKitEngine(src),
      },
      maxActiveCount: 3,
      maxRecycledCount: 2,
    ),
  );

  runApp(const YuNiPlayerExampleApp());
}

class YuNiPlayerExampleApp extends StatelessWidget {
  const YuNiPlayerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YuNiPlayer Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}
