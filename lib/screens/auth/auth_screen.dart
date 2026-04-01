import 'package:flutter/material.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

/// Auth screen wrapper that toggles between Sign In and Sign Up.
/// Extracted from splash_screen.dart so it can be used independently
/// as a named route (/login) without going through SplashScreen.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;

  @override
  Widget build(BuildContext context) {
    return _isSignIn
        ? SignInScreen(
            onSwitchToSignUp: () {
              setState(() {
                _isSignIn = false;
              });
            },
          )
        : SignUpScreen(
            onSwitchToSignIn: () {
              setState(() {
                _isSignIn = true;
              });
            },
          );
  }
}
