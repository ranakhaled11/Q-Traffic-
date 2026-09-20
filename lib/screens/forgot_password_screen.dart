import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final codeController = TextEditingController();

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
      duration: const Duration(milliseconds: 650),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _scale = Tween<double>(
      begin: 0.96,
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
    codeController.dispose();
    super.dispose();
  }

  void _verifyUser() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();

    if (email.isEmpty || code.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    if (code != "123456") {
      _showError("Invalid access code");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Check your email",
          ),
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showError("Email not found");
      } else if (e.code == 'invalid-email') {
        _showError("Invalid email");
      } else {
        _showError(
          e.message ?? "Something went wrong",
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: ScaleTransition(
            scale: _scale,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      logoUrl,
                      height: 85,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    "Forgot Password",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Enter your email and access code",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 28),

                  _input(
                    "Email Address",
                    controller: emailController,
                    icon: Icons.email_outlined,
                  ),

                  _passwordInput(
                    "Access Code",
                    controller: codeController,
                    isHidden: hideCode,
                    onToggle: () =>
                        setState(() => hideCode = !hideCode),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _verifyUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xff0A1A3A),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
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
        required TextEditingController controller,
        required IconData icon,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: isHidden,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon:
          const Icon(Icons.vpn_key_outlined),
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
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}