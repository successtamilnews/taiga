import 'package:flutter/material.dart';
import 'app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final EdgeInsetsGeometry padding;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.backgroundColor = AppColors.primary,
    this.textColor = Colors.white,
    this.height = 48.0,
    this.borderRadius = 8.0,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding,
          elevation: 2,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: textColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}