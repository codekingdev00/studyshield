import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Plays a lesson's YouTube video in-app. Requires an active internet
/// connection to load — checked before the player is shown, and re-checked
/// if the connection drops mid-session.
class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key, required this.title, required this.videoUrl});

  final String title;
  final String videoUrl;

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  YoutubePlayerController? _controller;
  bool _checking = true;
  bool _hasInternet = false;

  @override
  void initState() {
    super.initState();
    _checkAndInit();
  }

  void _retry() {
    setState(() => _checking = true);
    _checkAndInit();
  }

  Future<void> _checkAndInit() async {
    final result = await Connectivity().checkConnectivity();
    final online = !result.contains(ConnectivityResult.none);

    if (!mounted) return;
    setState(() {
      _hasInternet = online;
      _checking = false;
    });

    if (online) {
      final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
      if (videoId != null) {
        _controller = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101418),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101418),
        title: Text(widget.title),
      ),
      body: Center(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_checking) {
      return const CircularProgressIndicator();
    }

    if (!_hasInternet) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No internet connection',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'This video requires an internet connection to play. '
              'Connect to Wi-Fi or mobile data and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (_controller == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'This video link looks invalid.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return YoutubePlayer(
      controller: _controller!,
      showVideoProgressIndicator: true,
      progressIndicatorColor: Colors.tealAccent,
    );
  }
}
