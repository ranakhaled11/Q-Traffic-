import 'package:flutter/material.dart';
import 'welcome_screen.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();


    _dotAnimations = List.generate(3, (index) {
      double start = index * 0.2; // delay between dots
      double end = start + 0.5;

      return Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });


    Future.delayed(Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animatedDot(Animation<double> anim) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        return Transform.scale(
          scale: anim.value,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfffaf9fb),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Q-TRAFFIC",
              style: TextStyle(
                fontSize: 45,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Color(0xff12223b),
              ),
            ),
            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _animatedDot(_dotAnimations[0]),
                SizedBox(width: 8),
                _animatedDot(_dotAnimations[1]),
                SizedBox(width: 8),
                _animatedDot(_dotAnimations[2]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}