import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../domain/entities/auth_result.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();

  bool _submitting = false;
  bool _resending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _emailController.text.isEmpty) {
      _emailController.text = args;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final AuthResult result = await ref.read(verifyOtpProvider).call(
      email: _emailController.text.trim(),
      otp: _otpController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.isSuccess) {
      _showMessage('Email verified. Please sign in.');
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(RoutePaths.login, (route) => false);
    } else {
      _showMessage(result.message ?? 'Invalid code. Please try again.');
    }
  }

  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);

    final AuthResult result = await ref
        .read(resendOtpProvider)
        .call(email: _emailController.text.trim());

    if (!mounted) return;
    setState(() => _resending = false);

    _showMessage(
      result.isSuccess
          ? 'A new verification code has been sent.'
          : result.message ?? 'Unable to resend the code. Please try again.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthHeader(
                  icon: Icons.mark_email_read_outlined,
                  title: 'Verify your email',
                  subtitle:
                      'Enter the 6-digit code we sent to your inbox to '
                      'activate your account.',
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  prefixIcon: Icons.mail_outline,
                  enabled: false,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _otpController,
                  label: 'Verification code',
                  hint: '123456',
                  prefixIcon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    final code = value?.trim() ?? '';
                    if (code.length != 6) return 'Enter the 6-digit code';
                    return null;
                  },
                  onFieldSubmitted: (_) => _verify(),
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: 'Verify Email',
                  loading: _submitting,
                  onPressed: _verify,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _resending ? null : _resend,
                    child: Text(_resending ? 'Sending…' : 'Resend code'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    "Didn't get an email? Check your spam folder.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
