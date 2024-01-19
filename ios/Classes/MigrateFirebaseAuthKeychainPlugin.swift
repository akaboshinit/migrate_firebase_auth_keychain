import Flutter
import UIKit
import KeychainAccess

public class MigrateFirebaseAuthKeychainPlugin: NSObject, FlutterPlugin {
  private var channelResult: FlutterResult!

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "MigrateFirebaseAuth", binaryMessenger: registrar.messenger())
    let instance = MigrateFirebaseAuthKeychainPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

   public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      self.channelResult = result;

      switch call.method {
      case "getKeychain":
         getKeychain(call: call)

      case "getKeychainAll":
         getKeychainAll(call: call)

      case "setKeychain":
         setKeychain(call: call)

      case "deleteKeychain":
         deleteKeychain(call: call)

      default:
         self.channelResult!(FlutterMethodNotImplemented)
      }
   }

    private func getKeychainAll(call: FlutterMethodCall) {
      guard let arguments = call.arguments as? NSDictionary,
            let serviceName = arguments["serviceName"] as? String
      else {
         self.channelResult!(FlutterError(code: "InvalidArguments", message: "Invalid arguments", details: nil))
         return
      }


      let keychain = Keychain(service: serviceName)
      if let data = try? keychain.allItems() {
         self.channelResult!("\(data)")
      } else {
         self.channelResult!(FlutterError(code: "FailedKeychainGetAll", message: "Failed to retrieve data from keychain", details: nil))
      }
   }

   private func getKeychain(call: FlutterMethodCall) {
      guard let arguments = call.arguments as? NSDictionary,
            let serviceName = arguments["serviceName"] as? String,
            let keychainKey = arguments["keychainKey"] as? String
      else {
         self.channelResult!(FlutterError(code: "InvalidArguments", message: "Invalid arguments", details: nil))
         return
      }

      let keychain = Keychain(service: serviceName)
      if let data = try? keychain.getData(keychainKey) {
         self.channelResult!(FlutterStandardTypedData(bytes: data))
      } else {
         self.channelResult!(FlutterError(code: "FailedKeychainGet", message: "Failed to retrieve data from keychain", details: nil))
      }
   }

   private func setKeychain(call: FlutterMethodCall) {
      guard let arguments = call.arguments as? NSDictionary,
            let serviceName = arguments["serviceName"] as? String,
            let keychainKey = arguments["keychainKey"] as? String,
            let authDataUnit8List = arguments["authDataUnit8List"] as? FlutterStandardTypedData
      else {
         self.channelResult!(FlutterError(code: "InvalidArguments", message: "Invalid arguments", details: nil))
         return
      }

      do {
         let keychain = Keychain(service: serviceName)
         try keychain.set(authDataUnit8List.data, key: keychainKey)
         self.channelResult!("\(authDataUnit8List.data)")
      } catch {
         self.channelResult!(FlutterError(code: "FailedKeychainSet", message: "Failed to set data in keychain: \(error)", details: nil))
      }
   }

   private func deleteKeychain(call: FlutterMethodCall) {
      guard let arguments = call.arguments as? NSDictionary,
            let serviceName = arguments["serviceName"] as? String,
            let keychainKey = arguments["keychainKey"] as? String
      else {
         self.channelResult!(FlutterError(code: "InvalidArguments", message: "Invalid arguments", details: nil))
         return
      }

      do {
         let keychain = Keychain(service: serviceName)
         try keychain.remove(keychainKey)
         self.channelResult!("Success")
      } catch {
         self.channelResult!(FlutterError(code: "FailedKeychainDelete", message: "Failed to delete data from keychain: \(error)", details: nil))
      }
   }
}
