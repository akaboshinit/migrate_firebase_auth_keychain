import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'migrate_firebase_auth_keychain_method_channel.dart';

abstract class MigrateFirebaseAuthKeychainPlatform extends PlatformInterface {
  /// Constructs a MigrateFirebaseAuthKeychainPlatform.
  MigrateFirebaseAuthKeychainPlatform() : super(token: _token);

  static final Object _token = Object();

  static MigrateFirebaseAuthKeychainPlatform _instance = MethodChannelMigrateFirebaseAuthKeychain();

  /// The default instance of [MigrateFirebaseAuthKeychainPlatform] to use.
  ///
  /// Defaults to [MethodChannelMigrateFirebaseAuthKeychain].
  static MigrateFirebaseAuthKeychainPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MigrateFirebaseAuthKeychainPlatform] when
  /// they register themselves.
  static set instance(MigrateFirebaseAuthKeychainPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
