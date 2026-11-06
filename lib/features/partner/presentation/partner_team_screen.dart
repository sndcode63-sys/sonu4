import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../features/partner/controllers/partner_home_controller.dart';
import '../../../features/partner/models/partner_models.dart';
import 'partner_bottom_sheets.dart';

import 'widgets/partner_ui.dart';
class PartnerTeamScreen extends StatefulWidget {
  const PartnerTeamScreen({super.key});

  @override
  State<PartnerTeamScreen> createState() => _PartnerTeamScreenState();
}

class _PartnerTeamScreenState extends State<PartnerTeamScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _credits = TextEditingController(text: '250');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ensurePartnerHomeController().loadTeam();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _credits.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      PartnerTheme(child: Builder(builder: _partnerBody));

  Widget _partnerBody(BuildContext context) {
    final c = ensurePartnerHomeController();

    return Scaffold(
      backgroundColor: PartnerColors.canvas,
      appBar: AppBar(
        shape: const Border(bottom: BorderSide(color: PartnerColors.line)),
        title: const Text('Team Members'),
        backgroundColor: Colors.white,
        foregroundColor: PartnerColors.ink,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.white,
      ),
      body: Obx(() {
        if (!c.isTeamOwner.value) {
          return const Center(
            child: Text('Team management is available for agency owners.'),
          );
        }
        return RefreshIndicator(
          onRefresh: c.loadTeam,
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              Text('Verified members',
                  style: TextStyle(
                      fontSize: 15.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              if (c.teamLoading.value)
                const Center(child: CircularProgressIndicator())
              else if (c.teamMembers.isEmpty)
                Text('No verified members yet',
                    style: TextStyle(color: PartnerColors.textSecondary))
              else
                ...c.teamMembers.map((m) {
                  final id = asString(m['_id']) ?? asString(m['id']) ?? '';
                  final name = asString(m['name']) ?? 'Member';
                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),

                    ),
                    elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.white,
                    margin: EdgeInsets.only(bottom: 8.h),
                    child: ListTile(
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(asString(m['email']) ??
                          asString(m['phone']) ??
                          ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF0A5C4A)),
                        onPressed: () async {
                          final credits =
                              int.tryParse(_credits.text.trim()) ?? 250;
                          await c.allocateCreditsToMember(
                            memberId: id,
                            credits: credits,
                          );
                        },
                      ),
                    ),
                  );
                }),
              SizedBox(height: 16.h),
              Text('Allocate amount (credits)',
                  style: TextStyle(fontSize: 12.sp)),
              TextField(
                controller: _credits,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: '250',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFF0A5C4A)),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text('Add Sub-Agent',
                  style: TextStyle(
                      fontSize: 15.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: 'Name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFF0A5C4A)),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _email,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFF0A5C4A)),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _phone,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFF0A5C4A)),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: () => c.addSubAgent({
                  'name': _name.text.trim(),
                  'email': _email.text.trim(),
                  'phone': _phone.text.trim(),
                  'privacyConsent': true,
                  'teamRole': 'subagent',
                  'business': '',
                  'location': '',
                  'rera': '',
                  'identityDocuments': '',
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A5C4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                child: const Text('Invite Sub-Agent'),
              ),
              SizedBox(height: 20.h),
              Text('Team properties',
                  style: TextStyle(
                      fontSize: 15.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              if (c.teamProperties.isEmpty)
                Text('No team properties',
                    style: TextStyle(color: PartnerColors.textSecondary))
              else
                ...c.teamProperties.map((p) => Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
  
                      ),
                      elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.white,
                      margin: EdgeInsets.only(bottom: 8.h),
                      child: ListTile(
                        title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(p.status),
                        trailing: TextButton(
                          onPressed: () => showDelegatePropertySheet(context, property: p),
                          child: const Text('Delegate / Assign', style: TextStyle(color: Color(0xFF0A5C4A))),
                        ),
                      ),
                    )),
            ],
          ),
        );
      }),
    );
  }
}
