import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class CustomInputField extends StatefulWidget {
  final String label;
  final String placeholder;
  final String? iconPath;
  final IconData? materialIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool showPasswordStrength;
  final bool isLightTheme;
  final TextInputType? keyboardType;

  const CustomInputField({
    super.key,
    required this.label,
    required this.placeholder,
    this.iconPath,
    this.materialIcon,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.showPasswordStrength = false,
    this.isLightTheme = false,
    this.keyboardType,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  late bool _isPasswordVisible;

  @override
  void initState() {
    super.initState();
    _isPasswordVisible = !widget.isPassword;
  }

  String _getPasswordStrength(String password) {
    if (password.isEmpty) return '';
    if (password.length < 6) return 'Weak';
    if (password.length < 10) return 'Medium';
    return 'Strong';
  }

  Color _getPasswordStrengthColor(String password) {
    final strength = _getPasswordStrength(password);
    switch (strength) {
      case 'Strong':
        return AppColors.strongPassword;
      case 'Medium':
        return AppColors.mediumPassword;
      default:
        return AppColors.weakPassword;
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = widget.isLightTheme
        ? AppTextStyles.lightLabelText
        : AppTextStyles.labelText;
    final inputStyle = widget.isLightTheme
        ? AppTextStyles.lightInputText
        : AppTextStyles.inputText;
    final bgColor = widget.isLightTheme
        ? AppColors.lightInputBg
        : AppColors.inputBg;
    final borderColor = widget.isLightTheme
        ? AppColors.darkLabelText.withOpacity(0.2)
        : AppColors.inputBg;
    final iconColor = widget.isLightTheme
        ? AppColors.darkLabelText
        : AppColors.labelText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: labelStyle),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword && !_isPasswordVisible,
            style: inputStyle,
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: inputStyle.copyWith(
                color: iconColor.withOpacity(0.6),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: widget.iconPath != null
                  ? Padding(
                      padding: EdgeInsets.all(12),
                      child: widget.iconPath!.endsWith('.svg')
                          ? SvgPicture.asset(
                              widget.iconPath!,
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                iconColor,
                                BlendMode.srcIn,
                              ),
                            )
                          : Image.asset(
                              widget.iconPath!,
                              width: 20,
                              height: 20,
                              color: iconColor,
                            ),
                    )
                  : widget.materialIcon != null
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            widget.materialIcon!,
                            size: 20,
                            color: iconColor,
                          ),
                        )
                      : null,
              suffixIcon: widget.isPassword
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: iconColor,
                        ),
                      ),
                    )
                  : null,
            ),
            onChanged: widget.showPasswordStrength ? (_) => setState(() {}) : null,
          ),
        ),
        if (widget.showPasswordStrength && widget.controller != null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: _buildPasswordStrengthIndicator(),
          ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = widget.controller?.text ?? '';
    final strength = _getPasswordStrength(password);
    final color = _getPasswordStrengthColor(password);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 11,
                height: 2,
                color: password.isNotEmpty ? color : Colors.grey,
              ),
              SizedBox(width: 8),
              Container(
                width: 11,
                height: 2,
                color: password.length >= 6 ? color : Colors.grey,
              ),
              SizedBox(width: 8),
              Container(
                width: 11,
                height: 2,
                color: password.length >= 10 ? color : Colors.grey,
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        Text(strength, style: AppTextStyles.strengthText),
      ],
    );
  }
}
