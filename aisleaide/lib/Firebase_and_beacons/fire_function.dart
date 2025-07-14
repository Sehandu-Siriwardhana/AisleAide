import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        await _auth.signInWithCredential(credential);

        if (_auth.currentUser != null) {
          return _auth.currentUser!.displayName;
        } else {
          // This should not happen in normal circumstances
          return null;
        }
      } else {
        // Google sign-in canceled by the user
        return null;
      }
    } on FirebaseAuthException catch (e) {
      // Firebase authentication error
      if (kDebugMode) {
        print('Firebase Auth Error: ${e.message}');
      }
      return null;
    } catch (e, stackTrace) {
      // Other unexpected errors
      if (kDebugMode) {
        print('Unexpected Error: $e\nStack Trace: $stackTrace');
      }
      return null;
    }
  }

  Future<void> signOutFromGoogle() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // First, sign out the user
        await _auth.signOut();

        // If the user signed in with Google, revoke access
        if (user.providerData
            .any((userInfo) => userInfo.providerId == 'google.com')) {
          await _googleSignIn.disconnect();
        }

        // Then, delete the user's account
        await user.delete();
      }
    } catch (error) {
      // Handle errors
      rethrow;
    }
  }
}
