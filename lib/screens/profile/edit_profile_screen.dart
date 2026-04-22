import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/hunarmand_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  String _buyerType = 'individual';
  String _province = 'Federal';
  String _city = 'Islamabad';
  bool _isLoading = false;
  XFile? _imageFile;
  double _uploadProgress = 0;

  final _provinces = [
    'Punjab',
    'Sindh',
    'KPK',
    'Balochistan',
    'Federal',
    'Azad Kashmir'
  ];
  final _cities = {
    'Punjab': ['Lahore', 'Faisalabad', 'Multan', 'Rawalpindi'],
    'Sindh': ['Karachi', 'Hyderabad'],
    'KPK': ['Peshawar', 'Swat'],
    'Balochistan': ['Quetta'],
    'Federal': ['Islamabad'],
    'Azad Kashmir': ['Muzaffarabad'],
  };

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _buyerType = user?.buyerType ?? 'individual';
    _province = user?.province ?? 'Federal';
    _city = user?.city ?? 'Islamabad';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_imageFile == null) return null;

    try {
      final ref =
          FirebaseStorage.instance.ref().child('users/$userId/profile.jpg');

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(await _imageFile!.readAsBytes());
      } else {
        // Use readAsBytes for cross-platform compatibility without dart:io
        uploadTask = ref.putData(await _imageFile!.readAsBytes());
      }


      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
        });
      });

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cities = _cities[_province] ?? ['Islamabad'];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Picker
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF0D5C2F), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: ClipOval(
                            child: _imageFile != null
                                ? Image.network(_imageFile!.path,
                                    fit: BoxFit.cover)

                                : (user.profileImageUrl.isNotEmpty
                                    ? Image.network(user.profileImageUrl,
                                        fit: BoxFit.cover)
                                    : const Icon(Icons.person,
                                        size: 60, color: AppColors.textLight)),
                          ),
                        ),
                        if (_uploadProgress > 0 && _uploadProgress < 1)
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: _uploadProgress,
                              strokeWidth: 4,
                              color: AppColors.primaryGreen,
                              backgroundColor: Colors.white.withAlpha(100),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0D5C2F),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _pickImage,
                    child: Text('Change Photo',
                        style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Full Name
            Text('Full Name',
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).cardColor,
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Email
            Text('Email',
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).cardColor,
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Phone
            Text('Phone Number',
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).cardColor,
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Province
            Text('Province',
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _province,
              items: _provinces
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() {
                _province = v!;
                _city = _cities[v]!.contains(_city) ? _city : _cities[v]!.first;
              }),
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // City
            Text('City',
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: cities.contains(_city) ? _city : cities.first,
              items: cities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _city = v!),
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Buyer type
            Text('Buyer Type',
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _buyerType,
              items: const [
                DropdownMenuItem(
                    value: 'individual', child: Text('👤 Individual')),
                DropdownMenuItem(
                    value: 'business', child: Text('🏪 Small Business')),
                DropdownMenuItem(
                    value: 'bulk', child: Text('🚢 Bulk/Export Buyer')),
              ],
              onChanged: (v) => setState(() => _buyerType = v!),
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),

            HunarmandButton(
              label: 'Save Changes',
              isLoading: _isLoading,
              onPressed: () async {
                setState(() => _isLoading = true);

                String? newPhotoUrl;
                if (_imageFile != null) {
                  newPhotoUrl = await _uploadImage(user.id);
                }

                if (!context.mounted) return;

                final userProvider = context.read<UserProvider>();
                await userProvider.updateProfile(
                  name: _nameCtrl.text,
                  email: _emailCtrl.text,
                  phone: _phoneCtrl.text,
                  buyerType: _buyerType,
                  province: _province,
                  city: _city,
                  profileImageUrl: newPhotoUrl,
                );

                setState(() => _isLoading = false);

                if (!context.mounted) return;
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Profile updated!'),
                      backgroundColor: AppColors.primaryGreen),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
