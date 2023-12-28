import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, FirebaseAuthException;
import 'package:firebase_core/firebase_core.dart';
import 'package:notes_app_yt/firebase_options.dart';
import 'dart:developer' as devtools show log;

import 'package:notes_app_yt/services/auth/auth_exceptions.dart';
import 'package:notes_app_yt/services/auth/auth_provider.dart';
import 'package:notes_app_yt/services/auth/auth_user.dart';

class FirebaseAuthProvider implements AuthProvider {
  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = currentUser;
      if (user != null) {
        return user;
      }
      throw UserNotLoggedInAuthException();
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        devtools.log("Email already taken");
        throw EmailAlreadyTakenAuthException();
      } else if (e.code == "weak-password") {
        devtools.log("Weak password");
        throw WeakPasswordAuthException();
      } else if (e.code == "invalid-email") {
        devtools.log("Invalid email");
        throw InvalidEmailAuthException();
      } else {
        devtools.log(e.code);
        throw GenericAuthException();
      }
    } catch (e) {
      devtools.log(e.toString());
      throw GenericAuthException();
    }
  }

  @override
  AuthUser? get currentUser {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? AuthUser.fromFirebase(user) : null;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = currentUser;
      if (user != null) {
        return user;
      } else {
        throw UserNotLoggedInAuthException();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == "invalid-credential") {
        devtools.log("Invalid credentials");
        throw InvalidCredentialsAuthException();
      } else {
        devtools.log(e.code);
        throw GenericAuthException();
      }
    } catch (e) {
      devtools.log(e.toString());
      throw GenericAuthException();
    }
  }

  @override
  Future<void> logOut() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseAuth.instance.signOut();
    } else {
      throw UserNotLoggedInAuthException();
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    } else {
      throw UserNotLoggedInAuthException();
    }
  }

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
