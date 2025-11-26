import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioButton extends StatefulWidget {
  final String audioAssetPath;
  final Color color;

  const AudioButton({
    super.key,
    required this.audioAssetPath,
    this.color = Colors.blue,
  });

  @override
  State<AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<AudioButton> {
  late AudioPlayer _player;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    
    // Listen to player state changes to update UI when audio finishes
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    try {
      // Stop if currently playing (allows restart)
      await _player.stop(); 
      
      // AssetSource automatically looks in "assets/"
      // So if path is "assets/audio/file.mp3", we pass "audio/file.mp3"
      final cleanPath = widget.audioAssetPath.replaceFirst('assets/', '');
      
      await _player.play(AssetSource(cleanPath));
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio not found: ${widget.audioAssetPath}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _playAudio,
      icon: Icon(
        _isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
        color: widget.color,
        size: 32,
      ),
      tooltip: 'Listen',
    );
  }
}