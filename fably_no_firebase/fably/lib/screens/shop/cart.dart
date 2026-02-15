import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:convert'; // For JSON decoding, if needed
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'checkout_screen.dart';
import '../auth/login.dart';
import '../shop/product.dart';
import '../../utils/requests.dart';
import '../../utils/prefs.dart';

/*void main() {
  runApp(MyApp());
}*/

ElevatedButton backButton = ElevatedButton(
    style: ElevatedButton.styleFrom(
      foregroundColor: Color.fromARGB(255, 255, 255, 255),
      backgroundColor: Color.fromARGB(255, 0, 0, 0),
    ),
    child: Row(
      children: const [
        SizedBox(width: 4), // Padding to align properly
        Icon(Icons.arrow_back),
        /*SizedBox(width: 4), // Space between icon and text
        Text('Back', style: TextStyle(fontSize: 16)),*/
      ],
    ), // Back button icon
    
    onPressed: () {
      // Define the back button's action
      // Navigates back to the previous screen
    },
  );

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cart Page with Slidable',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CartPage(),
    );
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {

  // Mock data for the cart items
  List<Map<String, dynamic>> cartItems = [
    {'name': 'Item 1', 'price': 10.0, 'quantity': 1, 'photos':['https://placehold.co/600x400/000000/FFFFFF/png']},
    {'name': 'Item 2', 'price': 15.0, 'quantity': 2, 'photos':['https://placehold.co/600x400/000000/FFFFFF/png']},
    {'name': 'Item 3', 'price': 20.0, 'quantity': 1, 'photos':['https://placehold.co/600x400/000000/FFFFFF/png']},
    {'name': 'Item 4', 'price': 20.0, 'quantity': 1, 'photos':['https://placehold.co/600x400/000000/FFFFFF/png']},
    {'name': 'Item 5', 'price': 20.0, 'quantity': 1, 'photos':['https://placehold.co/600x400/000000/FFFFFF/png']},
  ];

  

  String content = '';
  bool isLoading = true;

  //List<Map<String, dynamic>> jsonObject = jsonDecode(fetchWebContent());

  Future<String?> getPrefs(pref) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? value = prefs.getString(pref);
    return value;
  }

  void _showMessage(String message) {
    print(message);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> fetchCartContent() async{
    //_showMessage("Fetching cart Items...");
    final requests = BackendRequests();
    final prefs = Prefs();
    String cookies = '';
    Map userInfo = {};
    cookies = await prefs.getPrefs('cookies') ?? '';
    String? info = await prefs.getPrefs('userInfo');
    userInfo = jsonDecode(info ?? '{}');
    /*
    _showMessage("test after cookies and userInfo");
    _showMessage("Cookies: $cookies");
    _showMessage("userInfo: $userInfo");
    _showMessage("test after the 2 prints");*/
    //final url = Uri.parse('http://152.53.119.239:5000/products');
    //final url = Uri.parse('127.0.0.1:5000/get_cart/${userInfo['_id']}');

    try {
      /*
      final response = await http.get(
        url,
        headers: {
          'Cookie': cookies, // Add cookies to headers
        },
        );
      print('Response status: ${response.statusCode}');
      print(response.body);*/
      final response = await requests.getRequest(
        'get_cart/${userInfo['_id']}',
        headers: {
          'Content-Type':'application/json'
        }
        );
      if (response.statusCode == 200) {
        setState(() {
          List<dynamic> jsonData = jsonDecode(response.body);
          cartItems = jsonData.map((item) => item as Map<String, dynamic>).toList();
          content = response.body;
          isLoading = false;
        });
      } else {
        setState(() {
          content = 'Failed to load content: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error occrued: $e');
      //print('Response status: ${response.statusCode}');
      setState(() {
        content = 'Error occurred: $e';
        isLoading = false;
      });
    }
  }

  Future<bool> removeFromCart(String id, int quantity) async {
    final requests = BackendRequests();
    final prefs = Prefs();
    String cookies = '';
    Map userInfo = {};
    cookies = await prefs.getPrefs('cookies') ?? '';
    userInfo = jsonDecode( await prefs.getPrefs('userInfo') ?? '{}');

    // Step 1: Retrieve the CSRF token
    
    // Step 2: Prepare the login data as JSON
    final changePayload = jsonEncode({
      'item_id': id,
      'quantity': quantity,
    });

    // Step 3: Send a POST request to the login endpoint with the CSRF token in headers
    /*
    final url = Uri.parse('http://127.0.0.1:5000/remove_from_cart/${userInfo["_id"]}/');
    final changeResponse = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "X-CSRFToken": csrfToken, // Adjust header name if needed
        "Cookies": cookies
      },
      body: changePayload,
    );*/
    final changeResponse = await requests.postRequest(
      'remove_from_cart/${userInfo["_id"]}/',
      body:
        {
          'item_id': id,
          'quantity': quantity,
        }
    );
    // Step 4: Handle the login response
    if (changeResponse.statusCode == 200) {
      // Parse the returned user info
      print(changeResponse.body);

      // Extract cookies from the response headers
      // Note: The cookie string might include additional attributes
      final String? cookies = changeResponse.headers['set-cookie'];
      print("Cookies: $cookies");

      // Step 5: Save the user info and cookies using SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userInfo', jsonEncode(userInfo));
      if (cookies != null) {
        await prefs.setString('cookies', cookies);
      }

      print("Removed Item Successfully");
      return true;
    } else {
      print("Failed to remove item: ${changeResponse.statusCode}");
      print("Response: ${changeResponse.body}");
    }
    return false;
  }

  // Calculate the total price of items in the cart
  double get totalPrice =>
      cartItems.fold(0.0, (sum, item) => sum + item['price'] * item['quantity']);

  double deliveryPrice = 0.0;

  // Remove an item from the cart
  void removeItem(int index, {int count = 1}) {
    _showMessage("removed item");
    bool status = false;
    removeFromCart(cartItems[index]['_id'], count).then((s){
      status = s;
      if (status == false){
        print("An error occured whie trying to delete cart item");
      } else{
        setState(() {
          cartItems[index]['quantity']-=count;
        });
        if (cartItems[index]['quantity']<=0){
          setState(() {
            cartItems.removeAt(index);
          });
        }
      }    
    });
  }

  void checkLoggedIn(context){
    if (getPrefs('userInfo') == Null || getPrefs('cookies') == Null){
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
    }
  }

  void onCardTap(index){
    final data = cartItems[index];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProductPage(product: 
          Product(
            id: data['_id']?.toString() ?? '', // Ensure no null id
            name: data['name']?.toString() ?? 'Unknown', // Default to 'Unknown'
            price: double.tryParse(data['price']?.toString() ?? '0.0') ?? 0.0, // Fallback to 0.0
            images: List<String>.from(data['photos'] ?? []), // Ensure it's a List<String>
            category: data['category']?.toString() ?? 'No category', // Default category
            stockQuantity: int.tryParse(data['stock_quantity']?.toString() ?? '0') ?? 0, // Fallback to 0
            description: data['description']?.toString() ?? 'No description', // Default description
          )
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    
    cartItems = [];

    final requests = BackendRequests();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if(! await requests.isLoggedIn()){
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      fetchCartContent();
    });


    WidgetsBinding.instance.addPostFrameCallback((_) {
    });    
    /*for (int i=0;i<cartItems.length;i++) {
      cartItems[i]['quantity'] = cartItems[i]['quantity']; // Add or update the 'amount' field to 1
    }*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Cart", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      /*appBar: AppBar(
        title: Text("Checkout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        /*title:Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          
          children:[
            backButton,
            /*SizedBox(
              width: 105,
              //child:backButton,
            ),*/
            
            const SizedBox(height: 12),
            const Text(
              'Cart',
              style: TextStyle(
                fontSize: 35, // Set the font size
                fontWeight: FontWeight.bold, // Optional: Set font weight
              ),
            ),
          ],
        ),*/
        //centerTitle: true,
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        automaticallyImplyLeading: false, // Prevent default back button
        toolbarHeight: 130,
        //leading: backButton
      ),*/

      
      body: SafeArea( 
        child: isLoading ? Center(child: CircularProgressIndicator()) : cartItems.isEmpty ? Center(child: Text('No Items in Cart')) : Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,// number of items in the cart
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Slidable(
                      key: ValueKey(item['name']),
                      endActionPane: ActionPane(
                        extentRatio: 0.3,
                        motion: ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) {
                              removeItem(index);
                            },
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.black,
                            icon: Icons.exposure_minus_1,
                            flex: 1, // Takes 1 units of space
                            //label: 'Remove One',
                          ),
                          SlidableAction(
                            onPressed: (context) { 
                              removeItem(index, count: item['quantity']);
                              },
                            //label: 'Remove All',
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.black,
                            icon: Icons.delete,
                            flex: 1, // Takes 1 units of space
                            //closeOnTap: false, // Prevent slider from closing immediately
                            //label: 'Delete',
                          ),
                        ],
                      ),
                      child: Card(// cart item display card
                        margin: EdgeInsets.symmetric(vertical: 5.0),
                        
                        child: ListTile(
                          leading: Image.network( // image
                            item['photos'][0], // Replace this with your image URL
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover, // Ensures the image fills the space
                          ),
                          title: Text(item['name']),
                          onTap: () {
                              onCardTap(index);
                            },
                          subtitle:
                              Text('Price: \$${item['price']} x ${item['quantity']} = \$${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Items (${(cartItems.length)}):',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white),
                        ),
                        Text(
                          '\$${(totalPrice).toStringAsFixed(2)}', // Example value for total items
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // Add spacing between rows
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Standard Delivery:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white),
                        ),
                        Text(
                          '\$${deliveryPrice.toStringAsFixed(2)}', // Example delivery cost
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // Add spacing between rows
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '\$${(totalPrice+deliveryPrice).toStringAsFixed(2)}', // Final total cost
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                /*child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(fontSize: 25),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                    );
                  },
                  child: const Text('Checkout'),
                ),*/
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black, // Background color
                    backgroundColor: Colors.white, // Text and icon color
                  ),
                  onPressed: () {
                    // Handle checkout logic here
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Proceeding to Checkout...')),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutScreen(),
                      ),
                    );
                    //Navigator.pushNamed(context, '/checkout');
                  },
                  child: Text('Checkout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
