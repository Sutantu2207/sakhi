import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'legal_navigator_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MapScreen(),
    LegalNavigatorScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: AppColors.softLavender,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primaryViolet),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: AppColors.primaryViolet),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_outlined),
            selectedIcon: Icon(Icons.support, color: AppColors.primaryViolet),
            label: 'Help',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primaryViolet),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
