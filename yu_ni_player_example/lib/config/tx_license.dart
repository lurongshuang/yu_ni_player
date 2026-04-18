import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 腾讯播放器 license 配置
///
/// license 信息存储在 android/local.properties（不提交到 git），
/// 通过 BuildConfig 注入，再经 MethodChannel 传给 Dart 层。
class TxLicense {
  TxLicense._();

  static const _channel = MethodChannel('com.uneed.yuniphotos/config');

  static String _licenseUrl = '';
  static String _licenseKey = '';

  static String get licenseUrl => _licenseUrl;
  static String get licenseKey => _licenseKey;

  /// 从 native 层读取 license（仅 Android 有效）
  static Future<void> load() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      _licenseUrl = await _channel.invokeMethod<String>('getTxLicenseUrl') ?? '';
      _licenseKey = await _channel.invokeMethod<String>('getTxLicenseKey') ?? '';
    } catch (e) {
      debugPrint('[TxLicense] Failed to load license: $e');
    }
  }
}
