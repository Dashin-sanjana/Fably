import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:convert'; // For JSON decoding, if needed
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login.dart';
import '../../utils/requests.dart';
import '../../utils/prefs.dart';
import '../home/widgets/common_drawer.dart';
import '../shop/cart.dart';
import '../shop/product.dart';
import '../home/widgets/bottom_nav_bar.dart';

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
      title: 'Wishlist Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WishlistPage(),
    );
  }
}

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {

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

  Future<void> fetchWishlistContent() async{
    //_showMessage("Fetching Wishlist Items...");
    final requests = BackendRequests();
    final prefs = Prefs();
    String cookies = '';
    Map userInfo = {};
    cookies = await prefs.getPrefs('cookies') ?? '';
    String? info = await prefs.getPrefs('userInfo');
    userInfo = jsonDecode(info ?? '{}');
    
    try {
      
      final response = await requests.getRequest(
        'get_wishlist/${userInfo['_id']}',
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

  Future<void> signOut() async {
    final requests = BackendRequests();
    final prefs = Prefs();

    try{
      final response = await requests.getRequest('logout');
      if (response.statusCode==200){
        await prefs.clearPrefs();
        _showMessage('Logged out successfully');
      }
    }catch (e) {
      _showMessage('Error Loging out: $e');
    }

  }

  Future<bool> removeFromWishlist(String id) async {
    final requests = BackendRequests();
    final prefs = Prefs();
    String cookies = '';
    Map userInfo = {};
    cookies = await prefs.getPrefs('cookies') ?? '';
    userInfo = jsonDecode( await prefs.getPrefs('userInfo') ?? '{}');

    final changeResponse = await requests.postRequest(
      'remove_from_wishlist/${userInfo["_id"]}/',
      body:
        {
          'item_id': id,
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

  void removeItem(int index) {
    _showMessage("removed item");
    bool status = false;
    removeFromWishlist(cartItems[index]['_id']).then((s){
      setState(() {
        cartItems.removeAt(index);
      });
    });
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

  @override
  void initState() {
    super.initState();
    
    cartItems = [];

    final requests = BackendRequests();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if(!await requests.isLoggedIn()){
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      fetchWishlistContent();
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
        title: const Text(
          'Fably - WISHLIST',
          style: TextStyle(
            letterSpacing: 3,
            fontFamily: "Italiana",
            fontWeight: FontWeight.bold,
            fontSize: 24,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
          ),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(),
                  //builder: (context) => ProductPage(product: myProduct),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              signOut().then((o){
                Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              });
            },
          ),
        ],
      ),
      drawer: CommonDrawer(),
            
      body: isLoading ? Center(child: CircularProgressIndicator()) : cartItems.isEmpty ? Center(child: Text('No Items in Wishlist')) : Padding(
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
                          icon: Icons.delete,
                          flex: 1, // Takes 1 units of space
                          //closeOnTap: false, // Prevent slider from closing immediately
                          label: 'Remove',
                        ),
                      ],
                    ),
                    child: Card(// cart item display card
                      margin: EdgeInsets.symmetric(vertical: 5.0),
                      elevation: 4, // Adds shadow to the card
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),

                      child: ListTile(
                        leading: Image.network( // image
                          item['photos'][0],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                        onTap: () {
                            onCardTap(index);
                          },
                        title: Text(item['name']),
                        subtitle:
                            Text('Price: \$${item['price']}'),
                      ),
                    ),
                  );
                },
              ),
            ),
            Divider(),
            
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
                child: const Text('Add all to cart'),
              ),*/
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black, // Background color
                  backgroundColor: Colors.white, // Text and icon color
                ),
                onPressed: () {
                },
                child: Text('Add all to cart'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 1,
        //onTap: _onNavBarTap,
      ),
    );
  }
}
