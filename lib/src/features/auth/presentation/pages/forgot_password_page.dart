import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:wr_pmis_mobile/src/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:wr_pmis_mobile/src/features/auth/presentation/pages/login_page.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  static const String routeName = 'forgot-password';
  static const String routePath = '/forgot-password';

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) {
      return;
    }
    _seeded = true;
    final String email =
        ref.read(authControllerProvider).valueOrNull?.emailId.trim() ?? '';
    if (email.isNotEmpty) {
      _emailController.text = email;
      ref.read(forgotPasswordControllerProvider.notifier).seedEmail(email);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _showError(Failure failure) {
    return GlobalDialog.error(
      failure.message,
      title: failure.code ?? 'Request Failed',
    );
  }

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final Failure? failure = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendOtp(_emailController.text.trim());
    if (!mounted || failure == null) {
      return;
    }
    await _showError(failure);
  }

  Future<void> _verifyOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final Failure? failure = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .verifyOtp(_otpController.text.trim());
    if (!mounted || failure == null) {
      return;
    }
    await _showError(failure);
  }

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final Failure? failure = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .resetPassword(
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
    if (!mounted) {
      return;
    }
    if (failure != null) {
      await _showError(failure);
      return;
    }
    await GlobalDialog.success(
      'Your password has been reset successfully. Please login.',
      title: 'Password Reset',
    );
    if (!mounted) {
      return;
    }
    final bool loggedIn =
        ref.read(authControllerProvider).valueOrNull != null;
    if (loggedIn) {
      await ref.read(authControllerProvider.notifier).logout();
    }
    if (!mounted) {
      return;
    }
    context.goNamed(LoginPage.routeName);
  }

  Future<void> _resendOtp() async {
    final Failure? failure =
        await ref.read(forgotPasswordControllerProvider.notifier).resendOtp();
    if (!mounted) {
      return;
    }
    if (failure != null) {
      await _showError(failure);
      return;
    }
    await GlobalDialog.info(
      'A new verification code has been sent to your email.',
      title: 'OTP Sent',
    );
  }

  void _handleBack(ForgotPasswordState state) {
    if (state.step == ForgotPasswordStep.email) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(LoginPage.routeName);
      }
      return;
    }
    ref.read(forgotPasswordControllerProvider.notifier).goBack();
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Enter email address';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ForgotPasswordState flowState =
        ref.watch(forgotPasswordControllerProvider);
    final String title = switch (flowState.step) {
      ForgotPasswordStep.email => 'Forgot Password',
      ForgotPasswordStep.otp => 'Verify OTP',
      ForgotPasswordStep.reset => 'Reset Password',
    };
    final String subtitle = switch (flowState.step) {
      ForgotPasswordStep.email =>
        'Enter your registered email to receive a one-time password.',
      ForgotPasswordStep.otp =>
        'Enter the 6-digit code sent to ${flowState.email}.',
      ForgotPasswordStep.reset =>
        'Choose a new password for ${flowState.email}.',
    };

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _handleBack(flowState),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                switch (flowState.step) {
                  ForgotPasswordStep.email => _buildEmailStep(flowState),
                  ForgotPasswordStep.otp => _buildOtpStep(flowState),
                  ForgotPasswordStep.reset => _buildResetStep(flowState),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(ForgotPasswordState flowState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          validator: _validateEmail,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: flowState.isLoading || _emailController.text.trim().isEmpty
              ? null
              : _sendOtp,
          child: flowState.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Text('Send OTP'),
        ),
      ],
    );
  }

  Widget _buildOtpStep(ForgotPasswordState flowState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (_) => setState(() {}),
          validator: (String? value) {
            if ((value ?? '').trim().length != 6) {
              return 'Enter 6-digit OTP';
            }
            return null;
          },
          decoration: const InputDecoration(
            labelText: 'OTP',
            prefixIcon: Icon(Icons.pin_outlined),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: flowState.isLoading ? null : _resendOtp,
            child: const Text('Resend OTP'),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: flowState.isLoading || _otpController.text.trim().length != 6
              ? null
              : _verifyOtp,
          child: flowState.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Text('Verify OTP'),
        ),
      ],
    );
  }

  Widget _buildResetStep(ForgotPasswordState flowState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          validator: (String? value) {
            if ((value ?? '').length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'New password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscureNewPassword = !_obscureNewPassword),
              icon: Icon(
                _obscureNewPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          validator: (String? value) {
            if (value != _newPasswordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Confirm password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: flowState.isLoading ? null : _resetPassword,
          child: flowState.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Text('Reset Password'),
        ),
      ],
    );
  }
}
