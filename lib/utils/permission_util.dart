import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static Future<bool> checkAndRequestPermissions(BuildContext context) async {
    if (await _isAndroid13OrAbove()) {
      return await _checkAndRequestPermissionsAndroid13Plus(context);
    } else {
      return await _checkAndRequestPermissionsLegacy(context);
    }
  }

  static Future<bool> _isAndroid13OrAbove() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33;
    }
    return false;
  }

  static Future<bool> _checkAndRequestPermissionsAndroid13Plus(
      BuildContext context) async {
    final permissions = [
      Permission.phone,
      Permission.microphone,
      Permission.audio,
    ];

    /// Check current status
    final statuses =
        await Future.wait(permissions.map((permission) => permission.status));

    if (statuses.every((status) => status.isGranted)) {
      return true;
    }

    /// Request permissions
    final results = await permissions.request();

    if (results.values.any((status) => status.isDenied) && context.mounted) {
      bool shouldRequest = await _showPermissionDialog(context);
      if (shouldRequest) {
        await openAppSettings();
      }
      return false;
    }

    return true;
  }

  static Future<bool> _checkAndRequestPermissionsLegacy(
      BuildContext context) async {
    final permissions = [
      Permission.phone,
      Permission.microphone,
      Permission.storage,
    ];

    /// Check current status
    final statuses =
        await Future.wait(permissions.map((permission) => permission.status));

    if (statuses.every((status) => status.isGranted)) {
      return true;
    }

    /// Request permissions
    final results = await permissions.request();

    if (results.values.any((status) => status.isDenied) && context.mounted) {
      bool shouldRequest = await _showPermissionDialog(context);
      if (shouldRequest) {
        await openAppSettings();
      }
      return false;
    }

    return true;
  }

  static Future<bool> _showPermissionDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Permissions Required'),
              content: const Text(
                'This app needs access to phone, microphone, and storage to record calls. '
                'Please grant these permissions in Settings.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Open Settings'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
