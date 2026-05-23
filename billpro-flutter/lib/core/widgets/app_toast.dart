import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ToastType { success, error, info, warning }

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: () => entry.remove(),
        duration: duration,
      ),
    );

    overlay.insert(entry);
  }

  /// Safe to use after async gaps — pass ScaffoldMessenger.of(context) before the await
  static void showOnMessenger(
    ScaffoldMessengerState messenger, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    messenger.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: switch (type) {
        ToastType.success => AppColors.success,
        ToastType.error => AppColors.error,
        ToastType.warning => AppColors.warning,
        ToastType.info => AppColors.primary,
      },
      behavior: SnackBarBehavior.floating,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}


class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;
  final Duration duration;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, iconData, iconColor) = switch (widget.type) {
      ToastType.success => (
          const Color(0xFFF0FDF4),
          Icons.check_circle_rounded,
          AppColors.success,
        ),
      ToastType.error => (
          const Color(0xFF334155),
          Icons.error_rounded,
          const Color(0xFFF8FAFC),
        ),
      ToastType.warning => (
          const Color(0xFFFFFBEB),
          Icons.warning_rounded,
          AppColors.warning,
        ),
      ToastType.info => (
          const Color(0xFFEFF6FF),
          Icons.info_rounded,
          AppColors.primary,
        ),
    };

    final borderColor = switch (widget.type) {
      ToastType.success => const Color(0xFFBBF7D0),
      ToastType.error => const Color(0xFF475569),
      ToastType.warning => const Color(0xFFFDE68A),
      ToastType.info => const Color(0xFFBFDBFE),
    };

    final textColor = switch (widget.type) {
      ToastType.success => const Color(0xFF166534),
      ToastType.error => const Color(0xFFF8FAFC),
      ToastType.warning => const Color(0xFF92400E),
      ToastType.info => const Color(0xFF1E40AF),
    };

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(iconData, color: iconColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        _controller.reverse().then((_) => widget.onDismiss()),
                    child: Icon(Icons.close_rounded, color: textColor, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
