import 'package:aisleaide/Voice_assistant_and_database/camera_screen.dart';
import 'package:aisleaide/Voice_assistant_and_database/cart_screen.dart';
import 'package:aisleaide/Voice_assistant_and_database/create_product_list_screen.dart';
import 'package:aisleaide/Voice_assistant_and_database/home_screen.dart';
import 'package:aisleaide/Voice_assistant_and_database/navigation_screen.dart';
import 'package:aisleaide/Voice_assistant_and_database/profile_screen.dart';
import 'package:aisleaide/Voice_assistant_and_database/search_products_screen.dart';
import 'package:flutter/material.dart';

class MyNavigationBar extends StatefulWidget {
  const MyNavigationBar({super.key});

  @override
  MyNavigationBarState createState() => MyNavigationBarState();
}

class MyNavigationBarState extends State<MyNavigationBar> {
  int _currentIndex = 0;

  final List<Widget> _children = const [
    HomeScreen(),
    NavigationScreen(),
    CameraScreen(),
    CartScreen(),
    ProfileScreen(),
    CreateProductListScreen(),
    SearchProductsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 101, 101, 101).withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: onTabTapped,
          selectedItemColor: const Color.fromRGBO(54, 72, 107, 1),
          unselectedItemColor:
              const Color.fromARGB(255, 148, 152, 154).withOpacity(1),
          elevation: 8,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          iconSize: 24,
          items: const [
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage(
                  'assets/home.png')), // Example of using a custom image
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage(
                  'assets/marker.png')), // Example of using a custom image
              label: 'Navigation',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/camera.png')),
              label: 'Product Scan',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/shopping-cart.png')),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/user.png')),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
