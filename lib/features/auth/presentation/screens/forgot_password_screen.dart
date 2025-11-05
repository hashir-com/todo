import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app_pro/features/auth/presentation/widgets/custom_text_feid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_state_provider.dart';
import '../widgets/custom_button.dart';

class ForgotPasswordState {
  final bool isLoading;
  final bool emailSent;
  final String email;
  final String? error;

  const ForgotPasswordState({
    this.isLoading = false,
    this.emailSent = false,
    this.email = '',
    this.error,
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    bool? emailSent,
    String? email,
    String? error,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      emailSent: emailSent ?? this.emailSent,
      email: email ?? this.email,
      error: error ?? this.error,
    );
  }
}

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordNotifier() : super(const ForgotPasswordState());

  Future<void> updateEmail(String email) async {
    state = state.copyWith(email: email);
  }

  Future<void> resetPassword(AuthStateNotifier authNotifier) async {
    state = state.copyWith(isLoading: true, error: null);
    final error = await authNotifier.resetPassword(state.email.trim());
    state = state.copyWith(isLoading: false);

    if (error == null) {
      state = state.copyWith(emailSent: true);
    } else {
      state = state.copyWith(error: error);
    }
  }

  void clear() {
    state = const ForgotPasswordState();
  }
}

final forgotPasswordNotifierProvider =
    StateNotifierProvider.autoDispose<ForgotPasswordNotifier, ForgotPasswordState>(
  (ref) => ForgotPasswordNotifier(),
);

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    ref.read(forgotPasswordNotifierProvider.notifier).updateEmail('');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordNotifierProvider);
    final notifier = ref.read(forgotPasswordNotifierProvider.notifier);
    final authNotifier = ref.read(authStateNotifierProvider.notifier);

    // Sync controller with state
    if (_emailController.text != state.email) {
      _emailController.text = state.email;
    }
    _emailController.addListener(() {
      notifier.updateEmail(_emailController.text);
    });

    ref.listen(forgotPasswordNotifierProvider, (previous, next) {
      if (next.error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (next.emailSent && previous?.emailSent != true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset link sent successfully!'),
            backgroundColor: AppColors.completed,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: state.emailSent
              ? _buildSuccessView(context, state, notifier)
              : _buildFormView(context, state),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context, ForgotPasswordState state) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Icon
          const Icon(
            Icons.lock_reset_rounded,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Reset Password',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

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
          const SizedBox(height: 32),

          // Reset Button
          CustomButton(
            text: 'Send Reset Link',
            onPressed: state.isLoading
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    final authNotifier = ref.read(authStateNotifierProvider.notifier);
                    await ref.read(forgotPasswordNotifierProvider.notifier).resetPassword(authNotifier);
                  },
            isLoading: state.isLoading,
          ),
          const SizedBox(height: 16),

          // Back to Login
          TextButton(
            onPressed: state.isLoading ? null : () => Navigator.pop(context),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, ForgotPasswordState state, ForgotPasswordNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        // Success Icon
        const Icon(
          Icons.mark_email_read_rounded,
          size: 100,
          color: AppColors.completed,
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          'Check Your Email',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Description
        Text(
          'We\'ve sent a password reset link to',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          state.email,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          'Please check your email and click on the link to reset your password.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        // Resend Button
        OutlinedButton(
          onPressed: () async {
            final authNotifier = ref.read(authStateNotifierProvider.notifier);
            await notifier.resetPassword(authNotifier);
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Resend Email'),
        ),
        const SizedBox(height: 16),

        // Back to Login
        CustomButton(
          text: 'Back to Login',
          onPressed: () {
            notifier.clear();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}