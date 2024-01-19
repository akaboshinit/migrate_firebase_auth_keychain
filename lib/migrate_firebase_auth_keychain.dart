import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MigrateFirebaseAuth {
  final _keyChainPlugin = _FirebaseAuthBackupAndMigrateKeychain();
  final _sharedPreferencesPlugin =
      _FirebaseAuthBackupAndMigrateSharedPreferences();

  Future<void> migrateFirebaseAuthData({
    void Function(Uint8List authData)? onRestoreCompleted,
    void Function(Exception error)? onRestoreFailed,
  }) async {
    ({String authKey, String backupAuthKey, String serviceName}) keychainName;
    try {
      keychainName = await _getKeychainName();
    } on Exception catch (e) {
      onRestoreFailed?.call(e);
      return;
    }

    final authData = await _keyChainPlugin.getKeychain(
      serviceName: keychainName.serviceName,
      keychainKey: keychainName.authKey,
    );
    final spFirebaseAuthData =
        await _sharedPreferencesPlugin.getFirebaseAuthData();
    if (authData == null && spFirebaseAuthData != null) {
      final spBackupAuthData = await restoreFirebaseAuthData();
      onRestoreCompleted?.call(spBackupAuthData);
    } else {
      onRestoreFailed?.call(
        Exception(
          'keychainAuthData ${authData != null ? "exists" : "null"} or sharedPreferencesAuthData ${spFirebaseAuthData != null ? "exists" : "null"}',
        ),
      );
    }
  }

  Future<void> backupFirebaseAuthData({
    void Function(Uint8List authData)? onBackupCompleted,
    void Function(String message)? onBackupFailed,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      onBackupFailed?.call("currentUser is null");
      return;
    }

    final firebaseApp = Firebase.app();
    await _sharedPreferencesPlugin.setFirebaseAppId(
      firebaseApp.options.appId,
    );
    // await _sharedPreferencesPlugin.setFirebaseAppName(
    //   firebaseApp.name,
    // );

    final keychainName = await _getKeychainName();
    final authData = await _keyChainPlugin.getKeychain(
      serviceName: keychainName.serviceName,
      keychainKey: keychainName.authKey,
    );
    if (authData == null) {
      onBackupFailed?.call("keychain authData is null");
      return;
    }

    await _keyChainPlugin.setKeychain(
      serviceName: keychainName.serviceName,
      keychainKey: keychainName.backupAuthKey,
      authData: authData,
    );
    await _sharedPreferencesPlugin.setFirebaseAuthData(authData);

    onBackupCompleted?.call(authData);
  }

  Future<Uint8List> restoreFirebaseAuthData() async {
    final keychainName = await _getKeychainName();

    final spFirebaseAuthData =
        await _sharedPreferencesPlugin.getFirebaseAuthData();

    if (spFirebaseAuthData == null) {
      throw Exception('SharedPreferences authData is null');
    }

    await _keyChainPlugin.setKeychain(
      authData: spFirebaseAuthData,
      serviceName: keychainName.serviceName,
      keychainKey: keychainName.authKey,
    );

    return spFirebaseAuthData;
  }

  Future<void> deleteKeychainFirebaseAuthData() async {
    final keychainName = await _getKeychainName();

    await _keyChainPlugin.deleteKeychain(
      serviceName: keychainName.serviceName,
      keychainKey: keychainName.authKey,
    );
  }

  Future<void> deleteBackupAuthData() async {
    final keychainName = await _getKeychainName();
    await _keyChainPlugin.deleteKeychain(
      serviceName: keychainName.serviceName,
      keychainKey: keychainName.backupAuthKey,
    );

    await _sharedPreferencesPlugin.deleteFirebaseAuthData();
    await _sharedPreferencesPlugin.deleteFirebaseAppId();
    await _sharedPreferencesPlugin.deleteFirebaseAppName();
  }

  Future<Map<String, dynamic>> checkFirebaseAuthDataExists() async {
    final keychainName = await _getKeychainName();

    final authData = await _keyChainPlugin.getKeychain(
      serviceName: keychainName.serviceName,
      keychainKey: keychainName.authKey,
    );
    final authDataBackup = await _keyChainPlugin.getKeychain(
      serviceName: keychainName.serviceName,
      keychainKey: keychainName.backupAuthKey,
    );
    final spFirebaseAuthData =
        await _sharedPreferencesPlugin.getFirebaseAuthData();

    final allKeychainData = await _keyChainPlugin.getAllKeychainData(
      serviceName: keychainName.serviceName,
    );

    return {
      // 'authData': authData,
      // 'authDataBackup': authDataBackup,
      // 'spFirebaseAuthData': spFirebaseAuthData,
      'authDataExists': authData != null,
      'authDataBackupExists': authDataBackup != null,
      'spFirebaseAuthDataExists': spFirebaseAuthData != null,
      'allKeychainData': allKeychainData,
    };
  }

  Future<({String serviceName, String authKey, String backupAuthKey})>
      _getKeychainName() async {
    const authKey = 'firebase_auth_1___FIRAPP_DEFAULT_firebase_user';
    const backupAuthKey = 'firebase_migrate_backup_auth_data';

    if (Firebase.apps.isNotEmpty) {
      final firebaseApp = Firebase.app();
      return (
        serviceName: 'firebase_auth_${firebaseApp.options.appId}',
        authKey: authKey,
        backupAuthKey: backupAuthKey,
      );
    } else {
      final appId = await _sharedPreferencesPlugin.getFirebaseAppId();
      // final appName = await _sharedPreferencesPlugin.getFirebaseAppName();

      if (appId == null) {
        throw Exception('appId is null');
      }

      return (
        serviceName: 'firebase_auth_$appId',
        // authKey: 'firebase_auth_1_${appName}_firebase_user',
        authKey: authKey,
        backupAuthKey: backupAuthKey,
      );
    }
  }

  // Future<bool> isEqualUnit8List(
  //   Uint8List list1,
  //   Uint8List list2,
  // ) async {
  //   if (identical(list1, list2)) {
  //     return true;
  //   }
  //   final length = list1.length;
  //   if (length != list2.length) {
  //     return false;
  //   }
  //   for (var i = 0; i < length; i++) {
  //     if (!(list1[i] == list2[i])) {
  //       return false;
  //     }
  //   }
  //   return true;
  // }
}

class _FirebaseAuthBackupAndMigrateSharedPreferences {
  _FirebaseAuthBackupAndMigrateSharedPreferences();

  static const _spBackupAuthKey = 'firebase_auth_migrate_auth_data';
  static const _firebaseAppNameSpKey =
      'firebase_auth_migrate_firebase_app_name';
  static const _firebaseAppIdSpKey = 'firebase_auth_migrate_firebase_app_id';

  Future<SharedPreferences> _getLatestSharedPreferences() async {
    final sp = await SharedPreferences.getInstance();
    await sp.reload();
    return sp;
  }

  Future<void> setFirebaseAppId(String appId) async {
    final sp = await _getLatestSharedPreferences();

    await sp.setString(
      _firebaseAppIdSpKey,
      appId,
    );
  }

  Future<String?> getFirebaseAppId() async {
    final sp = await _getLatestSharedPreferences();

    final appId = sp.getString(
      _firebaseAppIdSpKey,
    );

    return appId;
  }

  Future<void> deleteFirebaseAppId() async {
    final sp = await _getLatestSharedPreferences();
    await sp.remove(
      _firebaseAppIdSpKey,
    );
  }

  Future<void> setFirebaseAppName(String appName) async {
    final sp = await _getLatestSharedPreferences();

    await sp.setString(
      _firebaseAppNameSpKey,
      appName,
    );
  }

  Future<String?> getFirebaseAppName() async {
    final sp = await _getLatestSharedPreferences();

    final appName = sp.getString(
      _firebaseAppNameSpKey,
    );

    return appName;
  }

  Future<void> deleteFirebaseAppName() async {
    final sp = await _getLatestSharedPreferences();
    await sp.remove(
      _firebaseAppNameSpKey,
    );
  }

  Future<void> setFirebaseAuthData(
    Uint8List value,
  ) async {
    final sp = await _getLatestSharedPreferences();

    final string = String.fromCharCodes(value);

    await sp.setString(
      _spBackupAuthKey,
      string,
    );
  }

  Future<Uint8List?> getFirebaseAuthData() async {
    final sp = await _getLatestSharedPreferences();

    final spFirebaseAuthData = sp.getString(
      _spBackupAuthKey,
    );

    if (spFirebaseAuthData == null) {
      return null;
    }

    final authDataUnit8List = Uint8List.fromList(spFirebaseAuthData.codeUnits);
    return authDataUnit8List;
  }

  Future<void> deleteFirebaseAuthData() async {
    final sp = await _getLatestSharedPreferences();
    await sp.remove(_spBackupAuthKey);
  }
}

class _FirebaseAuthBackupAndMigrateKeychain {
  _FirebaseAuthBackupAndMigrateKeychain();

  static const _channel = MethodChannel('MigrateFirebaseAuth');

  Future<String?> getAllKeychainData({
    required String serviceName,
  }) async {
    final allData = await _channel.invokeMethod<String>(
      'getKeychainAll',
      <String, dynamic>{
        'serviceName': serviceName,
      },
    );

    return allData;
  }

  Future<Uint8List?> getKeychain({
    required String serviceName,
    required String keychainKey,
  }) async {
    try {
      final authData = await _channel.invokeMethod<Uint8List>(
        'getKeychain',
        <String, dynamic>{
          'serviceName': serviceName,
          'keychainKey': keychainKey,
        },
      );

      return authData;
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'FailedKeychainGet':
          return null;
        default:
          rethrow;
      }
    }
  }

  Future<void> setKeychain({
    required String serviceName,
    required String keychainKey,
    required Uint8List authData,
  }) async {
    await _channel.invokeMethod('setKeychain', <String, dynamic>{
      'serviceName': serviceName,
      'keychainKey': keychainKey,
      'authDataUnit8List': authData,
    });
  }

  Future<void> deleteKeychain({
    required String serviceName,
    required String keychainKey,
  }) async {
    await _channel.invokeMethod('deleteKeychain', <String, dynamic>{
      'serviceName': serviceName,
      'keychainKey': keychainKey,
    });
  }
}
