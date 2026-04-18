import 'package:flutter/material.dart';
import 'package:yu_ni_player/yu_ni_player.dart';
import 'package:yu_ni_player_video_player_kit/yu_ni_player_video_player_kit.dart';

import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 如需使用腾讯播放器，在此初始化 License：
  // import 'package:yu_ni_player_tx_player/yu_ni_player_tx_player.dart';
  // TXPlayerEngine.initLicense('your-license-url', 'your-license-key');

  // 如需使用 media_kit，在此初始化：
  // import 'package:yu_ni_player_media_kit/yu_ni_player_media_kit.dart';
  // MediaKitEngine.initLicense();

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
