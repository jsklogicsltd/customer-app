import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/custom_request_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/hunarmand_button.dart';
import '../../widgets/custom_request/custom_request_shared_widgets.dart';

class CustomRequestStep4Screen extends StatefulWidget {
  const CustomRequestStep4Screen({super.key});

  @override
  State<CustomRequestStep4Screen> createState() => _CustomRequestStep4ScreenState();
}

class _CustomRequestStep4ScreenState extends State<CustomRequestStep4Screen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _colorCtrl;
  late TextEditingController _materialCtrl;
  late TextEditingController _budgetMinCtrl;
  late TextEditingController _budgetMaxCtrl;
  late TextEditingController _deadlineCtrl;
  
  // Custom Measurements Controllers
  late TextEditingController _homeLengthCtrl;
  late TextEditingController _homeWidthCtrl;
  late TextEditingController _shirtLengthCtrl;
  late TextEditingController _shoulderCtrl;
  late TextEditingController _chestCtrl;
  late TextEditingController _waistCtrl;
  late TextEditingController _sleevesCtrl;

  int _quantity = 1;
  final List<String> _selectedSizes = [];
  String _deliveryType = 'domestic';
  String _packaging = 'standard';
  final List<XFile> _pickedImages = [];
  final ImagePicker _picker = ImagePicker();

  bool _isCustomSize = false;
  final List<String> _sizeOptions = ['S', 'M', 'L', 'XL', 'XXL', 'Custom'];
  String _selectedMaterialChip = 'Cotton';
  static const _standardMaterials = ['Lawn', 'Cotton', 'Linen', 'Silk', 'Chiffon', 'Khaddar', 'Denim', 'Wool'];

  @override
  void initState() {
    super.initState();
    final p = context.read<CustomRequestProvider>();
    _nameCtrl = TextEditingController(text: p.step1ProductType);
    _descCtrl = TextEditingController(text: p.step1Description);
    _colorCtrl = TextEditingController(text: p.step2Color);
    _materialCtrl = TextEditingController(text: p.step2Material);
    _budgetMinCtrl = TextEditingController(text: p.step3BudgetMin > 0 ? p.step3BudgetMin.toString() : '');
    _budgetMaxCtrl = TextEditingController(text: p.step3BudgetMax > 0 ? p.step3BudgetMax.toString() : '');
    _deadlineCtrl = TextEditingController(text: p.step3Deadline);
    
    _homeLengthCtrl = TextEditingController();
    _homeWidthCtrl = TextEditingController();
    _shirtLengthCtrl = TextEditingController();
    _shoulderCtrl = TextEditingController();
    _chestCtrl = TextEditingController();
    _waistCtrl = TextEditingController();
    _sleevesCtrl = TextEditingController();

    _quantity = p.step2Quantity;
    _selectedSizes.addAll(p.step2Sizes);
    _isCustomSize = _selectedSizes.contains('Custom');
    _packaging = p.step3Packaging;
    _pickedImages.addAll(p.step1Images);
    
    if (_materialCtrl.text.isEmpty) {
      _selectedMaterialChip = 'Cotton';
      _materialCtrl.text = 'Cotton';
    } else if (_standardMaterials.contains(_materialCtrl.text)) {
      _selectedMaterialChip = _materialCtrl.text;
    } else {
      _selectedMaterialChip = 'Other';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _colorCtrl.dispose();
    _materialCtrl.dispose();
    _budgetMinCtrl.dispose();
    _budgetMaxCtrl.dispose();
    _deadlineCtrl.dispose();
    _homeLengthCtrl.dispose();
    _homeWidthCtrl.dispose();
    _shirtLengthCtrl.dispose();
    _shoulderCtrl.dispose();
    _chestCtrl.dispose();
    _waistCtrl.dispose();
    _sleevesCtrl.dispose();
    super.dispose();
  }

  bool get _isHomeTextile {
    final p = context.read<CustomRequestProvider>();
    final cat = p.step1Category.toLowerCase();
    final sub = p.step1SubCategory.toLowerCase();
    return cat.contains('home') || sub.contains('home');
  }

  void _showMeasurementGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.straighten, color: AppColors.primaryGreen),
                        const SizedBox(width: 12),
                        Text('Measurement Guide', style: AppTypography.h2),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_isHomeTextile) ...[
                      _guideStep('1', 'Use a Measuring Tape', 'Always use a flexible measuring tape for Home Textile.'),
                      _guideStep('2', 'Measure Width First', 'Measure the total width of the area (e.g. window or bed).'),
                      _guideStep('3', 'Measure Length/Height', 'Measure from top to bottom where you want the fabric to end.'),
                      _guideStep('4', 'Allow for Foldings', 'Keep 2-3 inches extra for stitching folds.'),
                    ] else ...[
                      _guideStep('1', 'Find a Good Fit', 'Take your best-fitting garment and lay it flat on a table.'),
                      _guideStep('2', 'Chest Measurement', 'Measure from one armhole to the other across the front.'),
                      _guideStep('3', 'Shoulder (Teera)', 'Measure from one shoulder seam to the other.'),
                      _guideStep('4', 'Length (Lambai)', 'Measure from the highest point of the shoulder to the bottom.'),
                      _guideStep('5', 'Sleeves (Bazu)', 'Measure from the shoulder seam to the end of the sleeve.'),
                    ],
                    const SizedBox(height: 30),
                    HunarmandButton(label: 'Got it!', onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideStep(String num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 12, backgroundColor: AppColors.primaryGreen, child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                Text(desc, style: AppTypography.small.copyWith(color: AppColors.textMedium)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) setState(() => _pickedImages.add(image));
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;

    final p = context.read<CustomRequestProvider>();

    p.step1ProductName = _nameCtrl.text.trim();
    p.step1Description = _descCtrl.text.trim();
    p.step1Images = _pickedImages;
    p.step2Quantity = _quantity;
    p.step2Sizes = _selectedSizes;
    p.step2Color = _colorCtrl.text.trim();
    p.step2Material = _materialCtrl.text.trim();
    p.step3BudgetMin = int.tryParse(_budgetMinCtrl.text) ?? 0;
    p.step3BudgetMax = int.tryParse(_budgetMaxCtrl.text) ?? 0;
    p.step3Deadline = _deadlineCtrl.text.trim();
    p.step3DeliveryType = _deliveryType;
    p.step3Packaging = _packaging;

    // Save Measurements
    p.step4HomeLength = _homeLengthCtrl.text.trim();
    p.step4HomeWidth = _homeWidthCtrl.text.trim();
    p.step4CustomMeasurements = {
      if (_shirtLengthCtrl.text.isNotEmpty) 'Length': _shirtLengthCtrl.text.trim(),
      if (_shoulderCtrl.text.isNotEmpty) 'Shoulder': _shoulderCtrl.text.trim(),
      if (_chestCtrl.text.isNotEmpty) 'Chest': _chestCtrl.text.trim(),
      if (_waistCtrl.text.isNotEmpty) 'Waist': _waistCtrl.text.trim(),
      if (_sleevesCtrl.text.isNotEmpty) 'Sleeves': _sleevesCtrl.text.trim(),
    };

    context.push('/custom-request/step5');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Final Details'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            CustomRequestStepper(
              currentStep: 4,
              onStepTap: (step) {
                if (step == 1) {
                  context.pop();
                  context.pop();
                  context.pop();
                } else if (step == 2) {
                  context.pop();
                  context.pop();
                } else if (step == 3) {
                  context.pop();
                }
              },
            ),
            SelectionSummaryCard(
              category: context.read<CustomRequestProvider>().step1Category,
              subCategory: context.read<CustomRequestProvider>().step1SubCategory,
              productType: context.read<CustomRequestProvider>().step1ProductType,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Almost there!', style: AppTypography.h2),
                    const SizedBox(height: 4),
                    Text('Provide the final details to get the best quotes.', style: AppTypography.small.copyWith(color: AppColors.textMedium)),
                    const SizedBox(height: 24),

                    _sectionTitle('Product Overview'),
                    _label('Request Title'),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Handmade Silk Kurti with Embroidery',
                        prefixIcon: Icon(Icons.edit_note, size: 20),
                      ),
                      validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 20),
                    _label('Note for Artisan (Requirements)'),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe your dream product... (e.g. pattern, specific embroidery color, etc.)',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Reference Photos'),
                    _ImagePickerGrid(images: _pickedImages, onAdd: _pickImage, onRemove: (i) => setState(() => _pickedImages.removeAt(i))),

                    const SizedBox(height: 32),
                    _sectionTitle('Custom Specifications'),
                    _label('Material Preference'),
                    _MaterialChips(
                      selected: _selectedMaterialChip,
                      onSelected: (m) {
                        setState(() {
                          _selectedMaterialChip = m;
                          if (m != 'Other') {
                            _materialCtrl.text = m;
                          } else {
                            // Clear if switching to other, or keep previous? 
                            // Let's clear so user can type fresh.
                            _materialCtrl.clear();
                          }
                        });
                      },
                    ),
                    if (_selectedMaterialChip == 'Other') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _materialCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Enter your custom material type (e.g. Velvet, Net)...',
                          prefixIcon: Icon(Icons.edit_outlined, size: 20),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Quantity'),
                              _QuantitySelector(
                                quantity: _quantity,
                                onDec: () => setState(() { if(_quantity > 1) _quantity--; }),
                                onInc: () => setState(() => _quantity++),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Primary Color'),
                              TextFormField(
                                controller: _colorCtrl, 
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Emerald Green',
                                  prefixIcon: Icon(Icons.palette_outlined, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 32),
                    _sectionTitle('Measurements'),
                    if (_isHomeTextile) ...[
                      Text('Enter dimensions for Home Textile', style: AppTypography.small.copyWith(color: AppColors.textMedium)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _measurementField(_homeLengthCtrl, 'Length (L)', Icons.height)),
                          const SizedBox(width: 12),
                          Expanded(child: _measurementField(_homeWidthCtrl, 'Width (W)', Icons.width_full)),
                        ],
                      ),
                    ] else ...[
                      _label('Select Size'),
                      _SizeChips(
                        options: _sizeOptions, 
                        selected: _selectedSizes, 
                        onToggle: (s) {
                          setState(() {
                            if (_selectedSizes.contains(s)) {
                              _selectedSizes.remove(s);
                            } else {
                              _selectedSizes.add(s);
                            }
                            _isCustomSize = _selectedSizes.contains('Custom');
                          });
                        }
                      ),
                      if (_isCustomSize) ...[
                        const SizedBox(height: 20),
                        Text('Enter Custom Measurements (Inches)', style: AppTypography.small.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _measurementField(_shirtLengthCtrl, 'Length', Icons.straighten)),
                            const SizedBox(width: 12),
                            Expanded(child: _measurementField(_shoulderCtrl, 'Shoulder', Icons.square_foot)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _measurementField(_chestCtrl, 'Chest', Icons.settings_overscan)),
                            const SizedBox(width: 12),
                            Expanded(child: _measurementField(_waistCtrl, 'Waist', Icons.line_weight)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _measurementField(_sleevesCtrl, 'Sleeves', Icons.gesture),
                      ],
                    ],
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _showMeasurementGuide,
                      icon: const Icon(Icons.help_outline, size: 16),
                      label: Text('How to measure?', style: AppTypography.small.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),

                    const SizedBox(height: 32),
                    _sectionTitle('Budget & Timeline'),
                    _label('Your Budget Range (PKR)'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _budgetMinCtrl, 
                            keyboardType: TextInputType.number, 
                            decoration: const InputDecoration(
                              hintText: 'Min',
                              prefixText: 'Rs. ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('-', style: TextStyle(color: AppColors.textLight, fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _budgetMaxCtrl, 
                            keyboardType: TextInputType.number, 
                            decoration: const InputDecoration(
                              hintText: 'Max',
                              prefixText: 'Rs. ',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _label('Expected Deadline / Crafting Time'),
                    TextFormField(
                      controller: _deadlineCtrl, 
                      decoration: const InputDecoration(
                        hintText: 'e.g. Within 10 days', 
                        suffixIcon: Icon(Icons.timer_outlined, size: 20),
                        helperText: 'Handmade items usually take 5-7 days.',
                      ),
                    ),

                    const SizedBox(height: 32),
                    _sectionTitle('Delivery & Packaging'),
                    _label('Delivery Preference'),
                    _OptionRow(
                      options: const [
                        {'val': 'domestic', 'label': 'Domestic', 'icon': Icons.local_shipping_outlined},
                        {'val': 'international', 'label': 'International', 'icon': Icons.public},
                      ],
                      selected: _deliveryType,
                      onChanged: (v) => setState(() => _deliveryType = v),
                    ),
                    const SizedBox(height: 16),
                    _label('Packaging'),
                    _OptionRow(
                      options: const [
                        {'val': 'standard', 'label': 'Standard', 'icon': Icons.inventory_2_outlined},
                        {'val': 'premium', 'label': 'Premium', 'icon': Icons.card_giftcard},
                      ],
                      selected: _packaging,
                      onChanged: (v) => setState(() => _packaging = v),
                    ),

                    const SizedBox(height: 40),
                    Consumer<CustomRequestProvider>(
                      builder: (context, p, _) => HunarmandButton(
                        label: 'Review Request',
                        onPressed: _onNext,
                        type: ButtonType.gold,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(width: 4, height: 20, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Text(title, style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTypography.small.copyWith(fontWeight: FontWeight.w600, color: AppColors.textMedium)),
    );
  }

  Widget _measurementField(TextEditingController ctrl, String hint, IconData icon) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _MaterialChips extends StatelessWidget {
  final String selected;
  final Function(String) onSelected;
  const _MaterialChips({required this.selected, required this.onSelected});

  static const _materials = ['Lawn', 'Cotton', 'Linen', 'Silk', 'Chiffon', 'Khaddar', 'Denim', 'Wool', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 0,
      children: _materials.map((m) {
        final isSelected = selected == m;
        return ChoiceChip(
          label: Text(m),
          selected: isSelected,
          onSelected: (_) => onSelected(m),
          selectedColor: AppColors.primaryGreen.withAlpha(40),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primaryGreen : AppColors.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isSelected ? AppColors.primaryGreen : AppColors.divider),
          ),
        );
      }).toList(),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onInc, onDec;
  const _QuantitySelector({required this.quantity, required this.onInc, required this.onDec});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: onDec, icon: const Icon(Icons.remove, size: 16, color: AppColors.primaryGreen)),
          Text('$quantity', style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold)),
          IconButton(onPressed: onInc, icon: const Icon(Icons.add, size: 16, color: AppColors.primaryGreen)),
        ],
      ),
    );
  }
}

class _SizeChips extends StatelessWidget {
  final List<String> options, selected;
  final Function(String) onToggle;
  const _SizeChips({required this.options, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: options.map((s) {
        final isSelected = selected.contains(s);
        return FilterChip(
          label: Text(s),
          selected: isSelected,
          onSelected: (_) => onToggle(s),
          selectedColor: AppColors.primaryGreen.withAlpha(40),
          checkmarkColor: AppColors.primaryGreen,
          labelStyle: TextStyle(color: isSelected ? AppColors.primaryGreen : AppColors.textDark, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? AppColors.primaryGreen : AppColors.divider)),
        );
      }).toList(),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final String selected;
  final Function(String) onChanged;
  const _OptionRow({required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((o) {
        final isSelected = selected == o['val'];
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(o['val']),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppColors.primaryGreen : AppColors.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(o['icon'] as IconData, size: 18, color: isSelected ? Colors.white : AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  Text(o['label'] as String, style: TextStyle(color: isSelected ? Colors.white : AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ImagePickerGrid extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onAdd;
  final Function(int) onRemove;
  const _ImagePickerGrid({required this.images, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length + 1,
        itemBuilder: (context, i) {
          if (i == images.length) {
            return GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 90,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
                child: const Icon(Icons.add_a_photo_outlined, color: AppColors.textLight),
              ),
            );
          }
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(images[i].path),
                fit: BoxFit.cover,
              ),
            ),
          child: Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => onRemove(i),
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        );
      },
    ),
  );
}
}
