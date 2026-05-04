import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricHelper {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticate({required String reason}) async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        return true; // If device doesn't support biometrics, allow the action or handle otherwise
      }

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows PIN/Pattern if biometrics fail or aren't set
        ),
      );
    } on PlatformException catch (e) {
      print("Biometric Error: $e");
      return false;
    }
  }
}
