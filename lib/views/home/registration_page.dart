import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _register() async {
    try {
      // Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Get the newly created user's UID
      String userId = userCredential.user!.uid;

      // Save user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'userId': userId,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'projects': <String>[], // Default empty string array
      });

      // Navigate to home
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration Successful!')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific errors
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already in use.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Failed: $errorMessage')),
      );
    } catch (e) {
      // Handle other unexpected errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS-like light gray background
      appBar: AppBar(
        title: null,
        centerTitle: true,
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
            'Register',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        elevation: 0,
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
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
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
            ),
            const SizedBox(height: 16),
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
              onPressed: _register,
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
