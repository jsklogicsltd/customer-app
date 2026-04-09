import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/custom_request_provider.dart';
import '../../widgets/common/hunarmand_button.dart';

class CustomRequestStep3Screen extends StatefulWidget {
  const CustomRequestStep3Screen({super.key});

  @override
  State<CustomRequestStep3Screen> createState() => _CustomRequestStep3ScreenState();
}

class _CustomRequestStep3ScreenState extends State<CustomRequestStep3Screen> {
  RangeValues _budgetRange = const RangeValues(1000, 10000);
  String _deadline = '';
  String _deliveryType = 'domestic';
  String _packaging = 'standard';
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = context.read<CustomRequestProvider>();
    _budgetRange = RangeValues(
      p.step3BudgetMin.toDouble(),
      p.step3BudgetMax.toDouble(),
    );
    if (_budgetRange.start == 0 && _budgetRange.end == 0) {
      _budgetRange = const RangeValues(1000, 10000);
    }
    _deadline = p.step3Deadline;
    _deliveryType = p.step3DeliveryType;
    _packaging = p.step3Packaging;
    _descCtrl.text = p.step1Description;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deadline = DateFormat('dd MMM yyyy').format(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Budget & Requirements'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const _ProgressBar(step: 3, total: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Budget & Requirements', style: AppTypography.h2),
                  const SizedBox(height: 6),
                  Text(
                    'Step 3 of 4: Set your budget and timeline',
                    style: AppTypography.small.copyWith(color: AppColors.textMedium),
                  ),
                  const SizedBox(height: 24),

                  // ── Budget Range ───────────────────────────────────────
                  const _SectionLabel('Budget Range (PKR)'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatPKR(_budgetRange.start.toInt()),
                              style: AppTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              formatPKR(_budgetRange.end.toInt()),
                              style: AppTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: _budgetRange,
                          min: 500,
                          max: 100000,
                          divisions: 199,
                          activeColor: AppColors.primaryGreen,
                          inactiveColor: AppColors.divider,
                          onChanged: (v) => setState(() => _budgetRange = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Deadline ───────────────────────────────────────────
                  const _SectionLabel('Delivery Deadline'),
                  GestureDetector(
                    onTap: _pickDeadline,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              color: AppColors.primaryGreen, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _deadline.isEmpty ? 'Select deadline date' : _deadline,
                            style: AppTypography.bodyMedium.copyWith(
                              color: _deadline.isEmpty
                                  ? AppColors.textLight
                                  : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Delivery Type ──────────────────────────────────────
                  const _SectionLabel('Delivery Type'),
                  Row(
                    children: [
                      _RadioChip(
                        label: '🇵🇰 Domestic',
                        value: 'domestic',
                        groupValue: _deliveryType,
                        onChanged: (v) => setState(() => _deliveryType = v!),
                      ),
                      const SizedBox(width: 10),
                      _RadioChip(
                        label: '🌍 International',
                        value: 'international',
                        groupValue: _deliveryType,
                        onChanged: (v) => setState(() => _deliveryType = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Packaging ──────────────────────────────────────────
                  const _SectionLabel('Packaging Preference'),
                  Row(
                    children: [
                      _RadioChip(
                        label: 'Standard',
                        value: 'standard',
                        groupValue: _packaging,
                        onChanged: (v) => setState(() => _packaging = v!),
                      ),
                      const SizedBox(width: 10),
                      _RadioChip(
                        label: 'Premium',
                        value: 'premium',
                        groupValue: _packaging,
                        onChanged: (v) => setState(() => _packaging = v!),
                      ),
                      const SizedBox(width: 10),
                      _RadioChip(
                        label: 'Gift',
                        value: 'gift',
                        groupValue: _packaging,
                        onChanged: (v) => setState(() => _packaging = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Description ────────────────────────────────────────
                  const _SectionLabel('Additional Notes (optional)'),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Any other requirements or special instructions...',
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
                    label: 'Review & Submit →',
                    onPressed: () {
                      final p = context.read<CustomRequestProvider>();
                      p.step3BudgetMin = _budgetRange.start.toInt();
                      p.step3BudgetMax = _budgetRange.end.toInt();
                      p.step3Deadline = _deadline;
                      p.step3DeliveryType = _deliveryType;
                      p.step3Packaging = _packaging;
                      p.step1Description = _descCtrl.text.trim();
                      context.push('/custom-request/step4');
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

class _RadioChip extends StatelessWidget {
  final String label, value, groupValue;
  final ValueChanged<String?> onChanged;
  const _RadioChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.small.copyWith(
            color: selected ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
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
