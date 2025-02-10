import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'package:call_recording_app/models/recording.dart';
import 'package:call_recording_app/utils/permission_util.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:phone_state/phone_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;
  bool _isAutoRecordEnabled = false;
  StreamSubscription<PhoneState>? _phoneStateSubscription;

  Function(bool)? onRecordingStateChanged;

  Future<void> initialize() async {
    try {
      await _logPermissionStatus();
      await _verifyStoragePath();

      final prefs = await SharedPreferences.getInstance();
      _isAutoRecordEnabled = prefs.getBool('auto_record_enabled') ?? false;

      _phoneStateSubscription =
          PhoneState.stream.listen(_handlePhoneStateChange);

      log('CallRecorderService initialized successfully');
    } catch (e) {
      log('Error initializing CallRecorderService: $e');
      rethrow;
    }
  }

  void _handlePhoneStateChange(PhoneState event) async {
    log('Phone state changed: ${event.status}');

    switch (event.status) {
      case PhoneStateStatus.CALL_STARTED:
        if (_isAutoRecordEnabled && !_isRecording) {
          await startRecording(null);
        }
        break;
      case PhoneStateStatus.CALL_ENDED:
        if (_isRecording) {
          final path = await stopRecording();
          if (path != null) {
            log('Call recording saved at: $path');
          }
        }
        break;
      default:
        break;
    }
  }

  Future<void> _logPermissionStatus() async {
    final phone = await Permission.phone.status;
    final mic = await Permission.microphone.status;
    final storage = await Permission.storage.status;
    log('Permission status: Phone=$phone, Mic=$mic, Storage=$storage');
  }

  Future<void> _verifyStoragePath() async {
    final directory = await getExternalStorageDirectory();
    log('Storage path: ${directory?.path}');
    if (directory != null) {
      final exists = await directory.exists();
      log('Directory exists: $exists');
    }
  }

  Future<void> startRecording(BuildContext? context) async {
    if (!_isRecording) {
      try {
        if (context != null) {
          bool hasPermissions =
              await PermissionUtils.checkAndRequestPermissions(context);
          if (!hasPermissions) {
            throw Exception('Required permissions not granted');
          }
        }

        // Make sure we have a valid directory
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          throw Exception('Unable to access external storage');
        }

        // Create directory if it doesn't exist
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _currentRecordingPath = '${directory.path}/call_$timestamp.m4a';

        log('Starting recording at: $_currentRecordingPath');

        final config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
          device: null, // Let the system choose the appropriate device
        );

        await _recorder.start(config, path: _currentRecordingPath!);
        _isRecording = true;
        onRecordingStateChanged?.call(true);
        log('Recording started successfully');
      } catch (e) {
        log('Error starting recording: $e');
        _isRecording = false;
        onRecordingStateChanged?.call(false);
        rethrow;
      }
    }
  }

  Future<String?> stopRecording() async {
    if (_isRecording) {
      try {
        await _recorder.stop();
        _isRecording = false;
        onRecordingStateChanged?.call(false);

        /// Verify file exists and has content
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          final size = await file.length();
          if (size > 0) {
            log('Recording stopped successfully. File size: $size bytes');
            return _currentRecordingPath;
          } else {
            log('Recording file is empty');
            await file.delete();
            return null;
          }
        }
        return null;
      } catch (e) {
        log('Error stopping recording: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> setAutoRecordEnabled(bool enabled) async {
    _isAutoRecordEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_record_enabled', enabled);
  }

  Future<List<Recording>> getRecordings() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) return [];

      final files = directory
          .listSync()
          .where((file) => file.path.endsWith('.m4a'))
          .map((file) {
        final stats = file.statSync();
        return Recording(
          path: file.path,
          fileName: file.path.split('/').last,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
              int.parse(file.path.split('/').last.split('_')[1].split('.')[0])),
          size: stats.size,
        );
      }).toList();

      // Sort by timestamp, newest first
      files.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      log('Found ${files.length} recordings');
      return files;
    } catch (e) {
      log('Error getting recordings: $e');
      return [];
    }
  }

  Future<void> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        log('Recording deleted: $path');
      }
    } catch (e) {
      log('Error deleting recording: $e');
      rethrow;
    }
  }

  bool get isAutoRecordEnabled => _isAutoRecordEnabled;

  bool get isRecording => _isRecording;

  Future<void> dispose() async {
    await _phoneStateSubscription?.cancel();
    await _recorder.dispose();
  }
}
