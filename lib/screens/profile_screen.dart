import 'package:findora/services/auth_service.dart';
import 'package:findora/screens/change_password_dialog.dart';
import 'package:findora/screens/contact_us.dart';
import 'package:findora/screens/help_center.dart';
import 'package:findora/screens/login_screen.dart';
import 'package:findora/screens/my_orders_screen.dart';
import 'package:findora/screens/my_reviews.dart';
import 'package:findora/screens/privacy_setting_screen.dart';
import 'package:findora/screens/saved_businesses.dart';
import 'package:findora/services/deep_link_service.dart';

import 'package:findora/screens/your_businesses.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = "";
  String _email = "";
  String _role = "";
  String _city = "";
  bool _shareProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  /// Load user info from local storage
  Future<void> _loadUserInfo() async {
    final authService = AuthService();
    final loggedIn = await authService.isLoggedIn();
    if (!loggedIn) return;

    final email = await authService.getCurrentUserEmail() ?? '';
    final role = await authService.getCurrentUserRole() ?? 'user';
    final city = await authService.getUserCity() ?? '';

    // For simplicity, use email prefix as username, or load from prefs if stored
    final prefs = await SharedPreferences.getInstance();
    final username =
        prefs.getString('username') ??
        (email.isNotEmpty ? email.split('@')[0] : 'User');

    final prefsPrivacy = await SharedPreferences.getInstance();
    final privacyJson = prefsPrivacy.getString('privacy_settings');
    bool shareProfile = true;
    if (privacyJson != null) {
      try {
        final data = jsonDecode(privacyJson);
        shareProfile = data['shareProfile'] ?? true;
      } catch (_) {
        shareProfile = true;
      }
    }

    if (!mounted) return;
    setState(() {
      _email = email;
      _username = username;
      _role = role;
      _city = city;
      _shareProfile = shareProfile;
    });
  }

  Future<void> _editCity() async {
    final controller = TextEditingController(text: _city);
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery city'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'City',
            hintText: 'e.g. Sukkur',
          ),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final value = controller.text.trim();
    if (value.isEmpty) return;

    try {
      await AuthService().setUserCity(value);
      if (!mounted) return;
      setState(() => _city = value);
      messenger.showSnackBar(const SnackBar(content: Text('City updated')));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update city: $e')),
      );
    } finally {
      controller.dispose();
    }
  }

  /// Edit username dialog
  Future<void> _editUsername() async {
    final controller = TextEditingController(text: _username);
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.teal, width: 1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Username",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: "Enter new username",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.teal, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.teal, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.teal, width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A2D3F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final newName = controller.text.trim();
                      if (newName.isEmpty) return;

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('username', newName);

                      if (!mounted) return;
                      setState(() {
                        _username = newName;
                      });

                      Navigator.pop(context);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text("Username updated successfully!"),
                        ),
                      );
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Log out
  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 🔹 Modern Profile Header
                Container(
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
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                      child: Column(
                        children: [
                          // Top action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Profile",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: _editUsername,
                                      tooltip: "Edit Profile",
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: FaIcon(
                                        FontAwesomeIcons.shareNodes,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      onPressed: _shareProfile
                                          ? () {
                                              final profileUrl = DeepLinkService.generateShareableProfileLink(
                                                username: _username.trim(),
                                                role: _role.trim(),
                                                city: _city.trim(),
                                              );
                                              Share.share(
                                                'Check out my FindOra profile: $profileUrl',
                                                subject: 'My FindOra profile',
                                              );
                                            }
                                          : () {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Profile sharing is turned off in Privacy Settings.',
                                                  ),
                                                ),
                                              );
                                            },
                                      tooltip: _shareProfile
                                          ? "Share Profile"
                                          : "Sharing disabled",
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          // Profile Avatar
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Container(
                                color: Colors.teal.shade100,
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Username
                          Text(
                            _username.isNotEmpty ? _username : "Loading...",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Email
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.email_outlined,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _email,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_role.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _role.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 🔹 Menu Options in Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildModernOptionCard(
                        _city.trim().isEmpty
                            ? "Set delivery city"
                            : "Delivery city: $_city",
                        Icons.location_city_rounded,
                        Colors.teal.shade700,
                        onTap: _editCity,
                      ),
                      if (_role == 'owner')
                        _buildModernOptionCard(
                          "Your Businesses",
                          Icons.store_rounded,
                          Colors.teal.shade700,
                          screen: YourBusinessesScreen(userEmail: _email),
                        ),
                      _buildModernOptionCard(
                        "Change Password",
                        Icons.lock_rounded,
                        Colors.teal.shade700,
                        onTap: () {
                          final messenger = ScaffoldMessenger.of(context);
                          showChangePasswordDialog(context, (
                            oldPass,
                            newPass,
                          ) async {
                            final success = await AuthService().changePassword(
                              _email,
                              oldPass,
                              newPass,
                            );
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? "Password updated successfully"
                                      : "Old password is incorrect",
                                ),
                                backgroundColor: success
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            );
                          });
                        },
                      ),
                      _buildModernOptionCard(
                        "Privacy Settings",
                        Icons.privacy_tip_rounded,
                        Colors.teal.shade700,
                        screen: const PrivacySettingsScreen(),
                      ),
                      _buildModernOptionCard(
                        "Saved Businesses",
                        Icons.favorite_rounded,
                        Colors.teal.shade700,
                        screen: const SavedBusinessesScreen(),
                      ),
                      _buildModernOptionCard(
                        "My Orders",
                        Icons.receipt_long_rounded,
                        Colors.teal.shade700,
                        screen: const MyOrdersScreen(),
                      ),
                      _buildModernOptionCard(
                        "Contact Us",
                        Icons.contact_mail_rounded,
                        Colors.teal.shade700,
                        screen: const ContactUsScreen(),
                      ),
                      _buildModernOptionCard(
                        "My Reviews",
                        Icons.rate_review_rounded,
                        Colors.teal.shade700,
                        screen: MyPostedReviewsScreen(loggedInEmail: _email),
                      ),
                      _buildModernOptionCard(
                        "Help Centers / FAQ’s",
                        Icons.help_rounded,
                        Colors.teal.shade700,
                        screen: const HelpCenterScreen(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 🔹 Logout button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.red.shade200,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Log Out",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "By continuing, you agree to our Terms of Services and Privacy Policy",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Modern Card-based Option Builder
  Widget _buildModernOptionCard(
    String title,
    IconData icon,
    Color iconColor, {
    Widget? screen,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              onTap();
            } else if (screen != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => screen),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
