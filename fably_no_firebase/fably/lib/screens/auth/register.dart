import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import '../home/home.dart';
import 'login.dart';
import 'auth_widget.dart'; // Import for AreYouScreen
import '../../utils/requests.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _message = '';
  bool _isLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Register method
  Future<bool> registerCustomer(String firstName, String lastName, String email, String password) async {
    final requests = BackendRequests();

    final registerResponse = await requests.postRequest(
      'register_customer', 
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
      }
    );

    if (registerResponse.statusCode == 200) {
      print("Register successful.");
      return true;
    } else {
      print("Register failed with status code: ${registerResponse.statusCode}");
      print("Response: ${registerResponse.body}");
    }
    return false;
  }

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _message = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool registerSuccess = await registerCustomer(
        _firstNameController.text,
        _lastNameController.text,
        _emailController.text,
        _passwordController.text,
      );

      setState(() {
        _message = registerSuccess 
          ? 'Account created! Check your email for verification.' 
          : 'Registration failed.';
        _isLoading = false;
      });

      if (!registerSuccess) return;

      // Navigate to login screen upon successful registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      setState(() {
        _message = 'Registration Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _googleSignUpMethod() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _googleSignIn.signOut();
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          _message = 'Google Sign-In was canceled.';
          _isLoading = false;
        });
        return;
      }

      GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // TODO: Send Google sign-in token to backend for authentication.

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _message = 'Google Sign-In Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 50), // Reduced to make room for new title
            const Text(
              'FABLY',
              style: TextStyle(
                fontFamily: 'jura',
                fontSize: 50,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30), // Added spacing between titles
            Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    const Text(
                      'REGISTER',
                      style: TextStyle(
                        letterSpacing: 8,
                        fontFamily: 'Jura',
                        fontSize: 53,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // First Name Field
                    AuthTextField(
                      controller: _firstNameController, 
                      labelText: 'First Name',
                    ),

                    // Last Name Field
                    AuthTextField(
                      controller: _lastNameController, 
                      labelText: 'Last Name',
                    ),

                    // Email Field
                    AuthTextField(
                      controller: _emailController, 
                      labelText: 'Email',
                    ),

                    // Password Field
                    AuthTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      obscureText: true,
                    ),

                    // Confirm Password Field
                    AuthTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      obscureText: true,
                    ),

                    const SizedBox(height: 20),

                    // Register Button
                    AuthButton(text: 'REGISTER', onPressed: _register),

                    const SizedBox(height: 50),

                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen()
                          ),
                        );
                      },
                      child: const Text(
                        'Already have an account? Login',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      _message,
                      style: const TextStyle(
                        fontFamily: 'Jura',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    ),
  );
}}
