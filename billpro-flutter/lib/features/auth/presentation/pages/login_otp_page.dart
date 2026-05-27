import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../providers/auth_provider.dart';

class LoginOtpPage extends StatefulWidget {
  const LoginOtpPage({super.key});

  @override
  State<LoginOtpPage> createState() => _LoginOtpPageState();
}

class _LoginOtpPageState extends State<LoginOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  // true = OTP step, false = email step
  bool _otpSent = false;
  String _sentEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ── Step 1: Send OTP ────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();

    final success = await auth.sendLoginOtp(email: email);
    if (!mounted) return;

    if (success) {
      AppToast.show(
        context,
        message: auth.message ?? 'OTP sent to your email',
        type: ToastType.success,
      );
      setState(() {
        _otpSent = true;
        _sentEmail = email;
      });
    } else {
      AppToast.show(
        context,
        message: auth.errorMessage ?? 'Failed to send OTP',
        type: ToastType.error,
      );
    }
  }

  // ── Step 2: Verify OTP ──────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    if (_otpController.text.length < 6) return;
    final auth = context.read<AuthProvider>();

    final success = await auth.verifyLoginOtp(
      email: _sentEmail,
      otp: _otpController.text,
    );
    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else {
      AppToast.show(
        context,
        message: auth.errorMessage ?? 'Invalid OTP. Please try again.',
        type: ToastType.error,
      );
    }
  }

  // ── Go back to email step ────────────────────────────────────────────────
  void _goBack() {
    setState(() {
      _otpSent = false;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: _otpSent ? _goBack : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, animation) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.12, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: _otpSent
                ? _OtpStep(
                    key: const ValueKey('otp'),
                    email: _sentEmail,
                    otpController: _otpController,
                    onVerify: _verifyOtp,
                    onResend: _sendOtp,
                  )
                : _EmailStep(
                    key: const ValueKey('email'),
                    formKey: _formKey,
                    emailController: _emailController,
                    onSend: _sendOtp,
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Email Step ──────────────────────────────────────────────────────────────

class _EmailStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final VoidCallback onSend;

  const _EmailStep({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Logo
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: Image.asset(
                  'assets/images/billcube_icon.jpeg',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Login with OTP',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your registered email to receive a one-time password.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 36),

          AppTextField(
            controller: emailController,
            label: 'Email Address',
            hint: 'you@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
          ),
          const SizedBox(height: 32),

          Consumer<AuthProvider>(
            builder: (context, auth, _) => AppButton(
              text: 'Send OTP',
              isLoading: auth.isLoading,
              onPressed: onSend,
              icon: Icons.send_rounded,
            ),
          ),
          const SizedBox(height: 28),

          Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: RichText(
                text: TextSpan(
                  text: 'Back to ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  children: [
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── OTP Step ────────────────────────────────────────────────────────────────

class _OtpStep extends StatelessWidget {
  final String email;
  final TextEditingController otpController;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  const _OtpStep({
    super.key,
    required this.email,
    required this.otpController,
    required this.onVerify,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 52,
      height: 58,
      textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // Envelope icon badge
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 36,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 32),

        Text(
          'Check your inbox',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            text: 'We sent a 6-digit code to\n',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
            children: [
              TextSpan(
                text: email,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // OTP input
        Center(
          child: Pinput(
            controller: otpController,
            length: 6,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration?.copyWith(
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
            ),
            submittedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration?.copyWith(
                color: AppColors.primarySoft,
                border: Border.all(color: AppColors.primary),
              ),
            ),
            onCompleted: (_) => onVerify(),
          ),
        ),
        const SizedBox(height: 36),

        Consumer<AuthProvider>(
          builder: (context, auth, _) => AppButton(
            text: 'Verify & Login',
            isLoading: auth.isLoading,
            onPressed: onVerify,
            icon: Icons.verified_outlined,
          ),
        ),
        const SizedBox(height: 24),

        Center(
          child: GestureDetector(
            onTap: onResend,
            child: RichText(
              text: TextSpan(
                text: "Didn't receive it? ",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                children: [
                  TextSpan(
                    text: 'Resend OTP',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
