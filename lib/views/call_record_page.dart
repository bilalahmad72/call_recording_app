import 'package:call_recording_app/models/recording.dart';
import 'package:call_recording_app/services/audio_player_service.dart';
import 'package:call_recording_app/services/call_recording_service.dart';
import 'package:call_recording_app/utils/permission_util.dart';
import 'package:call_recording_app/views/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class CallRecorderPage extends StatefulWidget {
  const CallRecorderPage({super.key});

  @override
  State<CallRecorderPage> createState() => _CallRecorderPageState();
}

class _CallRecorderPageState extends State<CallRecorderPage> {
  final CallRecorderService _recorderService = CallRecorderService();
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  List<Recording> recordings = [];
  bool isRecording = false;

  bool _initializedPermissions = false;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeApp() async {
    if (!_initializedPermissions) {
      await PermissionUtils.checkAndRequestPermissions(context);
      _initializedPermissions = true;
    }
    await _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    try {
      _recorderService.onRecordingStateChanged = (recording) {
        setState(() => isRecording = recording);
        if (!recording) {
          _loadRecordings();
        }
      };

      await _recorderService.initialize();
      await _loadRecordings();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing: $e')),
        );
      }
    }
  }

  Future<void> _loadRecordings() async {
    final files = await _recorderService.getRecordings();
    setState(() => recordings = files);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _handleRecordingTap() async {
    try {
      if (isRecording) {
        await _recorderService.stopRecording();
      } else {
        await _recorderService.startRecording(context);
      }
      await _loadRecordings();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _recorderService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call Recorder'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsPage(
                  recorderService: _recorderService,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: EdgeInsets.all(8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Auto-record calls'),
                  Spacer(),
                  Switch(
                    value: _recorderService.isAutoRecordEnabled,
                    onChanged: (value) async {
                      await _recorderService.setAutoRecordEnabled(value);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final recording = recordings[index];
                final isPlaying =
                    _audioPlayer.currentlyPlayingPath == recording.path;

                return ListTile(
                  title: Text(recording.fileName),
                  subtitle:
                      Text('${recording.timestamp.toString().split('.')[0]}\n'
                          '${_formatFileSize(recording.size)}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () async {
                          try {
                            await _audioPlayer.playRecording(recording.path);
                            setState(() {});
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error playing recording: $e')),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          try {
                            if (_audioPlayer.currentlyPlayingPath ==
                                recording.path) {
                              await _audioPlayer.stopRecording();
                            }
                            await _recorderService
                                .deleteRecording(recording.path);
                            await _loadRecordings();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error deleting recording: $e'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleRecordingTap,
        backgroundColor: isRecording ? Colors.red : null,
        child: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
      ),
    );
  }
}
