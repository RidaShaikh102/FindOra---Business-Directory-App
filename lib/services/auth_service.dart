import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
import 'migration_service.dart';

class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleInit;

  String? _cachedRole;
  String? _cachedUserDocUid;
  Map<String, dynamic>? _cachedUserDoc;

  Future<bool> login(String email, String password, {bool save = false}) async {
    if (email.isEmpty || password.isEmpty) return false;
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) return false;
      final data = await _ensureUserDoc(user);
      if (data['isBlocked'] == true) {
        await logout();
        return false;
      }
      await MigrationService.migrateSharedData();
      await MigrationService.migrateUserDataIfNeeded();
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  Future<bool> signup(
    String email,
    String password,
    String name, {
    String role = 'user',
  }) async {
    if (email.isEmpty || password.isEmpty) return false;
    if (email == superAdminEmail || role == 'super_admin') {
      return false;
    }

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) return false;
      await user.updateDisplayName(name);
      await _ensureUserDoc(
        user,
        roleHint: _resolveRole(email, role),
        nameHint: name,
      );
      await MigrationService.migrateSharedData();
      await MigrationService.migrateUserDataIfNeeded();
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      UserCredential cred;
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        cred = await _auth.signInWithPopup(provider);
      } else {
        await _ensureGoogleInitialized();
        if (!_googleSignIn.supportsAuthenticate()) return false;
        final googleUser = await _googleSignIn.authenticate();
        final googleAuth = googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        cred = await _auth.signInWithCredential(credential);
      }

      final user = cred.user;
      if (user == null) return false;
      final data = await _ensureUserDoc(
        user,
        roleHint: _resolveRole(user.email ?? '', null),
        nameHint: user.displayName,
      );
      if (data['isBlocked'] == true) {
        await logout();
        return false;
      }
      await MigrationService.migrateSharedData();
      await MigrationService.migrateUserDataIfNeeded();
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  Future<void> logout() async {
    _clearCachedUserState();
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }

  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  Future<String?> getCurrentUserEmail() async {
    return _auth.currentUser?.email;
  }

  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  /// City used for marketplace delivery rules (e.g. Sukkur local vs courier).
  Future<String?> getUserCity() async {
    final data = await _getCurrentUserDoc();
    final city = data?['city']?.toString().trim();
    if (city == null || city.isEmpty) return null;
    return city;
  }

  Future<void> setUserCity(String city) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final normalized = city.trim();
    await _firestore.collection('users').doc(user.uid).set({
      'city': normalized,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _mergeCachedUserDoc({
      'city': normalized,
      'updatedAt': FieldValue.serverTimestamp(),
    }, uid: user.uid);
  }

  Future<String?> getCurrentUserName() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final data = await _getCurrentUserDoc();
    final name = data?['name']?.toString().trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    return _nameFromEmail(user.email ?? '');
  }

  Future<String?> getCurrentUserRole() async {
    if (_cachedRole != null) return _cachedRole;
    final user = _auth.currentUser;
    if (user == null) return null;
    final data = await _getCurrentUserDoc();
    if (data != null) {
      if (data['isBlocked'] == true) {
        await logout();
        return null;
      }
      final role = (data['role'] ?? 'user').toString();
      _cachedRole = role;
      return role;
    }

    final created = await _ensureUserDoc(user);
    final role = (created['role'] ?? 'user').toString();
    _cachedRole = role;
    return role;
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['uid'] = doc.id;
      return data;
    }).toList();
  }

  Future<int> getUserCount() async {
    final snapshot = await _firestore.collection('users').count().get();
    return snapshot.count ?? 0;
  }

  Future<void> saveUsers(List<Map<String, dynamic>> users) async {
    WriteBatch batch = _firestore.batch();
    int count = 0;
    for (final user in users) {
      final uid = (user['uid'] ?? user['id'])?.toString();
      if (uid == null || uid.isEmpty) continue;
      final payload = <String, dynamic>{
        if (user['email'] != null) 'email': user['email'],
        if (user['name'] != null) 'name': user['name'],
        if (user['role'] != null) 'role': user['role'],
        if (user['isBlocked'] != null) 'isBlocked': user['isBlocked'],
        'updatedAt': FieldValue.serverTimestamp(),
      };
      batch.set(
        _firestore.collection('users').doc(uid),
        payload,
        SetOptions(merge: true),
      );
      count++;
      if (count >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }
    if (count > 0) {
      await batch.commit();
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final data = Map<String, dynamic>.from(doc.data());
    data['uid'] = doc.id;
    return data;
  }

  Future<bool> changePassword(
    String email,
    String oldPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null || user.email != email) return false;

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  Future<Map<String, dynamic>> _ensureUserDoc(
    User user, {
    String? roleHint,
    String? nameHint,
  }) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final doc = await ref.get();

    final email = user.email ?? '';
    final resolvedRole = _resolveRole(email, roleHint);
    final displayName = nameHint?.trim().isNotEmpty == true
        ? nameHint!.trim()
        : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : _nameFromEmail(email));

    if (!doc.exists) {
      final data = <String, dynamic>{
        'email': email,
        'name': displayName,
        'role': resolvedRole,
        'isBlocked': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };
      await ref.set(data, SetOptions(merge: true));
      _cachedRole = resolvedRole;
      _mergeCachedUserDoc(data, uid: user.uid);
      return data;
    }

    final data = Map<String, dynamic>.from(doc.data() as Map);
    final updates = <String, dynamic>{
      'lastLoginAt': FieldValue.serverTimestamp(),
    };
    if ((data['email'] == null || (data['email'] as String).isEmpty) &&
        email.isNotEmpty) {
      updates['email'] = email;
    }
    if ((data['name'] == null || (data['name'] as String).isEmpty) &&
        displayName.isNotEmpty) {
      updates['name'] = displayName;
    }
    // Only set role from hint when doc has no role; never overwrite existing 'owner' with 'user'
    final existingRole = (data['role'] ?? '').toString();
    if (existingRole.isEmpty && resolvedRole.isNotEmpty) {
      updates['role'] = resolvedRole;
    }
    if (updates.length > 1) {
      await ref.set(updates, SetOptions(merge: true));
    }

    final effectiveRole = (data['role'] ?? resolvedRole ?? 'user').toString();
    _cachedRole = effectiveRole;
    final merged = {...data, ...updates, 'role': effectiveRole, 'email': email};
    _mergeCachedUserDoc(merged, uid: user.uid);
    return merged;
  }

  Future<void> _ensureGoogleInitialized() async {
    _googleInit ??= _googleSignIn.initialize();
    return _googleInit!;
  }

  String _resolveRole(String email, String? roleHint) {
    if (email == superAdminEmail) return 'super_admin';
    if (roleHint == null || roleHint.isEmpty) return 'user';
    return roleHint;
  }

  String _nameFromEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return 'User';
    return email.split('@').first;
  }

  Future<Map<String, dynamic>?> _getCurrentUserDoc({
    bool forceRefresh = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _cachedUserDoc = null;
      _cachedUserDocUid = null;
      return null;
    }

    if (!forceRefresh &&
        _cachedUserDocUid == user.uid &&
        _cachedUserDoc != null) {
      return Map<String, dynamic>.from(_cachedUserDoc!);
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    _cachedUserDocUid = user.uid;
    if (!doc.exists || doc.data() == null) {
      _cachedUserDoc = null;
      return null;
    }

    _cachedUserDoc = Map<String, dynamic>.from(doc.data()!);
    return Map<String, dynamic>.from(_cachedUserDoc!);
  }

  void _mergeCachedUserDoc(Map<String, dynamic> data, {required String uid}) {
    _cachedUserDocUid = uid;
    final merged = <String, dynamic>{...?_cachedUserDoc, ...data};
    _cachedUserDoc = merged;
  }

  void _clearCachedUserState() {
    _cachedRole = null;
    _cachedUserDocUid = null;
    _cachedUserDoc = null;
  }
}
