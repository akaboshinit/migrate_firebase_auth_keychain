
import 'migrate_firebase_auth_keychain_platform_interface.dart';

class MigrateFirebaseAuthKeychain {
  Future<String?> getPlatformVersion() {
    return MigrateFirebaseAuthKeychainPlatform.instance.getPlatformVersion();
  }
}
