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
      Permission.notification,
    ];

    // Request each permission individually
    for (var permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        final result = await permission.request();
        if (!result.isGranted) {
          if (context.mounted) {
            final shouldOpenSettings = await _showPermissionDialog(
              context,
              permission: _getPermissionName(permission),
            );
            if (shouldOpenSettings) {
              await openAppSettings();
            }
          }
          return false;
        }
      }
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

    // Request permissions
    Map<Permission, PermissionStatus> statuses = await permissions.request();

    if (statuses.values.any((status) => status.isDenied)) {
      if (context.mounted) {
        final shouldOpenSettings = await _showPermissionDialog(
          context,
          permission: 'required permissions',
        );
        if (shouldOpenSettings) {
          await openAppSettings();
        }
      }
      return false;
    }

    return true;
  }

  static String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.phone:
        return 'Phone';
      case Permission.microphone:
        return 'Microphone';
      case Permission.audio:
        return 'Media & Audio';
      case Permission.notification:
        return 'Notifications';
      default:
        return permission.toString();
    }
  }

  static Future<bool> _showPermissionDialog(
    BuildContext context, {
    required String permission,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Permission Required'),
              content: Text(
                'This app needs access to $permission to function properly. '
                'Please grant the permission in Settings.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Not Now'),
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
