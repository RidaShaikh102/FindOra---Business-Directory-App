import 'package:flutter/material.dart';
import 'package:findora/screens/about_us.dart';
import 'package:findora/screens/contact_us.dart';
import 'package:findora/screens/help_center.dart';
import 'package:findora/screens/home_screen.dart';
import 'package:findora/screens/login_screen.dart';
import 'package:findora/screens/map.dart';
import 'package:findora/screens/my_orders_screen.dart';
import 'package:findora/screens/owner/manage_orders_screen.dart';
import 'package:findora/screens/privacy_policy.dart';
import 'package:findora/screens/profile_screen.dart';
import 'package:findora/screens/saved_businesses.dart';
import 'package:findora/screens/search_screen.dart';
import 'package:findora/screens/owner/owner_dashboard.dart';
import 'package:findora/services/auth_service.dart';
import 'package:findora/services/analytics_service.dart';
import 'package:findora/widgets/responsive_layout.dart';

class MainScreen extends StatefulWidget {
  final String userRole;

  const MainScreen({super.key, required this.userRole});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  late final List<Widget> _screens;
  late final List<BottomNavigationBarItem> _navItems;
  late final List<String> _tabNames;

  @override
  void initState() {
    super.initState();
    if (widget.userRole == 'owner') {
      _screens = const [
        OwnerDashboardScreen(),
        HomeScreen(),
        MapScreen(),
        SearchScreen(),
        SavedBusinessesScreen(),
        ProfileScreen(),
      ];
      _navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Owner Panel',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_border),
          label: 'Saved',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ];
      _tabNames = [
        'OwnerTab',
        'HomeTab',
        'MapTab',
        'SearchTab',
        'SavedTab',
        'ProfileTab',
      ];
    } else {
      _screens = const [
        HomeScreen(),
        MapScreen(),
        SearchScreen(),
        SavedBusinessesScreen(),
        ProfileScreen(),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_border),
          label: 'Saved',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ];
      _tabNames = ['HomeTab', 'MapTab', 'SearchTab', 'SavedTab', 'ProfileTab'];
    }
    AnalyticsService.logScreenView(_tabNames[_selectedIndex]);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    AnalyticsService.logScreenView(_tabNames[index]);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isMediumOrLarger(context);
    if (!isDesktop) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(context),
        appBar: _buildTopAppBar(),
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: const Color(0xFF0A2D3F),
          unselectedItemColor: Colors.teal[600],
          onTap: _onItemTapped,
          items: _navItems,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: _buildTopAppBar(),
      body: ResponsivePageContainer(
        maxWidth: 1440,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                backgroundColor: Colors.white,
                labelType: NavigationRailLabelType.all,
                selectedLabelTextStyle: const TextStyle(
                  color: Color(0xFF0A2D3F),
                  fontWeight: FontWeight.w700,
                ),
                selectedIconTheme: const IconThemeData(color: Color(0xFF0A2D3F)),
                unselectedIconTheme: IconThemeData(color: Colors.teal.shade600),
                destinations: _navItems
                    .map(
                      (item) => NavigationRailDestination(
                        icon: item.icon,
                        label: Text(item.label ?? ''),
                      ),
                    )
                    .toList(),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: IconButton(
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      icon: const Icon(Icons.menu_open_rounded),
                      tooltip: 'Open menu',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(color: Colors.white, child: _screens[_selectedIndex]),
              ),
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(context),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      iconTheme: const IconThemeData(color: Colors.teal),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'FindOra',
            style: TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(0, 255, 255, 255),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset('lib/assets/logo.png', height: 32, width: 32),
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header with same gradient as profile screen
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0A2D3F),
                    const Color(0xFF0A2D3F).withOpacity(0.9),
                    Colors.teal.shade700,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Image.asset('lib/assets/logo.png', width: 46, height: 46),
                  const SizedBox(width: 12),
                  const Text(
                    'FindOra',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerTile(Icons.person, 'My Profile', context),
                  _drawerTile(Icons.receipt_outlined, 'My Orders', context),
                  if (widget.userRole == 'owner')
                    _drawerTile(Icons.store, 'Owner Panel', context),
                  if (widget.userRole == 'owner')
                    _drawerTile(Icons.receipt_long, 'Manage Orders', context),
                  _drawerTile(Icons.privacy_tip, 'Privacy Policy', context),
                  _drawerTile(Icons.help_outline, 'Help Center', context),
                  _drawerTile(Icons.contact_mail, 'Contact (FindOra)', context),
                  _drawerTile(Icons.info_outline, 'About FindOra', context),
                  const Divider(),
                  _drawerTile(Icons.logout, 'Log Out', context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ListTile _drawerTile(IconData icon, String title, BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A2D3F).withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF0A2D3F)),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () async {
        Navigator.pop(context);
        await Future.delayed(const Duration(milliseconds: 200));

        if (title == 'My Profile') {
          setState(() {
            _selectedIndex = widget.userRole == 'owner' ? 5 : 4;
          });
        } else if (title == 'My Orders') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
          );
        } else if (title == 'Owner Panel') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()),
          );
        } else if (title == 'Manage Orders') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageOrdersScreen()),
          );
        } else if (title == 'Help Center') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
          );
        } else if (title == 'Privacy Policy') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
          );
        } else if (title == 'Contact (FindOra)') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContactUsScreen()),
          );
        } else if (title == 'About FindOra') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AboutScreen()),
          );
        } else if (title == 'Log Out') {
          await AuthService().logout();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      },
    );
  }
}
