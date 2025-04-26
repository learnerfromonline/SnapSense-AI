import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:genai/screens/chat.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genai/main.dart';

class NavScreen extends StatefulWidget {
  @override
  _NavScreenState createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  int _selectedIndex = 0;

  // List of screens to navigate
  final List<Widget> _screens = [
    ImagePromptScreen(),
    Chatscreen(),
    
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121), // Dark gray background
      body: _screens[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.image, size: 30, color: Colors.white),
          Icon(Icons.chat, size: 30, color: Colors.white),
          
        ],
        color:Colors.black, // Soft blue
        buttonBackgroundColor: Colors.black, // Lighter blue for selected
        backgroundColor: const Color.fromARGB(117, 33, 33, 33), // Match scaffold background
        onTap: _onItemTapped,
        letIndexChange: (index) => true,
      ),
    );
  }
}