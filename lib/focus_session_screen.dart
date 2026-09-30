import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'lock_task_service.dart';
import 'models/study_material.dart';
import 'video_screen.dart';

const int kMinSeconds = 5;
const int kMaxSeconds = 3600;

class FocusSessionScreen extends StatefulWidget {
  const FocusSessionScreen({super.key, required this.material});

  final StudyMaterial material;

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  static const _presets = <int>[5, 30, 60, 300, 600, 900, 1800, 3600];

  Timer? _timer;
  late int _chosenSeconds = (widget.material.suggestedMinutes * 60)
      .clamp(kMinSeconds, kMaxSeconds);
  int _remaining = 0;
  bool _sessionActive = false;
  bool _locked = false;
  bool _completed = false;

  Future<void> _startReading() async {
    final locked = await LockTaskService.start();
    await WakelockPlus.enable();
    if (!mounted) return;
    setState(() {
      _sessionActive = true;
      _completed = false;
      _locked = locked;
      _remaining = _chosenSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        setState(() => _remaining = 0);
        _endSession(completed: true);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _endSession({bool completed = false}) async {
    _timer?.cancel();
    await LockTaskService.stop();
    await WakelockPlus.disable();
    if (!mounted) return;
    setState(() {
      _sessionActive = false;
      _locked = false;
      _completed = completed;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_sessionActive) {
      LockTaskService.stop();
      WakelockPlus.disable();
    }
    super.dispose();
  }

  String _format(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  String _label(int seconds) {
    if (seconds >= 3600) return '1 hr';
    if (seconds >= 60 && seconds % 60 == 0) return '${seconds ~/ 60} min';
    if (seconds < 60) return '$seconds sec';
    return _format(seconds);
  }

  Future<void> _pickCustom() async {
    final minCtrl = TextEditingController(text: '${_chosenSeconds ~/ 60}');
    final secCtrl = TextEditingController(text: '${_chosenSeconds % 60}');
    String? error;

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF1B2127),
          title: const Text('Custom time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _numField(minCtrl, 'Minutes')),
                  const SizedBox(width: 12),
                  Expanded(child: _numField(secCtrl, 'Seconds')),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                error ?? 'Between 5 seconds and 1 hour.',
                style: TextStyle(
                  color: error == null ? Colors.white38 : Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final total = (int.tryParse(minCtrl.text) ?? 0) * 60 +
                    (int.tryParse(secCtrl.text) ?? 0);
                if (total < kMinSeconds || total > kMaxSeconds) {
                  setLocal(() =>
                      error = 'Time must be 5 seconds to 1 hour (60 min).');
                  return;
                }
                Navigator.pop(ctx, total);
              },
              child: const Text('Set'),
            ),
          ],
        ),
      ),
    );

    if (result != null) setState(() => _chosenSeconds = result);
  }

  void _openVideo(StudyMaterial material) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoScreen(
          title: material.title,
          videoUrl: material.videoUrl,
        ),
      ),
    );
  }

  Widget _numField(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final material = widget.material;

    return PopScope(
      canPop: !_sessionActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _sessionActive) _endSession();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101418),
        appBar: AppBar(
          backgroundColor: const Color(0xFF101418),
          title: Text(material.title),
          automaticallyImplyLeading: !_sessionActive,
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_sessionActive) _buildTimerBanner(),
              if (_completed) _buildCompletedBanner(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: Icon(material.icon, size: 18),
                            label: Text(material.subject),
                          ),
                          if (material.hasVideo)
                            ActionChip(
                              avatar: const Icon(Icons.play_circle_fill,
                                  size: 18, color: Colors.redAccent),
                              label: const Text('Watch Video'),
                              onPressed: () => _openVideo(material),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        material.content.trim(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _sessionActive ? _buildStopBar() : _buildStartBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1B2127),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Study time',
                  style: TextStyle(color: Colors.white54)),
              Text(
                _format(_chosenSeconds),
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _chosenSeconds.toDouble(),
            min: kMinSeconds.toDouble(),
            max: kMaxSeconds.toDouble(),
            divisions: (kMaxSeconds - kMinSeconds) ~/ 5,
            label: _format(_chosenSeconds),
            onChanged: (v) => setState(() => _chosenSeconds = v.round()),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              for (final p in _presets)
                ChoiceChip(
                  label: Text(_label(p)),
                  selected: _chosenSeconds == p,
                  onSelected: (_) => setState(() => _chosenSeconds = p),
                ),
              ActionChip(
                avatar: const Icon(Icons.edit, size: 16),
                label: const Text('Custom'),
                onPressed: _pickCustom,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _startReading,
              icon: const Icon(Icons.lock_clock),
              label: Text('Start Reading (${_label(_chosenSeconds)})'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _endSession,
          icon: const Icon(Icons.stop_circle),
          label: const Text('Stop Session'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerBanner() {
    final progress = 1 - (_remaining / _chosenSeconds).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      color: Colors.teal.withValues(alpha: 0.15),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Column(
        children: [
          Text(
            _format(_remaining),
            style: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white12,
            color: Colors.tealAccent,
          ),
          const SizedBox(height: 8),
          Text(
            _locked
                ? 'Screen locked — other apps are blocked until time is up or you stop.'
                : 'Reading in progress. Screen pinning unavailable on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _locked ? Colors.white38 : Colors.orangeAccent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedBanner() {
    return Container(
      width: double.infinity,
      color: Colors.green.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(14),
      child: const Text(
        'Session complete! Screen unlocked.',
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.greenAccent, fontWeight: FontWeight.w600),
      ),
    );
  }
}
