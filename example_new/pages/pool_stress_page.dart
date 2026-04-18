import 'package:flutter/material.dart';
import 'package:yu_ni_player/yu_ni_player.dart';

import '../data/video_data.dart';

class PoolStressPage extends StatefulWidget {
  const PoolStressPage({super.key});

  @override
  State<PoolStressPage> createState() => _PoolStressPageState();
}

class _PoolStressPageState extends State<PoolStressPage> {
  final _pool = YuNiPlayerPool.instance;
  final List<_TestResult> _results = [];
  bool _isTesting = false;

  @override
  void dispose() {
    for (var i = 0; i < kTestVideos.length; i++) {
      _pool.release(
          YuNiVideoSource(id: 'stress-$i', url: kTestVideos[i].url));
    }
    super.dispose();
  }

  void _log(String name, bool pass, {String? detail}) {
    setState(() => _results.add(_TestResult(name: name, pass: pass, detail: detail)));
  }

  Future<void> _runTests() async {
    if (_isTesting) return;
    setState(() { _isTesting = true; _results.clear(); });

    await _pool.disposeAll();
    _pool.configure(maxActiveCount: 3, maxRecycledCount: 2);

    // 1. 活跃数量上限
    for (var i = 0; i < 5; i++) {
      _pool.acquire(YuNiVideoSource(id: 'stress-$i', url: kTestVideos[i].url));
      await Future.delayed(const Duration(milliseconds: 30));
    }
    _log('1. 活跃数量上限 (acquire×5)', _pool.activeCount <= 3,
        detail: 'activeCount=${_pool.activeCount} (应≤3)');

    // 2. 总量上限
    _log('2. 总量上限', _pool.activeCount + _pool.recycledCount <= 5,
        detail: 'total=${_pool.activeCount + _pool.recycledCount} (应≤5)');

    // 3. 命中活跃缓存
    await _pool.disposeAll();
    _pool.configure(maxActiveCount: 3, maxRecycledCount: 2);
    final src = YuNiVideoSource(id: 'cache-test', url: kTestVideos[0].url);
    final e1 = _pool.acquire(src);
    final e2 = _pool.acquire(src);
    _log('3. 命中活跃缓存返回同一实例', identical(e1, e2));
    await _pool.release(src);

    // 4. release 后进入回收池
    await _pool.disposeAll();
    _pool.configure(maxActiveCount: 3, maxRecycledCount: 2);
    final src2 = YuNiVideoSource(id: 'recycle-test', url: kTestVideos[0].url);
    _pool.acquire(src2);
    await _pool.release(src2);
    await Future.delayed(const Duration(milliseconds: 100));
    _log('4. release 后进入回收池', _pool.recycledCount > 0,
        detail: 'recycledCount=${_pool.recycledCount}');

    // 5. currentPlayer 不被 LRU 淘汰
    await _pool.disposeAll();
    _pool.configure(maxActiveCount: 3, maxRecycledCount: 2);
    final s1 = YuNiVideoSource(id: 'lru-1', url: kTestVideos[0].url);
    final s2 = YuNiVideoSource(id: 'lru-2', url: kTestVideos[1].url);
    final s3 = YuNiVideoSource(id: 'lru-3', url: kTestVideos[2].url);
    final s4 = YuNiVideoSource(id: 'lru-4', url: kTestVideos[3].url);
    final p1 = _pool.acquire(s1);
    _pool.acquire(s2);
    _pool.acquire(s3);
    _pool.currentPlayer = p1;
    _pool.acquire(s4);
    await Future.delayed(const Duration(milliseconds: 100));
    final p1Again = _pool.acquire(s1);
    _log('5. currentPlayer 不被 LRU 淘汰', identical(p1, p1Again),
        detail: 'activeCount=${_pool.activeCount}');
    _pool.currentPlayer = null;

    // 6. disposeAll 后所有实例 isDisposed
    await _pool.disposeAll();
    _pool.configure(maxActiveCount: 3, maxRecycledCount: 2);
    final engines = <YuNiPlayerEngine>[];
    for (var i = 0; i < 4; i++) {
      engines.add(_pool.acquire(
          YuNiVideoSource(id: 'dispose-$i', url: kTestVideos[i].url)));
    }
    await Future.delayed(const Duration(milliseconds: 100));
    await _pool.disposeAll();
    final allDisposed = engines.every((e) => e.isDisposed);
    _log('6. disposeAll 后所有实例 isDisposed', allDisposed,
        detail: '${engines.where((e) => e.isDisposed).length}/${engines.length}');

    setState(() => _isTesting = false);
  }

  @override
  Widget build(BuildContext context) {
    final passCount = _results.where((r) => r.pass).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('对象池压力测试'),
        actions: [
          if (_results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('$passCount/${_results.length}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: passCount == _results.length
                            ? Colors.green
                            : Colors.red)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatBox('活跃池', '${_pool.activeCount}/3', Colors.blue),
                _StatBox('回收池', '${_pool.recycledCount}/2', Colors.orange),
                _StatBox('总量', '${_pool.activeCount + _pool.recycledCount}/5',
                    Colors.purple),
              ],
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.memory, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('点击下方按钮开始测试',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final r = _results[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                        color: r.pass ? Colors.green.shade50 : Colors.red.shade50,
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            r.pass ? Icons.check_circle : Icons.cancel,
                            color: r.pass ? Colors.green : Colors.red,
                          ),
                          title: Text(r.name, style: const TextStyle(fontSize: 13)),
                          subtitle: r.detail != null
                              ? Text(r.detail!,
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade600))
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _isTesting ? null : _runTests,
            icon: _isTesting
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_arrow),
            label: Text(_isTesting ? '测试中...' : '运行对象池测试'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 18)),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

class _TestResult {
  const _TestResult({required this.name, required this.pass, this.detail});
  final String name;
  final bool pass;
  final String? detail;
}
