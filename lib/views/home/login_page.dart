import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      print('Login successful for user: ${_emailController.text}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found for this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Invalid password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        default:
          errorMessage = 'An unexpected error occurred. Please try again.';
      }

      print('Login failed: $errorMessage');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      print('Unexpected error: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS-like light gray background
      appBar: AppBar(
        title: null, // Remove the default title
        centerTitle: true, // Center the content
        flexibleSpace: Container(
          margin: const EdgeInsets.only(top: 20.0), // Push the box down
          alignment: Alignment.center,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0), // Rounded corners
            border: Border.all(color: Colors.white, width: 2.0), // White border
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF6FBEDC)], // Dark to light blue
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Text(
            'Login',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        elevation: 0, // No shadow
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo at the top
            Image.asset(
              'assets/logo.png', // Ensure this path matches your asset location
              height: 120,
              width: 120,
            ),
            const SizedBox(height: 20), // Spacing below the logo
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                filled: true,
                fillColor: const Color(0xFFF8F8F8), // Slightly off-white background
                labelStyle: const TextStyle(color: Color(0xFF5A8BB0)), // Light blue text
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFDADCE0)), // Gray border
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF6FBEDC)), // Soft blue border
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                filled: true,
                fillColor: const Color(0xFFF8F8F8), // Slightly off-white background
                labelStyle: const TextStyle(color: Color(0xFF5A8BB0)), // Light blue text
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFDADCE0)), // Gray border
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF6FBEDC)), // Soft blue border
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6FBEDC), // Soft blue button color
                foregroundColor: Colors.white, // White text color
              ),
              onPressed: _login,
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text(
                'Register',
                style: TextStyle(color: Color(0xFF5A8BB0)), // Light blue text
              ),
            ),
          ],
        ),
      ),
    );
  }
}
