import 'dart:io';

/// 视频源数据模型（不可变）
///
/// 用于描述一个视频的来源信息，包括网络 URL 或本地文件、
/// 尺寸元数据、封面图等。[id] 字段作为对象池（YuNiPlayerPool）的 key。
///
/// [headers] 是视频源级别的 HTTP 请求头，用于防盗链签名、CDN token、
/// 鉴权等与 URL 绑定的场景。引擎初始化时会将其与 [YuNiEngineConfig.headers]
/// 合并，[headers] 中的同名 key 优先级更高。
class YuNiVideoSource {
  const YuNiVideoSource({
    required this.id,
    this.url,
    this.file,
    this.width,
    this.height,
    this.aspectRatio,
    this.cover,
    this.headers = const {},
  })  : assert(
          url != null || file != null,
          'YuNiVideoSource requires either url or file',
        ),
        assert(id.length > 0, 'id must not be empty');

  /// 唯一标识符（用于对象池 key）
  final String id;

  /// 网络 URL（与 [file] 二选一，至少提供其中一个）
  final String? url;

  /// 本地文件（与 [url] 二选一，至少提供其中一个）
  final File? file;

  /// 视频宽度（像素，可选）
  final int? width;

  /// 视频高度（像素，可选）
  final int? height;

  /// 宽高比（可选）
  final double? aspectRatio;

  /// 封面图 URL 或本地路径（可选）
  final String? cover;

  /// 视频源级别的 HTTP 请求头（默认空 Map）
  ///
  /// 用于防盗链签名、CDN token、鉴权等与 URL 绑定的场景。
  /// 引擎初始化时会与 [YuNiEngineConfig.headers] 合并，
  /// 本字段中的同名 key 优先级更高。
  final Map<String, String> headers;

  /// 是否横屏。
  ///
  /// - [aspectRatio] 为 null 时默认返回 `true`（横屏）
  /// - [aspectRatio] > 1.0 时返回 `true`
  /// - [aspectRatio] <= 1.0 时返回 `false`
  bool get isLandscape {
    if (aspectRatio == null) return true;
    return aspectRatio! > 1.0;
  }

  /// 将 [YuNiEngineConfig.headers] 与本视频源的 [headers] 合并。
  ///
  /// 合并规则：config.headers 作为基础，videoSource.headers 覆盖同名 key。
  Map<String, String> mergedHeaders(Map<String, String> configHeaders) {
    if (configHeaders.isEmpty) return headers;
    if (headers.isEmpty) return configHeaders;
    return {...configHeaders, ...headers};
  }
}
