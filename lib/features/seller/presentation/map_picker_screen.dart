import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/location_service.dart';
import '../../../core/widgets/app_toast.dart';

class _Suggestion {
  final String label;
  final LatLng point;
  _Suggestion(this.label, this.point);
}

class MapPickerScreen extends StatefulWidget {
  final LatLng? initial;
  const MapPickerScreen({super.key, this.initial});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const Color _green = Color(0xFF0B7A4B);
  static const Color _navy = Color(0xFF0F2544);
  static const Color _grey = Color(0xFF64748B);
  static const Color _greenLine = Color(0xFFCBEFE0);
  static const LatLng _default = LatLng(30.3782, 76.7767);

  GoogleMapController? _map;
  late LatLng _picked;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  String _address = 'Fetching address...';
  bool _searching = false;
  bool _locating = false;
  List<_Suggestion> _results = [];

  @override
  void initState() {
    super.initState();
    _picked = widget.initial ?? _default;
    _loadAddress(_picked);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focus.dispose();
    _map?.dispose();
    super.dispose();
  }

  Future<String> _labelFor(LatLng p) async {
    try {
      final list = await Geocoding().placemarkFromCoordinates(p.latitude, p.longitude);
      if (list.isEmpty) return '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
      final pm = list.first;
      final parts = <String>[];
      for (final x in [pm.name, pm.street, pm.subLocality, pm.locality, pm.administrativeArea, pm.postalCode]) {
        final t = (x ?? '').trim();
        if (t.isNotEmpty && !parts.contains(t)) parts.add(t);
      }
      return parts.isEmpty ? 'Unknown location' : parts.join(', ');
    } catch (_) {
      return '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
    }
  }

  Future<void> _loadAddress(LatLng p) async {
    setState(() => _address = 'Fetching address...');
    final a = await _labelFor(p);
    if (mounted && _picked == p) setState(() => _address = a);
  }

  void _select(LatLng p, {bool moveCamera = true}) {
    setState(() {
      _picked = p;
      _results = [];
    });
    _focus.unfocus();
    if (moveCamera) _map?.animateCamera(CameraUpdate.newLatLngZoom(p, 16));
    _loadAddress(p);
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    _focus.unfocus();
    setState(() => _searching = true);
    try {
      final locs = await Geocoding().locationFromAddress(q);
      if (!mounted) return;
      if (locs.isEmpty) {
        AppToast.error(context, 'Location not found. Try a different search.');
        return;
      }
      final list = <_Suggestion>[];
      for (final l in locs.take(5)) {
        final p = LatLng(l.latitude, l.longitude);
        list.add(_Suggestion(await _labelFor(p), p));
      }
      if (!mounted) return;
      _select(list.first.point);
      if (list.length > 1) setState(() => _results = list);
    } catch (_) {
      if (mounted) AppToast.error(context, 'Could not find this location.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _myLocation() async {
    setState(() => _locating = true);
    try {
      final r = await Get.find<LocationService>().getCurrentLocation();
      _select(LatLng(r.latitude, r.longitude));
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _picked, zoom: 15),
            onMapCreated: (c) => _map = c,
            onTap: (p) => _select(p, moveCamera: false),
            markers: {
              Marker(
                markerId: const MarkerId('picked'),
                position: _picked,
                draggable: true,
                onDragEnd: (p) => _select(p, moveCamera: false),
              ),
            },
            padding: EdgeInsets.only(bottom: 170.h),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // ---- Search bar + results (Fixed Alignment & Padding) ----
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: Column(
                children: [
                  Container(
                    height: 52.h,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: _greenLine,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Back
                        InkWell(
                          borderRadius: BorderRadius.circular(20.r),
                          onTap: () => Navigator.pop(context),
                          child: SizedBox(
                            width: 40.w,
                            height: 44.h,
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 20.sp,
                              color: _navy,
                            ),
                          ),
                        ),

                        SizedBox(width: 2.w),

                        // Search Field
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            focusNode: _focus,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _search(),
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              color: _navy,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search area, society, landmark...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 12.5.sp,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),

                        // Search / Loading
                        if (_searching)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: SizedBox(
                              width: 19.sp,
                              height: 19.sp,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: _green,
                              ),
                            ),
                          )
                        else
                          InkWell(
                            borderRadius: BorderRadius.circular(22.r),
                            onTap: _search,
                            child: SizedBox(
                              width: 42.w,
                              height: 44.h,
                              child: Icon(
                                Icons.search_rounded,
                                color: _green,
                                size: 25.sp,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Search Results
                  if (_results.length > 1)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: _greenLine,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Column(
                          children: [
                            for (int i = 0; i < _results.length; i++) ...[
                              ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 2.h,
                                ),
                                dense: true,
                                minLeadingWidth: 30.w,

                                leading: Container(
                                  width: 34.w,
                                  height: 34.w,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCBEFE0),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: _green,
                                    size: 19.sp,
                                  ),
                                ),

                                title: Text(
                                  _results[i].label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    color: _navy,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                onTap: () => _select(_results[i].point),
                              ),

                              if (i != _results.length - 1)
                                Divider(
                                  height: 1,
                                  thickness: 0.6,
                                  indent: 58.w,
                                  endIndent: 14.w,
                                  color: const Color(0xFFE2E8F0),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // ---- My location button ----
          Positioned(
            right: 16.w,
            bottom: 195.h,
            child: FloatingActionButton.small(
              heroTag: 'myLoc',
              backgroundColor: Colors.white,
              elevation: 3,
              onPressed: _locating ? null : _myLocation,
              child: _locating
                  ? SizedBox(
                width: 18.sp,
                height: 18.sp,
                child: const CircularProgressIndicator(strokeWidth: 2, color: _green),
              )
                  : const Icon(Icons.my_location_rounded, color: _green),
            ),
          ),

          // ---- Bottom confirm card ----
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                border: Border.all(color: _greenLine, width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, -4))
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F7F2),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(Icons.location_pin, color: _green, size: 20.sp),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Selected Location',
                                  style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w600, color: _grey)),
                              SizedBox(height: 2.h),
                              Text(
                                _address,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: _navy, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, _picked),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text('Confirm Location',
                            style: GoogleFonts.poppins(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}