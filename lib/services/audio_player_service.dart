import 'package:just_audio/just_audio.dart';
import 'dart:developer';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentlyPlayingPath;

  bool get isPlaying => _player.playing;

  String? get currentlyPlayingPath => _currentlyPlayingPath;

  Future<void> playRecording(String path) async {
    try {
      if (_currentlyPlayingPath == path && _player.playing) {
        await pauseRecording();
      } else {
        await _player.setFilePath(path);
        await _player.play();
        _currentlyPlayingPath = path;
      }
    } catch (e) {
      log('Error playing recording: $e');
      rethrow;
    }
  }

  Future<void> pauseRecording() async {
    try {
      await _player.pause();
      _currentlyPlayingPath = null;
    } catch (e) {
      log('Error pausing recording: $e');
      rethrow;
    }
  }

  Future<void> stopRecording() async {
    try {
      await _player.stop();
      _currentlyPlayingPath = null;
    } catch (e) {
      log('Error stopping recording: $e');
      rethrow;
    }
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  void dispose() {
    _player.dispose();
  }
}
