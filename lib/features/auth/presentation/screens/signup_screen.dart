import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app_pro/features/auth/presentation/widgets/custom_text_feid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_state_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/social_login_button.dart';

class SignUpState {
  final bool isLoading;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final String? error;

  const SignUpState({
    this.isLoading = false,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.error,
  });

  SignUpState copyWith({
    bool? isLoading,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    String? error,
  }) {
    return SignUpState(
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
      error: error ?? this.error,
    );
  }
}

class SignUpNotifier extends StateNotifier<SignUpState> {
  SignUpNotifier() : super(const SignUpState());

  void toggleObscurePassword() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void toggleObscureConfirmPassword() {
    state =
        state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword);
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required AuthStateNotifier authNotifier,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final error = await authNotifier.signUpWithEmail(
      email: email.trim(),
      password: password,
      displayName: displayName.trim(),
    );
    state = state.copyWith(isLoading: false);

    if (error != null) {
      state = state.copyWith(error: error);
    }
  }

  Future<void> signInWithGoogle(AuthStateNotifier authNotifier) async {
    state = state.copyWith(isLoading: true, error: null);
    final error = await authNotifier.signInWithGoogle();
    state = state.copyWith(isLoading: false);

    if (error != null) {
      state = state.copyWith(error: error);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final signUpNotifierProvider =
    StateNotifierProvider.autoDispose<SignUpNotifier, SignUpState>(
  (ref) => SignUpNotifier(),
);

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Optional: Add listeners if syncing form values to state (not needed here for simplicity)
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpNotifierProvider);
    final notifier = ref.read(signUpNotifierProvider.notifier);
    final authNotifier = ref.read(authStateNotifierProvider.notifier);

    ref.listen(signUpNotifierProvider, (previous, next) {
      if (next.error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (next.isLoading == false &&
          previous?.isLoading == true &&
          next.error == null &&
          context.mounted) {
        // Success case: either email sign up or Google
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please verify your email.'),
            backgroundColor: AppColors.completed,
          ),
        );
        if (mounted) {
          Navigator.pop(context);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Title
                Text(
                  'Sign Up',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create an account to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),

                // Name Field
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) => Validators.name(value),
                  enabled: !state.isLoading,
                ),
                const SizedBox(height: 16),

                // Email Field
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  enabled: !state.isLoading,
                ),
                const SizedBox(height: 16),

                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: state.obscurePassword,
                  validator: Validators.password,
                  enabled: !state.isLoading,
                  suffixIcon: IconButton(
                    icon: Icon(
                      state.obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed:
                        state.isLoading ? null : notifier.toggleObscurePassword,
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: state.obscureConfirmPassword,
                  validator: _validateConfirmPassword,
                  enabled: !state.isLoading,
                  suffixIcon: IconButton(
                    icon: Icon(
                      state.obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: state.isLoading
                        ? null
                        : notifier.toggleObscureConfirmPassword,
                  ),
                ),
                const SizedBox(height: 32),

                // Sign Up Button
                CustomButton(
                  text: 'Sign Up',
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          await notifier.signUpWithEmail(
                            email: _emailController.text,
                            password: _passwordController.text,
                            displayName: _nameController.text,
                            authNotifier: authNotifier,
                          );
                        },
                  isLoading: state.isLoading,
                ),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 24),

                // Google Sign In
                SocialLoginButton(
                  icon: 'assets/images/google signin.svg',
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          await notifier.signInWithGoogle(authNotifier);
                        },
                ),
                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed:
                          state.isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
