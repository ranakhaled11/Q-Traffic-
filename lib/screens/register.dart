import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'signin_screen.dart';
import 'ambulance_map_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final codeController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool hideCode = true;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _scale;

  final String logoUrl = "assets/images/logo2.png";

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _scale = Tween<double>(
      begin: 0.95,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    codeController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty ||
        codeController.text.trim().isEmpty) {
      _showMsg("Please fill all fields");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showMsg("Passwords do not match");
      return;
    }

    if (codeController.text != '123456') {
      _showMsg("Invalid ambulance access code");
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      _showMsg("Account created successfully");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AmbulanceMapScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showMsg("Email already exists");
      } else if (e.code == 'weak-password') {
        _showMsg("Weak password");
      } else if (e.code == 'invalid-email') {
        _showMsg("Invalid email");
      } else {
        _showMsg(e.message ?? "Registration failed");
      }
    } catch (e) {
      _showMsg(e.toString());
    }
  }

  void _showMsg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xff0A1A3A),
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: ScaleTransition(
            scale: _scale,
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      logoUrl,
                      height: 90,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image, size: 80),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Sign up with your email and password to continue",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 35),

                  _input(
                    "Email Address",
                    icon: Icons.email_outlined,
                    controller: emailController,
                  ),

                  _passwordInput(
                    "Password",
                    controller: passwordController,
                    isHidden: hidePassword,
                    onToggle: () =>
                        setState(() => hidePassword = !hidePassword),
                  ),

                  _passwordInput(
                    "Confirm Password",
                    controller: confirmPasswordController,
                    isHidden: hideConfirmPassword,
                    onToggle: () => setState(
                          () => hideConfirmPassword = !hideConfirmPassword,
                    ),
                  ),

                  _passwordInput(
                    "Access Code",
                    controller: codeController,
                    isHidden: hideCode,
                    onToggle: () =>
                        setState(() => hideCode = !hideCode),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0A1A3A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignInScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign in",
                          style: TextStyle(
                            color: Color(0xff0A1A3A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
      String hint, {
        TextEditingController? controller,
        IconData? icon,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _passwordInput(
      String hint, {
        required TextEditingController controller,
        required bool isHidden,
        required VoidCallback onToggle,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        obscureText: isHidden,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              isHidden
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            onPressed: onToggle,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}