import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'partner_ui.dart';
/// Configurable slab model for Admin panel / dynamic backend integration.
class SuccessFeeSlab {
  final double min;
  final double max;
  final double percentage; // e.g. 0.25 for 0.25%
  final String label;

  const SuccessFeeSlab({
    required this.min,
    required this.max,
    required this.percentage,
    required this.label,
  });
}

/// DigiNiwas Deal Success Fee Calculator Widget
///
/// Implements fixed success fee slabs:
/// • Up to ₹50 Lakh: 0.25%
/// • Above ₹50 Lakh to ₹1 Crore: 0.20%
/// • Above ₹1 Crore: 0.18%
/// (Applies to entire deal value, based on slab, not progressively)
///
/// Formula:
/// • Agent Brokerage = Deal Value × Brokerage %
/// • Success Fee = Deal Value × Applicable Success Fee %
/// • Remaining Success Fee = Total Success Fee - Already Paid Credits
/// • ₹1 = 1 DigiCredit
class DealSuccessFeeCalculatorWidget extends StatefulWidget {
  final List<SuccessFeeSlab>? customSlabs;
  final bool isStandaloneCard;

  const DealSuccessFeeCalculatorWidget({
    super.key,
    this.customSlabs,
    this.isStandaloneCard = true,
  });

  @override
  State<DealSuccessFeeCalculatorWidget> createState() =>
      _DealSuccessFeeCalculatorWidgetState();
}

class _DealSuccessFeeCalculatorWidgetState
    extends State<DealSuccessFeeCalculatorWidget> {
  // Brand colors
  static const Color _navy = Color(0xFF0B1B2E);
  static const Color _primaryTeal = Color(0xFF0A5C4A);
  static const Color _softGreen = Color(0xFFE8F3EF);
  static const Color _emerald = Color(0xFF129B6C);
  static const Color _gold = Color(0xFFD9961F);
  static const Color _border = Color(0xFFE3E8ED);

  // Controllers
  late final TextEditingController _dealValueCtrl;
  late final TextEditingController _brokeragePctCtrl;
  late final TextEditingController _alreadyPaidCtrl;

  // Active state values
  double _dealValue = 7800000; // Default ₹78,00,000 as per specification
  double _brokeragePct = 1.0;  // Default 1%
  int _alreadyPaidCredits = 149; // Default 149 credits

  // Default slabs as per specification
  late List<SuccessFeeSlab> _slabs;

  final NumberFormat _inrFormatter = NumberFormat('#,##,###', 'en_IN');

  @override
  void initState() {
    super.initState();
    _slabs = widget.customSlabs ??
        const [
          SuccessFeeSlab(
            min: 0,
            max: 5000000,
            percentage: 0.25,
            label: 'Up to ₹50L: 0.25%',
          ),
          SuccessFeeSlab(
            min: 5000000,
            max: 10000000,
            percentage: 0.20,
            label: '₹50L - ₹1Cr: 0.20%',
          ),
          SuccessFeeSlab(
            min: 10000000,
            max: double.infinity,
            percentage: 0.18,
            label: '> ₹1Cr: 0.18%',
          ),
        ];

    _dealValueCtrl = TextEditingController(text: _formatNumber(_dealValue.toInt()));
    _brokeragePctCtrl = TextEditingController(text: '1.0');
    _alreadyPaidCtrl = TextEditingController(text: '149');
  }

  @override
  void dispose() {
    _dealValueCtrl.dispose();
    _brokeragePctCtrl.dispose();
    _alreadyPaidCtrl.dispose();
    super.dispose();
  }

  String _formatNumber(num val) {
    try {
      return _inrFormatter.format(val);
    } catch (_) {
      return val.toString();
    }
  }

  // Find the slab that applies to the entire deal value
  SuccessFeeSlab _getActiveSlab(double dealValue) {
    for (final s in _slabs) {
      if (dealValue <= s.max && dealValue > s.min) {
        return s;
      }
    }
    return _slabs.first;
  }

  void _onDealValuePreset(double val) {
    setState(() {
      _dealValue = val;
      _dealValueCtrl.text = _formatNumber(val.toInt());
    });
  }

  void _onBrokeragePreset(double val) {
    setState(() {
      _brokeragePct = val;
      _brokeragePctCtrl.text = val.toStringAsFixed(1);
    });
  }

  void _onAlreadyPaidPreset(int val) {
    setState(() {
      _alreadyPaidCredits = val;
      _alreadyPaidCtrl.text = val.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Determine active slab & percentage
    final activeSlab = _getActiveSlab(_dealValue);
    final double successFeeRate = activeSlab.percentage;

    // 2. Calculations
    final double agentBrokerage = _dealValue * (_brokeragePct / 100.0);
    final double totalSuccessFeeInr = _dealValue * (successFeeRate / 100.0);
    final int totalSuccessFeeCredits = totalSuccessFeeInr.round(); // ₹1 = 1 DigiCredit
    final int remainingCredits = (totalSuccessFeeCredits - _alreadyPaidCredits).clamp(0, totalSuccessFeeCredits);
    final double netAgentTakeHome = (agentBrokerage - totalSuccessFeeInr).clamp(0.0, double.infinity);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(9.w),
              decoration: BoxDecoration(
                color: _softGreen,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.calculate_rounded, color: _primaryTeal, size: 22.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deal Success Fee Calculator',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Estimate brokerage earnings and DigiNiwas success fee',
                    style: TextStyle(fontSize: 10.5.sp, color: PartnerColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // 1. Slabs Overview Badge Row
        Text(
          '1. Fixed Success Fee Slabs',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
        SizedBox(height: 6.h),
        Row(
          children: _slabs.map((slab) {
            final isActive = slab == activeSlab;
            return Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                decoration: BoxDecoration(
                  color: isActive ? _softGreen : const Color(0xFFF6F8FA),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isActive ? _primaryTeal : _border,
                    width: isActive ? 1.4 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    if (isActive)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 11.sp, color: _primaryTeal),
                          SizedBox(width: 3.w),
                          Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w800,
                              color: _primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    Text(
                      slab.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5.sp,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                        color: isActive ? _primaryTeal : const Color(0xFF4B5B6C),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        SizedBox(height: 16.h),

        // 2. Property Deal Value Input
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Property Deal Value',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: _navy),
            ),
            Text(
              '₹ ${_formatNumber(_dealValue.toInt())}',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: _primaryTeal,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: _dealValueCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Center(
                widthFactor: 0.0,
                child: Text('₹', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: _primaryTeal)),
              ),
            ),
            hintText: 'Enter property deal amount',
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            filled: true,
            fillColor: const Color(0xFFF6F8FA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: _primaryTeal, width: 1.5)),
          ),
          onChanged: (val) {
            final parsed = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
            setState(() {
              _dealValue = parsed;
            });
          },
        ),

        SizedBox(height: 6.h),
        // Quick Presets for Deal Value
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: [
              _presetChip('₹35L', 3500000, _dealValue == 3500000),
              _presetChip('₹50L', 5000000, _dealValue == 5000000),
              _presetChip('₹78L (Example)', 7800000, _dealValue == 7800000),
              _presetChip('₹1 Crore', 10000000, _dealValue == 10000000),
              _presetChip('₹2.5 Crore', 25000000, _dealValue == 25000000),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // 3. Brokerage Percentage & Already Paid Row
        Row(
          children: [
            // Brokerage Percentage Field
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Brokerage %', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: _navy)),
                      Text('${_brokeragePct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold, color: _emerald)),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _brokeragePctCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      suffixText: '%',
                      suffixStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: _emerald),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      filled: true,
                      fillColor: const Color(0xFFF6F8FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: _border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: _primaryTeal)),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 1.0;
                      setState(() {
                        _brokeragePct = parsed.clamp(0.1, 10.0);
                      });
                    },
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      _smallChip('1%', 1.0, _brokeragePct == 1.0, _onBrokeragePreset),
                      _smallChip('1.5%', 1.5, _brokeragePct == 1.5, _onBrokeragePreset),
                      _smallChip('2%', 2.0, _brokeragePct == 2.0, _onBrokeragePreset),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            // Already Paid Credits Field
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Already Paid', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: _navy)),
                      Text('$_alreadyPaidCredits Cr', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold, color: _gold)),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _alreadyPaidCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      suffixText: 'Credits',
                      suffixStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: _gold),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      filled: true,
                      fillColor: const Color(0xFFF6F8FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: _border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: _primaryTeal)),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val) ?? 0;
                      setState(() {
                        _alreadyPaidCredits = parsed;
                      });
                    },
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      _smallIntChip('0 Cr', 0, _alreadyPaidCredits == 0, _onAlreadyPaidPreset),
                      _smallIntChip('149 Cr', 149, _alreadyPaidCredits == 149, _onAlreadyPaidPreset),
                      _smallIntChip('250 Cr', 250, _alreadyPaidCredits == 250, _onAlreadyPaidPreset),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 18.h),

        // 4. Detailed Calculation Breakdown Card
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1B2E), // DigiNiwas Dark Navy Theme
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1B2E).withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CALCULATION BREAKDOWN',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF8493A3),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF129B6C).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'Rate: ${successFeeRate.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF34D399),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Item 1: Agent Brokerage
              _breakdownRow(
                label: 'Agent Brokerage (${_brokeragePct.toStringAsFixed(1)}%):',
                value: '₹ ${_formatNumber(agentBrokerage.round())}',
                valueColor: Colors.white,
              ),
              SizedBox(height: 8.h),

              // Item 2: DigiNiwas Success Fee Rate
              _breakdownRow(
                label: 'DigiNiwas Success Fee Rate:',
                value: '${successFeeRate.toStringAsFixed(2)}%',
                valueColor: const Color(0xFF6FD8BD),
              ),
              SizedBox(height: 8.h),

              // Item 3: Total Success Fee in DigiCredits
              _breakdownRow(
                label: 'Total Success Fee:',
                value: '${_formatNumber(totalSuccessFeeCredits)} DigiCredits',
                valueColor: const Color(0xFFFDE047),
              ),
              SizedBox(height: 8.h),

              // Item 4: Already Paid Credit Offset
              _breakdownRow(
                label: 'Already Paid Credits (Deduction):',
                value: '- ${_formatNumber(_alreadyPaidCredits)} DigiCredits',
                valueColor: const Color(0xFF8493A3),
              ),

              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
              ),

              // Big Highlight: Remaining Success Fee
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFF6FD8BD).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remaining to Pay:',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            'Payable upon deal closing',
                            style: TextStyle(fontSize: 9.sp, color: Colors.white38),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${_formatNumber(remainingCredits)} DigiCredits',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF34D399),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8.h),

              // Net Take-Home Brokerage Earning
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Your Net Earning (Take-Home):',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '₹ ${_formatNumber(netAgentTakeHome.round())}',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // 5. Important Compliance & Billing Notice Box
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: const Color(0xFFB7791F), size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Important: This is a calculation/estimate screen. No credits should be deducted automatically. Payment happens only after the deal is successfully completed and confirmed.',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    color: const Color(0xFF92400E),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!widget.isStandaloneCard) return content;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0C0B1B2E),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0x04000000),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _breakdownRow({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 11.5.sp, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          value,
          style: TextStyle(fontSize: 12.sp, color: valueColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _presetChip(String label, double val, bool isSelected) {
    return GestureDetector(
      onTap: () => _onDealValuePreset(val),
      child: Container(
        margin: EdgeInsets.only(right: 6.w, top: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isSelected ? _primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isSelected ? _primaryTeal : const Color(0xFFC9D2DB)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF33475B),
          ),
        ),
      ),
    );
  }

  Widget _smallChip(String label, double val, bool isSelected, Function(double) onSelect) {
    return GestureDetector(
      onTap: () => onSelect(val),
      child: Container(
        margin: EdgeInsets.only(right: 4.w, top: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: isSelected ? _emerald : Colors.white,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: isSelected ? _emerald : _border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF33475B),
          ),
        ),
      ),
    );
  }

  Widget _smallIntChip(String label, int val, bool isSelected, Function(int) onSelect) {
    return GestureDetector(
      onTap: () => onSelect(val),
      child: Container(
        margin: EdgeInsets.only(right: 4.w, top: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: isSelected ? _gold : Colors.white,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: isSelected ? _gold : _border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF33475B),
          ),
        ),
      ),
    );
  }
}
