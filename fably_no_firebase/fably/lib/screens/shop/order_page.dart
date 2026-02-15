// importing all material from package below.
import 'package:flutter/material.dart';

/*
import 'package:provider/provider.dart';
import 'package:badges/badges.dart';
*/

// importing from other classes.
import '';

/*
// importing security packages.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
*/

// running the app.
void main() { runApp(const OrderApp()); }

// class with widgets and states.
class OrderApp extends StatelessWidget {
  const OrderApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // debugger for Showing Checked Mode Banner.
      debugShowCheckedModeBanner: false,
      title: 'Flutter order Page',
      // The theme of the application.
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const OrderPage(),
    );
  }
}

class OrderPage extends StatelessWidget {
  const OrderPage({Key? key}) : super(key: key);

  // This widget is the root of your widget.
  @override
  Widget build(BuildContext context) {
    // data for the order.
    final String orderId = "ORD123456";
    final String orderDate = "2025-02-23";
    final List<Map<String, dynamic>> clothingItems = [
      {
        "name": "T-Shirt",
        "price": 20.0,
        "quantity": 2,
        "image": "https://picsum.photos/200/300"
      },
      {
        "name": "Jeans",
        "price": 40.0,
        "quantity": 1,
        "image": "https://picsum.photos/200/300"
      },
      {
        "name": "Jacket",
        "price": 60.0,
        "quantity": 1,
        "image": "https://picsum.photos/200/300"
      },
    ];

    // calculate total cost.
    final double totalCost = clothingItems.fold(
      0.0, (sum, item) => sum + (item["price"] * item["quantity"]),
    );

    return Scaffold(
      appBar: AppBar(
        // background color to AppBar.
        backgroundColor: Colors.black,
        // widget title.
        centerTitle: true,
        title: const Text(
          'All Order Details',
          style: TextStyle(
              letterSpacing: 1.5,
              color: Colors.white,
              fontWeight: FontWeight.normal
          ),
        ),
      ),
      body: Padding(
        // padding around the grid.
        padding: const EdgeInsets.all(16.0),
        // vertically arranges the buttons.
        child: Column(
          // spacing and alignments between item buttons.
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,

          children: [
            Text(
              "Order ID: $orderId",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 1),
            Text(
              "Date: $orderDate",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Divider(height: 24, thickness: 2),
            const Text(
              "Clothing Items:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            // expanded listview for the order list.
            const SizedBox(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: clothingItems.length,
                itemBuilder: (context, index) {
                  final item = clothingItems[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            item["image"],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${item['name']}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "\$${(item['price'] * item['quantity']).toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "\$${item['price'].toStringAsFixed(2)} each",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Quantity: ${item['quantity']}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // creating divider for items.
            const Divider(height: 20, thickness: 2,),
            // row for total cost.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Cost:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "\$${totalCost.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
