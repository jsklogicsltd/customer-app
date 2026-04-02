import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'pending':
        return AppColors.statusPending;
      case 'confirmed':
        return AppColors.statusDelivered;
      case 'in_production':
        return AppColors.statusProduction;
      case 'dispatched':
        return AppColors.statusDispatched;
      case 'delivered':
        return AppColors.statusActive;
      case 'cancelled':
        return AppColors.statusCancelled;
      case 'quotes_received':
        return AppColors.gold;
      case 'completed':
        return AppColors.primaryGreen;
      case 'new':
        return AppColors.primaryGreenLight;
      default:
        return AppColors.textLight;
    }
  }

  String get _label {
    switch (status) {
      case 'in_production':
        return 'In Production';
      case 'quotes_received':
        return 'Quotes Received';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withAlpha(25),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _color.withAlpha(100)),
      ),
      child: Text(
        _label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
