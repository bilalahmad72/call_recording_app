import 'package:call_recording_app/services/call_recording_service.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final CallRecorderService recorderService;

  const SettingsPage({
    super.key,
    required this.recorderService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Auto-record calls'),
            subtitle: const Text(
                'Automatically record all incoming and outgoing calls'),
            trailing: StatefulBuilder(
              builder: (context, setState) {
                return Switch(
                  value: recorderService.isAutoRecordEnabled,
                  onChanged: (value) async {
                    await recorderService.setAutoRecordEnabled(value);
                    setState(() {});
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
