import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'migrate_firebase_auth_keychain_platform_interface.dart';

/// An implementation of [MigrateFirebaseAuthKeychainPlatform] that uses method channels.
class MethodChannelMigrateFirebaseAuthKeychain extends MigrateFirebaseAuthKeychainPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('migrate_firebase_auth_keychain');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
