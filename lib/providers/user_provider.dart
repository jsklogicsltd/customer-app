import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  UserProvider() {
    _init();
  }

  Timer? _loadTimeout;

  AppUser? get user => _user;
  bool get hasUser => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthOnly => _auth.currentUser != null && _user == null && !_isLoading;

  StreamSubscription? _userSub;

  void _init() {
    debugPrint('UserProvider: Starting auth listener...');
    _auth.authStateChanges().listen((User? user) async {
      debugPrint('UserProvider: Auth event received. User: ${user?.uid}');
      
      if (user == null) {
        _userSub?.cancel();
        _loadTimeout?.cancel();
        _user = null;
        _isLoading = false;
        _error = null;
        notifyListeners();
        return;
      }

      // If we already have this user and we are NOT currently loading, do nothing
      if (_user != null && _user!.id == user.uid && !_isLoading) {
         debugPrint('UserProvider: User ${user.uid} already active, skipping listener restart.');
         return;
      }

      debugPrint('UserProvider: Setting up profile listener for: ${user.uid}');
      _userSub?.cancel();
      _loadTimeout?.cancel();

      _isLoading = true;
      _error = null;
      notifyListeners();

      // Absolute safety: if nothing happens in 10 seconds, force stop loading
      _loadTimeout = Timer(const Duration(seconds: 10), () {
        if (_isLoading) {
          debugPrint('UserProvider: CRITICAL TIMEOUT for ${user.uid}');
          _isLoading = false;
          _error = "Server response delayed. Please check connection.";
          notifyListeners();
        }
      });

      _userSub = _db.collection('users').doc(user.uid).snapshots().listen((snap) {
        debugPrint('UserProvider: Snapshot received (exists: ${snap.exists})');
        _loadTimeout?.cancel();
        try {
          if (snap.exists && snap.data() != null) {
            _user = AppUser.fromMap(snap.data()!);
            _error = null;
            debugPrint('UserProvider: Profile loaded for ${_user?.name}');
          } else {
            _user = null;
            // Removed specific error string to allow "isAuthOnly" logic to trigger for redirects
            _error = "Profile not found in database."; 
            debugPrint('UserProvider: WARNING!! Document missing for ${user.uid}');
          }
        } catch (e) {
          _error = "Data parsing error: $e";
          _user = null;
          debugPrint('UserProvider: Parse error: $e');
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      }, onError: (e) {
        _loadTimeout?.cancel();
        debugPrint('UserProvider: Listener error: $e');
        if (e.toString().contains('permission-denied')) {
          _error = "Database Access Denied! Please check Firebase Security Rules.";
        } else {
          _error = "Database connection error: $e";
        }
        _isLoading = false;
        _user = null;
        notifyListeners();
      });
    });
  }


  Future<void> syncFCMToken(String token) async {
    if (_user == null) return;
    await _db.collection('users').doc(_user!.id).update({
      'fcmToken': token,
    });
  }

  // _loadUser is no longer needed as we use a real-time listener

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required String language,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        await credential.user!.sendEmailVerification();
        
        // Initial profile
        final newUser = {
          'id': credential.user!.uid,
          'email': email,
          'phone': phone,
          'name': fullName,
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
          'language': language,
          'currency': 'PKR',
          'buyerType': 'individual',
          'province': 'Federal',
          'city': 'Islamabad',
          'avatar': 'https://i.pravatar.cc/150?u=${credential.user!.uid}',
          'profileImageUrl': 'https://i.pravatar.cc/150?u=${credential.user!.uid}',
          'verified': false,
          'addresses': [],
          'savedProducts': [],
          'savedVendors': [],
          'totalOrders': 0,
          'totalReviews': 0,
          'notifications': true,
          'profileSetupComplete': false,
        };
        
        await _db.collection('users').doc(credential.user!.uid).set(newUser);
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // Check role
      final doc = await _db.collection('users').doc(credential.user!.uid).get();
      if (doc.exists && doc.data()!['role'] != 'customer') {
        await _auth.signOut();
        throw 'Access denied. This account is not a customer.';
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  bool isProductSaved(String productId) => _user?.savedProducts.contains(productId) ?? false;
  bool isVendorSaved(String vendorId) => _user?.savedVendors.contains(vendorId) ?? false;

  void toggleSaveProduct(String productId) async {
    if (_user == null) return;
    
    final contains = _user!.savedProducts.contains(productId);
    if (contains) {
      _user!.savedProducts.remove(productId);
      await _db.collection('users').doc(_user!.id).update({
        'savedProducts': FieldValue.arrayRemove([productId])
      });
    } else {
      _user!.savedProducts.add(productId);
      await _db.collection('users').doc(_user!.id).update({
        'savedProducts': FieldValue.arrayUnion([productId])
      });
    }
    notifyListeners();
  }

  void toggleSaveVendor(String vendorId) async {
    if (_user == null) return;

    final contains = _user!.savedVendors.contains(vendorId);
    if (contains) {
      _user!.savedVendors.remove(vendorId);
      await _db.collection('users').doc(_user!.id).update({
        'savedVendors': FieldValue.arrayRemove([vendorId])
      });
    } else {
      _user!.savedVendors.add(vendorId);
      await _db.collection('users').doc(_user!.id).update({
        'savedVendors': FieldValue.arrayUnion([vendorId])
      });
    }
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? buyerType,
    String? province,
    String? city,
    String? profileImageUrl,
    bool? profileSetupComplete,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (phone != null) updates['phone'] = phone;
    if (buyerType != null) updates['buyerType'] = buyerType;
    if (province != null) updates['province'] = province;
    if (city != null) updates['city'] = city;
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
    if (profileSetupComplete != null) updates['profileSetupComplete'] = profileSetupComplete;

    if (updates.isNotEmpty) {
      final docRef = _db.collection('users').doc(uid);
      final docSnap = await docRef.get();
      
      if (docSnap.exists) {
        await docRef.update(updates);
      } else {
        // Create new document if it doesn't exist
        final newUser = {
          'id': uid,
          'name': name ?? '',
          'email': email ?? _auth.currentUser!.email ?? '',
          'phone': _auth.currentUser!.phoneNumber ?? '',
          'buyerType': buyerType ?? 'individual',
          'province': province ?? '',
          'city': city ?? '',
          'profileImageUrl': profileImageUrl ?? _user?.profileImageUrl ?? 'https://ui-avatars.com/api/?name=${(name ?? "User").replaceAll(' ', '+')}',
          'verified': false,
          'savedProducts': [],
          'savedVendors': [],
          'totalOrders': 0,
          'totalReviews': 0,
          'language': 'English',
          'currency': 'PKR',
          'notifications': true,
          'profileSetupComplete': profileSetupComplete ?? false,
          'addresses': [],
        };
        await docRef.set(newUser);
      }

      // Optimistic update: Update local user object immediately to prevent navigation race conditions
      if (_user != null) {
        final data = _user!.toMap();
        updates.forEach((key, value) => data[key] = value);
        _user = AppUser.fromMap(data);
        debugPrint('UserProvider: Optimistic update applied for ${user?.id}');
        notifyListeners();
      } else {
        // If _user was null, we need to fetch it once to be sure state is synced
        final freshSnap = await docRef.get();
        if (freshSnap.exists && freshSnap.data() != null) {
          _user = AppUser.fromMap(freshSnap.data()!);
          notifyListeners();
        }
      }
    }
  }

  Future<void> addAddress(UserAddress address) async {
    if (_user == null) return;
    
    final addrMap = {
      'id': address.id,
      'label': address.label,
      'address': address.address,
      'isDefault': address.isDefault,
    };

    await _db.collection('users').doc(_user!.id).update({
      'addresses': FieldValue.arrayUnion([addrMap])
    });
  }

  Future<void> toggleNotifications() async {
    if (_user == null) return;
    final newValue = !_user!.notifications;
    await _db.collection('users').doc(_user!.id).update({'notifications': newValue});
  }

  List<UserAddress> get addresses => _user?.addresses ?? [];
}
