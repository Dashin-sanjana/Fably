import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../home/home.dart';
import 'register.dart';
import 'auth_widget.dart';
// Import for AreYouScreen
import '../../utils/requests.dart';
import '../../utils/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON decoding, if needed
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = '';
  bool _isLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn();


  Future<String?> getPrefs(String pref) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? prefString = prefs.getString(pref);
    
    return prefString;
  }

  void _showMessage(String message) {
    print(message);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }


  Future<bool> loginCustomer(String email, String password) async {
    final requests = BackendRequests();
    final prefs = Prefs();
    // Step 1: Retrieve the CSRF token
    String csrfToken = await requests.getCsrf() ?? '';
    prefs.setPrefs('csrf_token', csrfToken);

    // Step 2: Prepare the login data as JSON

    // Step 3: Send a POST request to the login endpoint with the CSRF token in headers
    try{
    final loginResponse = await requests.postRequest(
      'login_customer',
      body:
        {
          'email': email,
          'password': password,
        }
    );

    // Step 4: Handle the login response
    if (loginResponse.statusCode == 200) {
      // Parse the returned user info
      final Map<String, dynamic> userInfo = jsonDecode(loginResponse.body);
      

      // Extract cookies from the response headers
      // Note: The cookie string might include additional attributes
      final String? cookies = loginResponse.headers['set-cookie'];
      print("Cookies: $cookies");

      // Step 5: Save the user info and cookies using SharedPreferences
      
      if (cookies != null) {
        await prefs.setPrefs('cookies', cookies);
      }

      await prefs.setPrefs('userInfo', jsonEncode(userInfo));

      _showMessage("Login successful. User info and cookies saved.");
      setState(() {
        _isLoading = true;
      });
      return true;
    } else {
      if(loginResponse.statusCode==401){
        _message = "Incorrect Email or Password";
      }
      print("Login failed with status code: ${loginResponse.statusCode}");
      print("Response: ${loginResponse.body}");
      setState(() {
        _isLoading = true;
      });
    }
    } catch(e){
        _message = '$e';
        print(e);
        setState(() {
          _isLoading = true;
        });
      return false;
    }
    setState(() {
      _isLoading = true;
    });
    return false;
  }

  void forgotPassword(String email) async {
    if (email==''){
      _showMessage("Please enter your email address");
      return;
    }
    final requests = BackendRequests();
    try{
      final response = await requests.postRequest(
        'forgot_password',
        body:
          {
            'email': email,
          }
      );

      if (response.statusCode == 200){
        _showMessage("Check your email for the reset passoword link");
      } else{
        _showMessage("Please enter your email in the field");
      }
    }
    catch (e) {
      _showMessage("Please enter your email in the field");
      _showMessage('$e');
    }
  }

  // Login method wrapper to handle void callback
  void _handleLogin() {
    if (!_isLoading) {
      _login().then((value) => null);
    }
  }

  // Updated login method
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

      bool loginSuccess = await loginCustomer(_emailController.text, _passwordController.text);
      setState(() {
        _isLoading = false;
      });
      if (!loginSuccess){
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

  }

  // Google sign-in method wrapper
  void _handleGoogleSignIn() {
    if (!_isLoading) {
      //_googleSignInMethod();
    }
  }

  // Updated Google sign-in method
  /*Future<void> _googleSignInMethod() async {
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
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      // Check if gender is selected
      bool hasGender = await UserPreferences.hasSelectedGender();
      if (!hasGender) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AreYouScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _message = 'Google Sign-In Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }*/

  // Forgot password method wrapper
  void _handleForgotPassword() {
    //_forgotPassword();
    forgotPassword(_emailController.text);
  }

  /*Future<void> _forgotPassword() async {
    try {
      //await _auth.sendPasswordResetEmail(email: _emailController.text);
      setState(() {
        _message = 'Password reset email sent.';
      });
    } catch (e) {
      setState(() {
        _message = 'Error: ${e.toString()}';
      });
    }
  }*/

  // Resend verification email method wrapper
  void _handleResendVerification() {
    //_resendVerificationEmail();
  }

  /*Future<void> _resendVerificationEmail() async {
    User? user = _auth.currentUser;

    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      setState(() {
        _message = 'Verification email sent again. Please check your inbox.';
      });
    }
  }*/

  

  @override
  void initState() {
    super.initState();
    final request = BackendRequests();
    final prefs = Prefs();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if(await request.isLoggedIn()){
        print('User is already logged in');
        print(prefs.getPrefs('userInfo'));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      return false;
    },
    child: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 50), // Reduced from 100 to make room for new title
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
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Column(
                    children: [
                      const Text(
                        'LOGIN',
                        style: TextStyle(
                          letterSpacing: 8,
                          fontFamily: 'jura',
                          fontSize: 53,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 60),
                      AuthTextField(
                        controller: _emailController, 
                        labelText: 'Email',
                      ),
                      AuthTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        obscureText: true,
                      ),
                      const SizedBox(height: 50),
                      AuthButton(
                        text: 'LOGIN',
                        onPressed: _isLoading ? () {} : _handleLogin,
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _handleForgotPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.white, fontSize: 13, height: 10)
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          "Don't have an account? Register",
                          style: TextStyle(color: Colors.white)
                        ),
                      ),
                      if (_message == 'Email not verified. Check your inbox.')
                        ElevatedButton(
                          onPressed: _handleResendVerification,
                          child: const Text('Resend Verification Email'),
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
    ),
  );
}}
