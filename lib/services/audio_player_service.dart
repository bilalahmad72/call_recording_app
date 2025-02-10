import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'dart:developer';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentlyPlayingPath;

  bool get isPlaying => _player.playing;

  String? get currentlyPlayingPath => _currentlyPlayingPath;

  Future<void> playRecording(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Recording file not found');
      }

      final size = await file.length();
      if (size == 0) {
        throw Exception('Recording file is empty');
      }

      if (_currentlyPlayingPath == path && _player.playing) {
        await pauseRecording();
      } else {
        /// Stop any currently playing audio first
        if (_player.playing) {
          await _player.stop();
        }

        /// Set the audio source and play
        await _player.setFilePath(path);
        await _player.play();
        _currentlyPlayingPath = path;
      }
    } catch (e) {
      log('Error playing recording: $e');
      _currentlyPlayingPath = null;
      rethrow;
    }
  }

  Future<void> pauseRecording() async {
    try {
      if (_player.playing) {
        await _player.pause();
      }
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
