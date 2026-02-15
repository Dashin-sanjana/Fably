import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final EdgeInsets? margin; // Add margin parameter

  const AuthTextField({super.key, 
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.margin = const EdgeInsets.only(bottom: 23), // Default bottom margin
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero, // Apply margin if provided
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300,
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: labelText,
            contentPadding: EdgeInsets.only(left: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(34),
              borderSide: BorderSide(width: 1),
            ),
          ),
        ),
      ),
    );
  }
}


class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AuthButton({super.key, 
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 34), // Set padding
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(34), // Set border radius
        ),
        elevation: 5, // Set shadow
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: "jura",
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 4,
        ),
        
        
        
        ),
    );
  }
}
