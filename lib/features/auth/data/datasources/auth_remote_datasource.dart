import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signUpWithEmail(
      String email, String password, String displayName);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<void> resetPassword(String email);
  Future<void> sendEmailVerification();
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
    required this.firestore,
  });

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw ServerException('Sign in failed');
      }

      return _userFromFirebase(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw ServerException(_handleAuthError(e));
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      // Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw ServerException('Google sign in cancelled');
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential =
          await firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw ServerException('Google sign in failed');
      }

      // Reload user to get fresh data
      await userCredential.user!.reload();
      final freshUser = firebaseAuth.currentUser;

      if (freshUser == null) {
        throw ServerException('Failed to get user data');
      }

      // Create user model directly without additional processing
      final user = UserModel(
        id: freshUser.uid,
        email: freshUser.email ?? googleUser.email,
        displayName: freshUser.displayName ?? googleUser.displayName ?? '',
        photoUrl: freshUser.photoURL ?? googleUser.photoUrl,
        createdAt: freshUser.metadata.creationTime ?? DateTime.now(),
      );

      // Save user to Firestore (non-blocking)
      _saveUserToFirestore(user).catchError((error) {
        print('Firestore save error: $error');
      });

      return user;
    } on FirebaseAuthException catch (e) {
      throw ServerException(_handleAuthError(e));
    } catch (e) {
      throw ServerException('Google sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw ServerException('Sign up failed');
      }

      // Update display name
      await credential.user!.updateDisplayName(displayName);
      await credential.user!.reload();

      final freshUser = firebaseAuth.currentUser;

      if (freshUser == null) {
        throw ServerException('Failed to get user data');
      }

      final user = UserModel(
        id: freshUser.uid,
        email: freshUser.email ?? email,
        displayName: freshUser.displayName ?? displayName,
        photoUrl: freshUser.photoURL,
        createdAt: freshUser.metadata.creationTime ?? DateTime.now(),
      );

      // Save to Firestore
      await _saveUserToFirestore(user);

      // Send verification email
      await credential.user!.sendEmailVerification();

      return user;
    } on FirebaseAuthException catch (e) {
      throw ServerException(_handleAuthError(e));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        firebaseAuth.signOut(),
        googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw ServerException('Sign out failed');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return null;

      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
      );
    } catch (e) {
      throw ServerException('Failed to get current user');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw ServerException(_handleAuthError(e));
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw ServerException('Failed to send verification email');
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;

      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
      );
    });
  }

  // Helper methods
  UserModel _userFromFirebase(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  Future<void> _saveUserToFirestore(UserModel user) async {
    try {
      await firestore.collection('users').doc(user.id).set({
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'createdAt': user.createdAt.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Log error but don't throw to prevent blocking the sign-in flow
      print('Error saving to Firestore: $e');
      rethrow;
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
