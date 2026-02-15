import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter/services.dart';

import '../auth/login.dart';
import '../shop/product.dart';
import '../shop/cart.dart';
import '../../utils/requests.dart';
import '../../utils/prefs.dart';
import 'widgets/common_drawer.dart';
import 'widgets/bottom_nav_bar.dart';

class ProductService {
  final requests = BackendRequests();
  
  static String _baseUrl = 'http://192.168.1.7:5000/products';

  Future<List<Product>> fetchProducts() async {
    _baseUrl = '${requests.getUrl()}/products';
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final double heightFactor;

  const ProductCard({
    super.key, 
    required this.product,
    this.heightFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.network(
                    product.images.isNotEmpty ? product.images[0] : '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: 'jura',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price}',
                  style: const TextStyle(
                    fontFamily: 'jura',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> futureProducts;
  int _selectedCategory = 0;
  final List<String> _categories = ['All', 'New', 'Trending', 'Shoes', 'Accessories'];

  Future<void> _refreshProducts() async {
    setState(() {
      futureProducts = ProductService().fetchProducts();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'jura'),
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> signOut() async {
    final requests = BackendRequests();
    final prefs = Prefs();

    try {
      final response = await requests.getRequest('logout');
      if (response.statusCode == 200) {
        await prefs.clearPrefs();
        _showMessage('Logged out successfully');
      }
    } catch (e) {
      _showMessage('Error Logging out: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ));
    
    final requests = BackendRequests();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!await requests.isLoggedIn()) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
    futureProducts = ProductService().fetchProducts();
  }

  // Calculate different heights based on index
  double _getItemHeight(int index) {
    if (index % 4 == 0 || index % 4 == 3) {
      return 1.2; // Taller
    } else if (index % 4 == 1) {
      return 0.9; // Shorter
    }
    return 1.0; // Normal
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: const Text(
          'FABLY',
          style: TextStyle(
            letterSpacing: 3,
            fontFamily: 'jura',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(),
                ),
              );
            },
          ),
        ],
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: CommonDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Discover',
              style: TextStyle(
                fontFamily: 'jura',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Category selector - with reduced height
          SizedBox(
            height: 36, // Reduced from 48
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedCategory == index 
                          ? Colors.white 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _categories[index],
                      style: TextStyle(
                        fontFamily: 'jura',
                        color: _selectedCategory == index 
                            ? Colors.black 
                            : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Products grid - Modified to create unbalanced look without staggered grid
          Expanded(
            child: LiquidPullToRefresh(
              color: Colors.white,
              backgroundColor: Colors.black,
              height: 60.0,
              showChildOpacityTransition: false,
              onRefresh: _refreshProducts,
              child: FutureBuilder<List<Product>>(
                future: futureProducts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(
                          fontFamily: 'jura',
                          color: Colors.white,
                        ),
                      ),
                    );
                  } else if (snapshot.hasData) {
                    final products = snapshot.data!;
                    
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.68, // Taller aspect ratio for all items
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        // Create visual imbalance by applying different padding
                        EdgeInsets padding;
                        if (index % 4 == 0) {
                          padding = const EdgeInsets.only(bottom: 24); // Push down
                        } else if (index % 4 == 1) {
                          padding = const EdgeInsets.only(top: 24); // Push up
                        } else if (index % 4 == 2) {
                          padding = const EdgeInsets.only(bottom: 12); // Slight push down
                        } else {
                          padding = const EdgeInsets.only(top: 12); // Slight push up
                        }
                        
                        return Padding(
                          padding: padding,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductPage(
                                    product: products[index],
                                  ),
                                ),
                              );
                            },
                            child: ProductCard(
                              product: products[index],
                              heightFactor: _getItemHeight(index),
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: Text(
                        'No products available.',
                        style: TextStyle(
                          fontFamily: 'jura',
                          color: Colors.white,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 0,
      ),
    );
  }
}