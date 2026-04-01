import 'package:flutter/material.dart';
import '../constants/app_text_styles.dart';

class AnimatedGradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final List<Color> gradientColors;

  const AnimatedGradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.gradientColors = const [
      Color.fromARGB(255, 0, 113, 72),
      Color.fromARGB(255, 0, 117, 164),
    ],
  });

  @override
  State<AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _scaleController;
  late Animation<double> _rippleAnimation;
  late Animation<double> _scaleAnimation;
  
  Offset? _tapPosition;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    // Ripple animation controller
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: Curves.easeOut,
      ),
    );

    // Scale animation controller (for press effect)
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _tapPosition = details.localPosition;
      _isPressed = true;
    });
    _scaleController.forward();
    _rippleController.forward(from: 0.0);
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });
      }
    });
  }

  void _handleTapCancel() {
    _scaleController.reverse();
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.onPressed != null && !widget.isLoading
                ? _handleTapDown
                : null,
            onTapUp: widget.onPressed != null && !widget.isLoading
                ? _handleTapUp
                : null,
            onTapCancel: _handleTapCancel,
            onTap: widget.onPressed != null && !widget.isLoading
                ? widget.onPressed
                : null,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.gradientColors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradientColors[0].withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Ripple effect
                    if (_isPressed && _tapPosition != null)
                      AnimatedBuilder(
                        animation: _rippleAnimation,
                        builder: (context, child) {
                          final size = MediaQuery.of(context).size.width * 2;
                          final animatedSize = size * _rippleAnimation.value;
                          
                          return Positioned(
                            left: _tapPosition!.dx - animatedSize / 2,
                            top: _tapPosition!.dy - animatedSize / 2,
                            child: Container(
                              width: animatedSize,
                              height: animatedSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(
                                  0.3 * (1 - _rippleAnimation.value),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    
                    // Button content
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: widget.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                widget.text,
                                style: AppTextStyles.buttonText,
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
