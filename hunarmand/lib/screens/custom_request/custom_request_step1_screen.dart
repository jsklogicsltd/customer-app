import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/custom_request_provider.dart';
import '../../data/mock/mock_categories.dart';
import '../../widgets/common/hunarmand_button.dart';

class CustomRequestStep1Screen extends StatefulWidget {
  const CustomRequestStep1Screen({super.key});

  @override
  State<CustomRequestStep1Screen> createState() =>
      _CustomRequestStep1ScreenState();
}

class _CustomRequestStep1ScreenState extends State<CustomRequestStep1Screen> {
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedProductType;
  final _descCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _pickedImages = [];

  List<Map<String, dynamic>> get _subCategories {
    if (_selectedCategory == null) return [];
    final cat = mockCategoriesHierarchy.firstWhere(
      (c) => c['name'] == _selectedCategory,
      orElse: () => {},
    );
    if (cat.isEmpty) return [];
    return List<Map<String, dynamic>>.from(cat['subCategories'] as List);
  }

  List<String> get _productTypes {
    if (_selectedSubCategory == null) return [];
    final sub = _subCategories.firstWhere(
      (s) => s['name'] == _selectedSubCategory,
      orElse: () => {},
    );
    if (sub.isEmpty) return [];
    return List<String>.from(sub['productTypes'] as List);
  }

  @override
  void initState() {
    super.initState();
    final provider = context.read<CustomRequestProvider>();
    if (provider.step1Category.isNotEmpty) {
      _selectedCategory = provider.step1Category;
    }
    if (provider.step1SubCategory.isNotEmpty) {
      _selectedSubCategory = provider.step1SubCategory;
    }
    if (provider.step1ProductType.isNotEmpty) {
      _selectedProductType = provider.step1ProductType;
    }
    _descCtrl.text = provider.step1Description;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String? value) {
    setState(() {
      _selectedCategory = value;
      _selectedSubCategory = null;
      _selectedProductType = null;
    });
  }

  void _onSubCategoryChanged(String? value) {
    setState(() {
      _selectedSubCategory = value;
      _selectedProductType = null;
    });
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) setState(() => _pickedImages.add(image));
  }

  Widget _levelCheck(bool done) {
    return done
        ? const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.check_circle_rounded,
                color: AppColors.primaryGreen, size: 18),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selectedCategory != null &&
        _selectedSubCategory != null &&
        _selectedProductType != null;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Create Custom Request'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const _ProgressBar(step: 1, total: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What product do you need?', style: AppTypography.h2),
                  const SizedBox(height: 6),
                  Text(
                    'Step 1 of 4: Product Selection',
                    style: AppTypography.small
                        .copyWith(color: AppColors.textMedium),
                  ),
                  const SizedBox(height: 20),

                  // ── Dropdown 1: Category ───────────────────────────────
                  Row(
                    children: [
                      Text('Category',
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      _levelCheck(_selectedCategory != null),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    hint: const Text('Select a category...'),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: mockCategoriesHierarchy
                        .map((c) => DropdownMenuItem(
                              value: c['name'] as String,
                              child: Row(
                                children: [
                                  Text(c['icon'] as String,
                                      style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(c['name'] as String),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: _onCategoryChanged,
                  ),

                  // ── Dropdown 2: Sub-Category ───────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text('Sub-Category',
                              style: AppTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600)),
                          _levelCheck(_selectedSubCategory != null),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedSubCategory,
                        hint: const Text('Select sub-category...'),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _selectedCategory == null
                            ? null
                            : _subCategories
                                .map((s) => DropdownMenuItem(
                                      value: s['name'] as String,
                                      child: Text(s['name'] as String),
                                    ))
                                .toList(),
                        onChanged: _selectedCategory == null ? null : _onSubCategoryChanged,
                      ),
                    ],
                  ),

                  // ── Dropdown 3: Product Type ───────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text('Product Type',
                              style: AppTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600)),
                          _levelCheck(_selectedProductType != null),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(20),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                  color: Colors.red.withAlpha(80)),
                            ),
                            child: Text('Required',
                                style: AppTypography.caption.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedProductType,
                        hint: const Text('Select product type...'),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _selectedSubCategory == null
                            ? null
                            : _productTypes
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ))
                                .toList(),
                        onChanged: _selectedSubCategory == null
                            ? null
                            : (v) => setState(() => _selectedProductType = v),
                      ),
                    ],
                  ),

                  // ── Description (Optional) ────────────────────────────
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Add more details',
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withAlpha(18),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text('Optional',
                            style: AppTypography.caption.copyWith(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _descCtrl,
                    builder: (_, val, __) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 4,
                            maxLength: 300,
                            decoration: const InputDecoration(
                              counterText: '',
                              hintText:
                                  'e.g. fabric preference, specific style, color idea…',
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${val.text.length}/300',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.textLight),
                          ),
                        ],
                      );
                    },
                  ),

                  // ── Reference Images ──────────────────────────────────
                  const SizedBox(height: 20),
                  Text('Reference Images',
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Upload photos to help us understand your requirement',
                      style: AppTypography.small
                          .copyWith(color: AppColors.textMedium)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate_outlined,
                                    color: AppColors.textMedium),
                                const SizedBox(height: 4),
                                Text('Add Photo',
                                    style: AppTypography.small
                                        .copyWith(color: AppColors.textMedium)),
                              ],
                            ),
                          ),
                        ),
                        ..._pickedImages.map((f) => Stack(
                              children: [
                                Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: FileImage(File(f.path)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 14,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _pickedImages.remove(f)),
                                    child: const CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.red,
                                      child: Icon(Icons.close,
                                          size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: HunarmandButton(
              label: 'Next: Specifications →',
              onPressed: canContinue
                  ? () {
                      final p = context.read<CustomRequestProvider>();
                      p.step1Category = _selectedCategory!;
                      p.step1SubCategory = _selectedSubCategory!;
                      p.step1ProductType = _selectedProductType!;
                      p.step1Description = _descCtrl.text.trim();
                      p.step1Images = _pickedImages.map((f) => f.path).toList();
                      context.push('/custom-request/step2');
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step, total;
  const _ProgressBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $step of $total',
            style: AppTypography.small.copyWith(color: AppColors.textMedium),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: step / total,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryGreen),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
