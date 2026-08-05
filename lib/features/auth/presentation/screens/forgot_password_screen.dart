import 'package:flutter/material.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/usecases/forgot_password.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final ForgotPassword _forgotPassword = ForgotPassword(
    ServiceLocator.instance.authRepository,
  );

  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final AuthResult result = await _forgotPassword.call(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.isSuccess) {
      Navigator.of(context).pushReplacementNamed(
        RoutePaths.resetPassword,
        arguments: _emailController.text.trim(),
      );
    } else {
      _showMessage(result.message ?? 'Something went wrong. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  icon: Icons.help_outline,
                  title: 'Forgot password?',
                  subtitle:
                      'No worries. Enter your email and we will send you a '
                      'link to reset your password.',
                ),
                const SizedBox(height: 32),
                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: Validators.email,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: 'Send Reset Link',
                  loading: _submitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Remembered your password?',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Back to Sign In'),
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
