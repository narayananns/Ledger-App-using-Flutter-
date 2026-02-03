import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'brevo_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final BrevoService _brevoService = BrevoService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Email and Password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint("Error signing in with Email: $e");
      rethrow;
    }
  }

  // Register with Email, Password, and Name
  Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update Display Name
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);

        // Set a random avatar if none exists
        if (credential.user!.photoURL == null) {
          String randomAvatarUrl =
              "https://api.dicebear.com/9.x/avataaars/png?seed=${credential.user!.uid}";
          await credential.user!.updatePhotoURL(randomAvatarUrl);
        }

        await credential.user!.reload(); // Reload to apply changes locally
      }

      // Send Welcome Email via Brevo
      if (credential.user != null && credential.user!.email != null) {
        _brevoService.sendWelcomeEmail(credential.user!.email!, name);
      }

      return credential;
    } catch (e) {
      debugPrint("Error signing up with Email: $e");
      rethrow;
    }
  }

  // Update User Profile (Name & Photo)
  Future<void> updateProfile({String? name, String? photoURL}) async {
    User? user = _auth.currentUser;
    if (user != null) {
      if (name != null) await user.updateDisplayName(name);
      if (photoURL != null) await user.updatePhotoURL(photoURL);
      await user.reload();
      notifyListeners();
    }
  }

  // Reload User
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
    notifyListeners();
  }

  // Change Password
  Future<void> updatePassword(String newPassword) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  // Re-authenticate User (Required before changing sensitive info like password)
  Future<void> reauthenticate(String email, String password) async {
    User? user = _auth.currentUser;
    if (user != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Update Email
  Future<void> updateEmail(String newEmail) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.verifyBeforeUpdateEmail(newEmail);
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web Authentication
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(authProvider);
      } else {
        // Mobile (Android/iOS) Authentication
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          return null; // The user canceled the sign-in
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        // Check if it's a new user to send Welcome Email
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          try {
            if (userCredential.user?.email != null) {
              String name = userCredential.user?.displayName ?? "User";
              // Fire and forget - don't block login if email fails
              _brevoService.sendWelcomeEmail(userCredential.user!.email!, name);
            }
          } catch (e) {
            debugPrint("Warning: Failed to send welcome email: $e");
          }
        }

        return userCredential;
      }
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }
}
