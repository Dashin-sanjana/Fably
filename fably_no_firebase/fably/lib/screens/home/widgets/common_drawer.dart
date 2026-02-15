import 'package:fably/screens/home/home.dart';
import 'package:fably/screens/scanner/add_images.dart';
import 'package:fably/screens/shop/cart.dart';
import 'package:fably/screens/shop/wishlist.dart';
import 'package:flutter/material.dart';
import '../../../utils/prefs.dart';
import '../../../utils/requests.dart';
import '../../profile/pofile_page.dart';
import 'dart:ui';

class CommonDrawer extends StatelessWidget {
  const CommonDrawer({super.key});
  
  Future<void> signOut(BuildContext context) async {
    final requests = BackendRequests();
    final prefs = Prefs();

    try{
      final response = await requests.getRequest('logout');
      if (response.statusCode==200){
          await prefs.clearPrefs();
        _showMessage(context, 'Logged out successfully');
      }
    }catch (e) {
      _showMessage(context, 'Error Loging out: $e');
    }
  }

  void _showMessage(BuildContext context, String message) {
    print(message);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
        ),
        SizedBox(
          width: 280, // Increased overall drawer width
          height: 430,
          child: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: 108, // Reduced header height (default is 160)
                  child: Stack(
                    children: [
                      Container(
                        height: 80,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 30.0, top: 20.0),
                          child: Text(
                            'MENU',
                            style: TextStyle(
                              fontFamily: "jura",
                              letterSpacing: 6,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, 
                              fontSize: 24),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 13,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: ListTile(
                    leading: const Icon(
                      Icons.home,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'HOME',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Jura",
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.6),
                    ),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                  )),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: ListTile(
                    leading: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'MY CART',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Jura",
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.6),
                    ),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => CartPage()),
                      );
                    },
                  )),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: ListTile(
                    leading: const Icon(
                      Icons.favorite_border_outlined,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'WISHLIST',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Jura",
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.6),
                    ),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => WishlistPage()),
                      );
                    },
                  )),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: ListTile(
                    leading: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'VIRTUAL TRY-ON',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Jura",
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.6),
                    ),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => UploadImagesPage()),
                      );
                    },
                  )),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: ListTile(
                    leading: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'PROFILE',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Jura",
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.6),
                    ),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    },
                  )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}