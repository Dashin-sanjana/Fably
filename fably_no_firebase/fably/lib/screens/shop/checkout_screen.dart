import 'package:flutter/material.dart';

import '../home/home.dart';
import '../../utils/requests.dart';


class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expirationController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  String selectedPaymentMethod = "Card";

  bool processingCheckout = false;

  void _showMessage(String message) {
    print(message);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> submitOrder() async {
    if (processingCheckout){
      return;
    }
    setState(() {
      processingCheckout = true;
    });
    _showMessage("Processing...");

      final requests = BackendRequests();
      try{
        final response = await requests.postRequest(
          'checkout', 
          body:{
            "email": emailController.text,
            "name": nameController.text,
            "address": addressController.text,
            "phone": phoneController.text,
            "postalCode": postalCodeController.text,
            "card_number": cardNumberController.text,
            "expiration": expirationController.text,
            "cvv": cvvController.text,
            "payment_method": selectedPaymentMethod,
          }
        );
        if (response.statusCode == 201){
          _showMessage("Order placed successfully!");

          setState(() {
            processingCheckout = false;
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ),
          );

        }else{
          _showMessage("Failed to place order.");
        }

        
        
      
      } catch (e){
        _showMessage("Error: $e");
      }

      setState(() {
        processingCheckout = false;
      });
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Checkout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Card(
                color: Colors.black.withOpacity(0.6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 5,
                child: Stepper(
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_currentStep < 2) {
                      setState(() {
                        _currentStep += 1;
                      });
                    } else {
                      submitOrder();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() {
                        _currentStep -= 1;
                      });
                    } else {
                      Navigator.of(context).pop(); // Navigate back if on first step
                    }
                  },
                  steps: [
                    Step(
                      title: _stepTitle("Payment Method"),
                      content: _paymentMethodSelector(),
                    ),
                    Step(
                      title: _stepTitle("Card Details"),
                      content: Column(
                        children: [
                          _buildTextField(cardNumberController, "Card Number", r'^[0-9]{16}\$', "Enter a valid 16-digit card number"),
                          _buildTextField(expirationController, "Expiration (MM/YY)", r'^(0[1-9]|1[0-2])/[0-9]{2}\$', "Enter a valid expiration date (MM/YY)"),
                          _buildTextField(cvvController, "CVV", r'^[0-9]{3,4}\$', "Enter a valid CVV (3 or 4 digits)"),
                        ],
                      ),
                    ),
                    Step(
                      title: _stepTitle("Review & Confirm"),
                      content: Column(
                        children: [
                          _buildTextField(nameController, "Full Name"),
                          _buildTextField(emailController, "E-mail", r'^[^@\s]+@[^@\s]+\.[^@\s]+\$', "Enter a valid email address"),
                          _buildTextField(addressController, "Address"),
                          _buildTextField(phoneController, "Phone Number", r'^\+?[0-9]{10,15}\$', "Enter a valid phone number"),
                          _buildTextField(postalCodeController, "Postal Code", r'^[0-9]{4,10}$', "Enter a valid postal code",),
                          SizedBox(height: 20),
                          _submitButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepTitle(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _paymentMethodSelector() {
    return Column(
      children: [
        _customRadioTile("Card", Icons.credit_card, Colors.blue),
        _customRadioTile("PayPal", Icons.paypal, Colors.yellow),
        _customRadioTile("Apple Pay", Icons.apple, Colors.white),
      ],
    );
  }

  Widget _customRadioTile(String title, IconData icon, Color color) {
    return ListTile(
      title: Text(title, style: TextStyle(color: Colors.white, fontSize: 16)),
      leading: Icon(icon, color: color),
      trailing: Radio(
        value: title,
        groupValue: selectedPaymentMethod,
        onChanged: (value) {
          setState(() {
            selectedPaymentMethod = value.toString();
          });
        },
        activeColor: color,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, [String? pattern, String? errorMessage]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        validator: (value) {
          if (value!.isEmpty) return "Enter your $label";
          if (pattern != null && !RegExp(pattern).hasMatch(value)) return errorMessage;
          return null;
        },
      ),
    );
  }

  Widget _submitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: submitOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text("Submit Order", style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}
