import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

enum ButtonType { primary, gold, outlined, text }

class HunarmandButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final double? width;
  final IconData? icon;

  const HunarmandButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.width,
    this.icon,
  });

  @override
  State<HunarmandButton> createState() => _HunarmandButtonState();
}

class _HunarmandButtonState extends State<HunarmandButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBgColor(BuildContext context) {
    switch (widget.type) {
      case ButtonType.gold:
        return AppColors.gold;
      case ButtonType.primary:
        return Theme.of(context).colorScheme.primary;
      default:
        return Colors.transparent;
    }
  }

  Color get _textColor {
    switch (widget.type) {
      case ButtonType.outlined:
        return AppColors.primaryGreen;
      case ButtonType.text:
        return AppColors.primaryGreen;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _controller.reverse(),
        onTapUp: (_) => _controller.forward(),
        onTapCancel: () => _controller.forward(),
        child: SizedBox(
          width: widget.width ?? double.infinity,
          child: _buildButton(),
        ),
      ),
    );
  }

  Widget _buildButton() {
    final content = widget.isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: _textColor, size: 18),
                const SizedBox(width: 8),
              ],
              Text(widget.label, style: AppTypography.button.copyWith(color: _textColor)),
            ],
          );

    switch (widget.type) {
      case ButtonType.outlined:
        return OutlinedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          child: content,
        );
      case ButtonType.text:
        return TextButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          child: Text(widget.label, style: AppTypography.button.copyWith(color: _textColor)),
        );
      default:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _getBgColor(context),
            foregroundColor: _textColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: widget.isLoading ? null : widget.onPressed,
          child: content,
        );
    }
  }
}
