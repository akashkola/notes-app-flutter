import 'package:test/test.dart';

import 'package:notes_app_yt/services/auth/auth_exceptions.dart';
import 'package:notes_app_yt/services/auth/auth_provider.dart';
import 'package:notes_app_yt/services/auth/auth_user.dart';

void main() {
  group('Mock Authentication', () {
    final provider = MockAuthProvider();

    test('should not be initialized to begin with', () {
      expect(provider.isInitialized, false);
    });

    test('cannot logout if not initialized', () {
      expect(
        provider.logOut(),
        throwsA(const TypeMatcher<NotInitializedAuthException>()),
      );
    });

    test('should be able to initialize', () async {
      await provider.initialize();
      expect(provider.isInitialized, true);
    });

    test('user should be null after initialization', () {
      expect(provider.currentUser, null);
    });

    test(
      'should be able to initialize in less than 3 seconds',
      () async {
        await provider.initialize();
        expect(provider.isInitialized, true);
      },
      timeout: const Timeout(Duration(seconds: 3)),
    );

    test('creating user should delegate to logIn function', () async {
      final badEmailUser = provider.createUser(
        email: 'foobar@gmail.com',
        password: 'test@123',
      );
      expect(
        badEmailUser,
        throwsA(const TypeMatcher<InvalidCredentialsAuthException>()),
      );

      final badPasswordUser = provider.createUser(
        email: 'test@gmail.com',
        password: 'foobar',
      );
      expect(
        badPasswordUser,
        throwsA(const TypeMatcher<InvalidCredentialsAuthException>()),
      );

      final user = await provider.createUser(
        email: 'foo',
        password: 'bar',
      );
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
    });

    test('logged in user should be able to verify their email', () async {
      await provider.sendEmailVerification();
      expect(provider.currentUser, isNotNull);
      expect(provider.currentUser!.isEmailVerified, true);
    });

    test('should be able logout and login again', () async {
      await provider.logOut();
      expect(provider.currentUser, isNull);
      await provider.logIn(
        email: 'foo',
        password: 'bar',
      );
      expect(provider.currentUser, isNotNull);
    });
  });
}

class NotInitializedAuthException implements Exception {}

class MockAuthProvider implements AuthProvider {
  var _isInitialized = false;
  AuthUser? _user;

  bool get isInitialized => _isInitialized;

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!isInitialized) throw NotInitializedAuthException();
    await Future.delayed(const Duration(seconds: 2));
    return logIn(
      email: email,
      password: password,
    );
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 2));
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    if (!isInitialized) throw NotInitializedAuthException();
    if (email == 'foobar@gmail.com') throw InvalidCredentialsAuthException();
    if (password == 'foobar') throw InvalidCredentialsAuthException();
    const user = AuthUser(
      id: "random_id",
      email: 'test@bar.com',
      isEmailVerified: false,
    );
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> logOut() async {
    if (!isInitialized) throw NotInitializedAuthException();
    if (_user == null) throw UserNotLoggedInAuthException();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw NotInitializedAuthException();
    final user = _user;
    if (user == null) throw UserNotLoggedInAuthException();
    const newUser = AuthUser(
      id: "random_id",
      email: "test@bar.com",
      isEmailVerified: true,
    );
    _user = newUser;
  }
}
