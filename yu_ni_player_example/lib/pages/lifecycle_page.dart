import 'package:flutter/material.dart';
import 'package:yu_ni_player_base/yu_ni_player_base.dart';
import 'package:yu_ni_player_video_player_kit/yu_ni_player_video_player_kit.dart';

import '../data/video_data.dart';

class LifecyclePage extends StatefulWidget {
  const LifecyclePage({super.key});

  @override
  State<LifecyclePage> createState() => _LifecyclePageState();
}

class _LifecyclePageState extends State<LifecyclePage>
    with WidgetsBindingObserver {
  late YuNiPlayerEngine _engine;
  final List<String> _log = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = VideoPlayerKitEngine(
      YuNiVideoSource(id: 'lifecycle-test', url: kTestVideos.first.url),
    );
    _engine.stateNotifier.addListener(_onStateChanged);
    _addLog('引擎创建，state=idle');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine.stateNotifier.removeListener(_onStateChanged);
    _engine.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _addLog('App 生命周期: $state');
  }

  void _onStateChanged() => _addLog('引擎状态变化: ${_engine.state}');

  void _addLog(String msg) {
    if (mounted) {
      setState(() {
        _log.insert(0, '[${_ts()}] $msg');
        if (_log.length > 60) _log.removeLast();
      });
    }
  }

  String _ts() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:'
        '${n.minute.toString().padLeft(2, '0')}:'
        '${n.second.toString().padLeft(2, '0')}';
  }

  Future<void> _init() async {
    _addLog('调用 init()...');
    await _engine.init();
    if (mounted) setState(() => _initialized = true);
  }

  Future<void> _switchEngine() async {
    _addLog('切换引擎...');
    final old = _engine;
    old.stateNotifier.removeListener(_onStateChanged);
    _engine = VideoPlayerKitEngine(
      YuNiVideoSource(id: 'lifecycle-2', url: kTestVideos[1].url),
    );
    _engine.stateNotifier.addListener(_onStateChanged);
    setState(() => _initialized = false);
    await old.dispose();
    _addLog('旧引擎 isDisposed=${old.isDisposed}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('生命周期测试')),
      body: Column(
        children: [
          // 播放器
          SizedBox(
            height: 200,
            child: _initialized
                ? YuNiPlayer(
                    player: _engine,
                    backgroundColor: Colors.black,
                    showDefaultControls: true,
                  )
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: Text('点击 Init 初始化',
                          style: TextStyle(color: Colors.white54)),
                    ),
                  ),
          ),

          // 控制按钮
          Padding(
            padding: const EdgeInsets.all(10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _init,
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Init'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _engine.play(),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Play'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                ),
                ElevatedButton.icon(
                  onPressed: () => _engine.pause(),
                  icon: const Icon(Icons.pause, size: 16),
                  label: const Text('Pause'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white),
                ),
                ElevatedButton.icon(
                  onPressed: _switchEngine,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('切换引擎'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white),
                ),
              ],
            ),
          ),

          // 说明
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '💡 测试方法：\n'
              '1. Init → Play 开始播放\n'
              '2. 按 Home 键将 App 切到后台 → 日志出现 paused\n'
              '3. 切回 App → 日志出现 playing（自动恢复）\n'
              '4. 点击"切换引擎"验证旧引擎 isDisposed=true',
              style: TextStyle(fontSize: 12),
            ),
          ),

          const Divider(height: 12),

          // 日志
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _log.length,
              itemBuilder: (_, i) {
                final entry = _log[i];
                final isState = entry.contains('状态变化');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    entry,
                    style: TextStyle(
                      fontSize: 12,
                      color: isState
                          ? Colors.blue.shade700
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          isState ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
