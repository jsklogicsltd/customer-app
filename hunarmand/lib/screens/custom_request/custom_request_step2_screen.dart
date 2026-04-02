import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/custom_request_provider.dart';
import '../../widgets/common/hunarmand_button.dart';

class CustomRequestStep2Screen extends StatefulWidget {
  const CustomRequestStep2Screen({super.key});

  @override
  State<CustomRequestStep2Screen> createState() => _CustomRequestStep2ScreenState();
}

class _CustomRequestStep2ScreenState extends State<CustomRequestStep2Screen> {
  int _quantity = 1;
  final List<String> _selectedSizes = [];
  final _colorCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _featuresCtrl = TextEditingController();

  final List<String> _sizeOptions = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'Custom'];

  @override
  void initState() {
    super.initState();
    final p = context.read<CustomRequestProvider>();
    _quantity = p.step2Quantity;
    _selectedSizes.addAll(p.step2Sizes);
    _colorCtrl.text = p.step2Color;
    _materialCtrl.text = p.step2Material;
    _featuresCtrl.text = p.step2SpecialFeatures;
  }

  @override
  void dispose() {
    _colorCtrl.dispose();
    _materialCtrl.dispose();
    _featuresCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Specifications'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const _ProgressBar(step: 2, total: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Product Specifications', style: AppTypography.h2),
                  const SizedBox(height: 6),
                  Text(
                    'Step 2 of 4: Tell us about your requirements',
                    style: AppTypography.small.copyWith(color: AppColors.textMedium),
                  ),
                  const SizedBox(height: 24),

                  // ── Quantity ───────────────────────────────────────────
                  _SectionLabel('Quantity'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.primaryGreen,
                      ),
                      Container(
                        width: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '$_quantity',
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Sizes ──────────────────────────────────────────────
                  _SectionLabel('Sizes (select all that apply)'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sizeOptions.map((size) {
                      final selected = _selectedSizes.contains(size);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected) {
                            _selectedSizes.remove(size);
                          } else {
                            _selectedSizes.add(size);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primaryGreen
                                : Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primaryGreen
                                  : AppColors.divider,
                            ),
                          ),
                          child: Text(
                            size,
                            style: AppTypography.small.copyWith(
                              color:
                                  selected ? Colors.white : AppColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Color ──────────────────────────────────────────────
                  _SectionLabel('Preferred Color'),
                  TextFormField(
                    controller: _colorCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Navy Blue, Ivory White...',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Material ───────────────────────────────────────────
                  _SectionLabel('Material / Fabric'),
                  TextFormField(
                    controller: _materialCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Pure Cotton, Silk, Lawn...',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Special Features ───────────────────────────────────
                  _SectionLabel('Special Features (optional)'),
                  TextFormField(
                    controller: _featuresCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Embroidery, custom buttons, specific cut...',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('← Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: HunarmandButton(
                    label: 'Next: Budget →',
                    onPressed: () {
                      final p = context.read<CustomRequestProvider>();
                      p.step2Quantity = _quantity;
                      p.step2Sizes = List.from(_selectedSizes);
                      p.step2Color = _colorCtrl.text.trim();
                      p.step2Material = _materialCtrl.text.trim();
                      p.step2SpecialFeatures = _featuresCtrl.text.trim();
                      context.push('/custom-request/step3');
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
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
            style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: step / total,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2E7D32)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
