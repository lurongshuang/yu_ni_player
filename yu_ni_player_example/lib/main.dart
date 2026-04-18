import 'package:flutter/material.dart';
import 'package:yu_ni_player_base/yu_ni_player_base.dart';
import 'package:yu_ni_player_media_kit/yu_ni_player_media_kit.dart';
import 'package:yu_ni_player_tx_player/yu_ni_player_tx_player.dart';
import 'package:yu_ni_player_video_player_kit/yu_ni_player_video_player_kit.dart';

import 'config/tx_license.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // media_kit 必须在 runApp 之前初始化
  MediaKitEngine.initLicense();

  // 从 native BuildConfig 读取腾讯 license（存于 local.properties，不提交 git）
  await TxLicense.load();
  if (TxLicense.licenseUrl.isNotEmpty) {
    TXPlayerEngine.initLicense(TxLicense.licenseUrl, TxLicense.licenseKey);
  }

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
