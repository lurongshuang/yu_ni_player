import 'package:flutter/material.dart';
import 'package:yu_ni_player_base/yu_ni_player_base.dart';
import 'package:yu_ni_player_media_kit/yu_ni_player_media_kit.dart';
import 'package:yu_ni_player_video_player_kit/yu_ni_player_video_player_kit.dart';

import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // media_kit 必须在 runApp 之前初始化
  MediaKitEngine.initLicense();

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
