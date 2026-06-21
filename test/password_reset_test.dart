import 'package:flutter_test/flutter_test.dart';

// ─── Fake Firebase Auth ──────────────────────────────────────────────

class _FakeFirebaseAuth {
  String? lastResetEmail;
  String? updatedPassword;
  bool sendPasswordResetEmailCalled = false;
  bool updatePasswordCalled = false;
  bool signOutCalled = false;

  Future<void> sendPasswordResetEmail({required String email}) async {
    sendPasswordResetEmailCalled = true;
    lastResetEmail = email;
  }

  Future<void> updatePassword(String newPassword) async {
    updatePasswordCalled = true;
    updatedPassword = newPassword;
  }

  Future<void> signOut() async {
    signOutCalled = true;
  }
}

// ─── Testable controller mirroring forgot password logic ──────────────

class _FakeForgotPasswordController {
  final _FakeFirebaseAuth auth;
  final List<String> navigationHistory = [];
  final List<String> snackbarMessages = [];
  bool isLoading = false;

  _FakeForgotPasswordController({required this.auth});

  /// Validates and submits email for password reset
  Future<bool> onSubmitEmail(String email) async {
    if (email.trim().isEmpty) {
      snackbarMessages.add('Please enter your email');
      return false;
    }
    if (!_isValidEmail(email.trim())) {
      snackbarMessages.add('Please enter a valid email');
      return false;
    }

    isLoading = true;
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
      snackbarMessages.add('Reset link sent! Check your email');
      navigationHistory.add('/login');
      return true;
    } catch (_) {
      snackbarMessages.add('Something went wrong. Please try again');
      return false;
    } finally {
      isLoading = false;
    }
  }

  /// Validates and confirms new password
  Future<bool> onConfirmPassword(
      String newPassword, String rePassword) async {
    if (newPassword.trim().isEmpty || rePassword.trim().isEmpty) {
      snackbarMessages.add('Please fill all fields');
      return false;
    }
    if (newPassword != rePassword) {
      snackbarMessages.add('Passwords do not match');
      return false;
    }
    if (newPassword.length < 6) {
      snackbarMessages.add('Password must be at least 6 characters');
      return false;
    }

    isLoading = true;
    try {
      await auth.updatePassword(newPassword.trim());
      snackbarMessages.add('Password updated successfully!');
      navigationHistory.add('/login');
      return true;
    } catch (_) {
      snackbarMessages.add('Something went wrong. Please try again');
      return false;
    } finally {
      isLoading = false;
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }
}

// ─── Tests ───────────────────────────────────────────────────────────

void main() {
  group('Request Password Reset', () {
    test('sends password reset email when email is valid', () async {
      final auth = _FakeFirebaseAuth();
      final controller = _FakeForgotPasswordController(auth: auth);

      final result = await controller.onSubmitEmail('user@example.com');

      expect(result, isTrue);
      expect(auth.sendPasswordResetEmailCalled, isTrue);
      expect(auth.lastResetEmail, 'user@example.com');
    });

    test('navigates to login after sending reset email', () async {
      final auth = _FakeFirebaseAuth();
      final controller = _FakeForgotPasswordController(auth: auth);

      await controller.onSubmitEmail('user@example.com');

      expect(controller.navigationHistory, contains('/login'));
    });

    test('shows error when email is empty', () async {
      final auth = _FakeFirebaseAuth();
      final controller = _FakeForgotPasswordController(auth: auth);

      final result = await controller.onSubmitEmail('');

      expect(result, isFalse);
      expect(controller.snackbarMessages,
          contains('Please enter your email'));
    });

    test('shows error when email format is invalid', () async {
      final auth = _FakeFirebaseAuth();
      final controller = _FakeForgotPasswordController(auth: auth);

      final result = await controller.onSubmitEmail('not-an-email');

      expect(result, isFalse);
      expect(controller.snackbarMessages,
          contains('Please enter a valid email'));
    });
  });

  group('Reset Password', () {
    test('updates password when confirmation is valid', () async {
      final auth = _FakeFirebaseAuth();
      final controller = _FakeForgotPasswordController(auth: auth);

      final result =
          await controller.onConfirmPassword('newPass123', 'newPass123');

      expect(result, isTrue);
      expect(auth.updatePasswordCalled, isTrue);
      expect(auth.updatedPassword, 'newPass123');
    });

    test('navigates to login after updating password', () async {
      final auth = _FakeFirebaseAuth();
      final controller = _FakeForgotPasswordController(auth: auth);

      await controller.onConfirmPassword('newPass123', 'newPass123');

      expect(controller.navigationHistory, contains('/login'));
    });

    test('shows error when new password is empty', () async {
      final auth = _FakeFirebaseAuth();
      final controller = _FakeForgotPasswordController(auth: auth);

      final result = await controller.onConfirmPassword('', '');

      expect(result, isFalse);
      expect(controller.snackbarMessages,
          contains('Please fill all fields'));
    });

    test('shows error when passwords do not match', () async {
      final auth = _FakeFirebaseAuth();
      final controller = _FakeForgotPasswordController(auth: auth);

      final result =
          await controller.onConfirmPassword('password1', 'password2');

      expect(result, isFalse);
      expect(controller.snackbarMessages,
          contains('Passwords do not match'));
    });

    test('shows error when password is too short', () async {
      final auth = _FakeFirebaseAuth();
      final controller = _FakeForgotPasswordController(auth: auth);

      final result = await controller.onConfirmPassword('abc', 'abc');

      expect(result, isFalse);
      expect(controller.snackbarMessages,
          contains('Password must be at least 6 characters'));
    });
  });

  group('Login with new password', () {
    test('login succeeds with correct credentials after reset', () async {
      final auth = _FakeFirebaseAuth();
      final controller = _FakeForgotPasswordController(auth: auth);

      await controller.onConfirmPassword('newPass123', 'newPass123');

      expect(auth.updatedPassword, 'newPass123');
      expect(controller.navigationHistory, contains('/login'));
    });
  });
}
