import 'package:flutter/material.dart';
import '../../utils/user_preferences.dart';
import '../scanner/scanner.dart';

class AreYouScreen extends StatelessWidget {
  const AreYouScreen({super.key});

  Future<void> _handleGenderSelection(
      BuildContext context, String gender) async {
    await UserPreferences.saveGender(gender);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Are You',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                _buildButton(context, 'MEN'),
                _buildButton(context, 'WOMEN'),
                _buildButton(context, 'COUPLES'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () => _handleGenderSelection(context, label),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
