import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/*void main() {
  runApp(const MyApp());
}
*/
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Checkout Form',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CheckoutForm(),
    );
  }
}

class CheckoutForm extends StatefulWidget {
  const CheckoutForm({super.key});

  @override
  _CheckoutFormState createState() => _CheckoutFormState();
}

class _CheckoutFormState extends State<CheckoutForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  final String apiUrl = "http://10.0.2.2:5000/submit-checkout-form"; // Use 10.0.2.2 for Emulator

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> customerData = {
        "name": _nameController.text,
        "address": _addressController.text,
        "phone": _phoneController.text,
        "postalCode": _postalCodeController.text
      };

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(customerData),
        );

        if (!mounted) return;

        print("Response Code: ${response.statusCode}");
        print("Response Body: ${response.body}");

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Checkout successful!")),
          );
          _clearForm();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Failed: ${response.body}")),
          );
        }
      } catch (error) {
        print("❌ Network Error: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Network Error: ${error.toString()}")),
        );
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _addressController.clear();
    _phoneController.clear();
    _postalCodeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Customer Name'),
                validator: (value) => value!.isEmpty ? 'Enter your name' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value!.isEmpty ? 'Enter your address' : null,
              ),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (value) => value!.isEmpty ? 'Enter phone number' : null,
              ),
              TextFormField(
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Postal Code'),
                validator: (value) => value!.isEmpty ? 'Enter postal code' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
