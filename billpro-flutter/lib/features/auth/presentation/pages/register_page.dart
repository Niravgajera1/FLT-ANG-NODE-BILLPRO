import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();
      final success = await auth.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      
      if (!mounted) return;
      if (success) {
        AppToast.show(
          context,
          message: auth.message ?? 'OTP Sent',
          type: ToastType.success,
        );
        context.push('/otp', extra: {
          'identifier': auth.otpIdentifier,
          'purpose': auth.otpPurpose,
        });
      } else {
        AppToast.show(
          context,
          message: auth.errorMessage ?? 'Registration failed',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  Text(
                    'Create Account',
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Start managing your business with BillPro',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 32),

                  AppTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'John Doe',
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: Validators.fullName,
                  ),
                  const SizedBox(height: 18),

                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'you@example.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 18),

                  AppTextField(
                    controller: _mobileController,
                    label: 'Mobile Number',
                    hint: '9876543210',
                    prefixIcon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    maxLength: 10,
                    validator: Validators.mobile,
                  ),
                  const SizedBox(height: 18),

                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Min 8 chars, 1 uppercase, 1 number, 1 special',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 18),

                  AppTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: (v) => Validators.confirmPassword(
                        v, _passwordController.text),
                  ),
                  const SizedBox(height: 32),

                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return AppButton(
                        text: 'Create Account',
                        isLoading: auth.isLoading,
                        onPressed: _onRegister,
                        icon: Icons.person_add_alt_1_rounded,
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Text(
                            'Sign In',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
