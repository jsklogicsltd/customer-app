import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'pending':
      case 'pending-approval':
        return AppColors.statusPending;
      case 'approved':
      case 'vendor-notified':
        return Colors.blue;
      case 'quote-submitted':
        return Colors.cyan;
      case 'quote-sent-to-customer':
        return AppColors.gold;
      case 'confirmed':
      case 'customer-confirmed':
        return AppColors.primaryGreen;
      case 'in_production':
      case 'in-production':
        return AppColors.statusProduction;
      case 'ready-to-ship':
        return Colors.indigo;
      case 'dispatched':
        return AppColors.statusDispatched;
      case 'delivered':
        return AppColors.statusActive;
      case 'cancelled':
      case 'quote-declined':
        return AppColors.statusCancelled;
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
      case 'pending-approval':
        return 'Pending Approval';
      case 'vendor-notified':
        return 'Vendor Notified';
      case 'quote-submitted':
        return 'Quote Submitted';
      case 'quote-sent-to-customer':
        return 'Quote Received';
      case 'customer-confirmed':
        return 'Confirmed';
      case 'in_production':
      case 'in-production':
        return 'In Production';
      case 'ready-to-ship':
        return 'Ready to Ship';
      default:
        return status.split('-').map((s) {
          if (s.isEmpty) return '';
          return s[0].toUpperCase() + s.substring(1).toLowerCase();
        }).join(' ');
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
