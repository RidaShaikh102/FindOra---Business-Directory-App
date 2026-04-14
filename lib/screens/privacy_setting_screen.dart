import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _shareProfile = true;
  bool _allowNotifications = true;
  bool _showOnlineStatus = true;
  bool _dataSharing = true;
  bool _allowLocation = true;

  bool _isLoading = true;

  final Color onColor = const Color(0xFF0A2D3F); // Dark teal
  final Color offColor = Colors.teal; // Teal

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('privacy_settings');
    if (settingsJson != null) {
      final data = jsonDecode(settingsJson);
      setState(() {
        _shareProfile = data['shareProfile'] ?? true;
        _allowNotifications = data['allowNotifications'] ?? true;
        _showOnlineStatus = data['showOnlineStatus'] ?? true;
        _dataSharing = data['dataSharing'] ?? true;
        _allowLocation = data['allowLocation'] ?? true;
        _isLoading = false;
      });
    } else {
      // Default settings
      final defaultSettings = {
        'shareProfile': true,
        'allowNotifications': true,
        'showOnlineStatus': true,
        'dataSharing': true,
        'allowLocation': true,
      };
      await prefs.setString('privacy_settings', jsonEncode(defaultSettings));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('privacy_settings');
    Map<String, dynamic> settings = {};
    if (settingsJson != null) {
      settings = jsonDecode(settingsJson);
    }
    settings[key] = value;
    await prefs.setString('privacy_settings', jsonEncode(settings));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        flexibleSpace: Container(
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
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Privacy Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildSwitchTile(
                "Share Profile with Public",
                _shareProfile,
                (val) => setState(() {
                  _shareProfile = val;
                  _updateSetting('shareProfile', val);
                }),
              ),
              _buildDivider(),
              _buildSwitchTile(
                "Allow Notifications",
                _allowNotifications,
                (val) => setState(() {
                  _allowNotifications = val;
                  _updateSetting('allowNotifications', val);
                }),
              ),
              _buildDivider(),
              _buildSwitchTile(
                "Show Online Status",
                _showOnlineStatus,
                (val) => setState(() {
                  _showOnlineStatus = val;
                  _updateSetting('showOnlineStatus', val);
                }),
              ),
              _buildDivider(),
              _buildSwitchTile(
                "Data Sharing with Partners",
                _dataSharing,
                (val) => setState(() {
                  _dataSharing = val;
                  _updateSetting('dataSharing', val);
                }),
              ),
              _buildDivider(),
              _buildSwitchTile(
                "Allow Location Access",
                _allowLocation,
                (val) => setState(() {
                  _allowLocation = val;
                  _updateSetting('allowLocation', val);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: onColor,
        inactiveThumbColor: offColor,
        inactiveTrackColor: offColor.withOpacity(0.4),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 0, thickness: 1, color: Colors.grey.shade300);
  }
}
