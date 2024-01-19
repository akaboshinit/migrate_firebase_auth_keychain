import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:migrate_firebase_auth_keychain/migrate_firebase_auth_keychain.dart';
import 'package:migrate_firebase_auth_keychain_example/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final migrateFirebaseAuth = MigrateFirebaseAuth();
  await migrateFirebaseAuth.migrateFirebaseAuthData(
    onRestoreCompleted: (authData) {
      print('onRestoreAuthData:${authData.lengthInBytes}');
    },
    onRestoreFailed: (error) {
      print('onRestoreFailed:$error');
    },
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await migrateFirebaseAuth.backupFirebaseAuthData(
    onBackupCompleted: (authData) {
      print('onCompletedBackup:${authData.lengthInBytes}');
    },
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final migrateFirebaseAuth = MigrateFirebaseAuth();

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text('User is signed in! ${snapshot.data!.uid}');
                } else {
                  return const Text('User is not signed in!');
                }
              },
            ),
            TextButton(
                onPressed: () {
                  FirebaseAuth.instance.signInAnonymously();
                },
                child: const Text('Sign In Anonymously')),
            TextButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                },
                child: const Text('Sign Out')),
            TextButton(
                onPressed: () async {
                  FirebaseAuth.instance.currentUser!.reload();
                },
                child: const Text('Reload User')),
            TextButton(
                onPressed: () async {
                  final firebaseAuthData =
                      await migrateFirebaseAuth.checkFirebaseAuthDataExists();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(firebaseAuthData.entries
                            .map((e) => '${e.key}:${e.value}')
                            .join('\n')),
                      ),
                    );
                    print(firebaseAuthData);
                  }
                },
                child: const Text('Check FirebaseAuthData')),
            TextButton(
                onPressed: () async {
                  await migrateFirebaseAuth.deleteKeychainFirebaseAuthData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delete Keychain FirebaseAuthData'),
                      ),
                    );
                  }
                },
                child: const Text('Delete Keychain FirebaseAuthData')),
            TextButton(
                onPressed: () async {
                  await migrateFirebaseAuth.deleteBackupAuthData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delete Backup FirebaseAuthData'),
                      ),
                    );
                  }
                },
                child: const Text('Delete Backup FirebaseAuthData')),
          ],
        ),
      ),
    );
  }
}
