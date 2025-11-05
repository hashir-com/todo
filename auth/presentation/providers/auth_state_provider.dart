import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_up_with_email.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/reset_password.dart';
import '../../../../core/usecases/usecase.dart';
import 'auth_provider.dart';

final obscurePasswordProvider = StateProvider<bool>((ref) => true);
// Auth state notifier
class AuthStateNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final SignInWithEmail signInWithEmailUseCase;
  final SignInWithGoogle signInWithGoogleUseCase;
  final SignUpWithEmail signUpWithEmailUseCase;
  final SignOut signOutUseCase;
  final ResetPassword resetPasswordUseCase;

  AuthStateNotifier({
    required this.signInWithEmailUseCase,
    required this.signInWithGoogleUseCase,
    required this.signUpWithEmailUseCase,
    required this.signOutUseCase,
    required this.resetPasswordUseCase,
  }) : super(const AsyncValue.loading());

  Future<String?> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    
    final result = await signInWithEmailUseCase(
      SignInWithEmailParams(email: email, password: password),
    );

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return failure.message;
      },
      (user) {
        state = AsyncValue.data(user);
        return null;
      },
    );
  }

  Future<String?> signInWithGoogle() async {
    state = const AsyncValue.loading();
    
    final result = await signInWithGoogleUseCase(NoParams());

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return failure.message;
      },
      (user) {
        state = AsyncValue.data(user);
        return null;
      },
    );
  }

  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    
    final result = await signUpWithEmailUseCase(
      SignUpWithEmailParams(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return failure.message;
      },
      (user) {
        state = AsyncValue.data(user);
        return null;
      },
    );
  }

  Future<String?> signOut() async {
    final result = await signOutUseCase(NoParams());

    return result.fold(
      (failure) => failure.message,
      (_) {
        state = const AsyncValue.data(null);
        return null;
      },
    );
  }

  Future<String?> resetPassword(String email) async {
    final result = await resetPasswordUseCase(ResetPasswordParams(email));

    return result.fold(
      (failure) => failure.message,
      (_) => null,
    );
  }
}

// Provider
final authStateNotifierProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<UserEntity?>>((ref) {
  return AuthStateNotifier(
    signInWithEmailUseCase: ref.watch(signInWithEmailUseCaseProvider),
    signInWithGoogleUseCase: ref.watch(signInWithGoogleUseCaseProvider),
    signUpWithEmailUseCase: ref.watch(signUpWithEmailUseCaseProvider),
    signOutUseCase: ref.watch(signOutUseCaseProvider),
    resetPasswordUseCase: ref.watch(resetPasswordUseCaseProvider),
  );
});