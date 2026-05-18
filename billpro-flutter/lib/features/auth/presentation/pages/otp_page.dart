import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OtpPage extends StatefulWidget {
  final String identifier;
  final String purpose;

  const OtpPage({
    super.key,
    required this.identifier,
    required this.purpose,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _onVerify() async {
    if (_otpController.text.length == 6) {
      final auth = context.read<AuthProvider>();
      final success = await auth.verifyOtp(
        identifier: widget.identifier,
        otp: _otpController.text,
        purpose: widget.purpose,
      );
      
      if (!mounted) return;
      if (success) {
        AppToast.show(
          context,
          message: auth.message ?? 'Verification successful',
          type: ToastType.success,
        );
        if (widget.purpose == 'password_reset') {
          context.push('/reset-password', extra: {'token': auth.resetToken});
        } else {
          context.go('/login');
        }
      } else {
        AppToast.show(
          context,
          message: auth.errorMessage ?? 'Verification failed',
          type: ToastType.error,
        );
      }
    }
  }

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Icon
                Container(
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
                const SizedBox(height: 28),

                Text(
                  'Verify Your Email',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'We sent a 6-digit code to',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.identifier,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 40),

                Pinput(
                  controller: _otpController,
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration?.copyWith(
                      border:
                          Border.all(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  submittedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration?.copyWith(
                      color: AppColors.primarySoft,
                      border: Border.all(color: AppColors.primary),
                    ),
                  ),
                  onCompleted: (_) => _onVerify(),
                ),
                const SizedBox(height: 36),

                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return AppButton(
                      text: 'Verify OTP',
                      isLoading: auth.isLoading,
                      onPressed: _onVerify,
                      icon: Icons.verified_outlined,
                    );
                  },
                ),
                const SizedBox(height: 24),

                Text(
                  'Didn\'t receive the code? Check your spam folder\nor contact support.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
