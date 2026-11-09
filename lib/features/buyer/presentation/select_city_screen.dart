import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/app_adaptive_back_button.dart';
import '../../../core/widgets/app_pill_search_bar.dart';
import '../controllers/buyer_home_controller.dart';

class SelectCityScreen extends StatefulWidget {
  final String? selectedCity;

  const SelectCityScreen({super.key, this.selectedCity});

  /// Popular cities come from the live home-feed API (popularAreas), not a
  /// hardcoded list. Empty until the feed has loaded.
  static List<String> get popularCities {
    if (!Get.isRegistered<BuyerHomeController>()) return const [];
    final areas = Get.find<BuyerHomeController>().homeFeed.value?.popularAreas ?? [];
    final seen = <String>{};
    final out = <String>[];
    for (final a in areas) {
      final c = (a.city ?? '').trim();
      if (c.isNotEmpty && seen.add(c.toLowerCase())) out.add(c);
    }
    return out;
  }

  static const List<String> allCities = [
    'Abohar',
    'Adilabad',
    'Adoni',
    'Agarmalwa',
    'Agartala',
    'Agra',
    'Ahmedabad',
    'Ahmednagar',
    'Aizawl',
    'Ajman',
    'Ajmer',
    'Akola',
    'Alappuzha',
    'Aligarh',
    'Alipurduar',
    'Allahabad',
    'Almora',
    'Alwar',
    'Ambala',
    'Ambikapur',
    'Amravati',
    'Amritsar',
    'Anand',
    'Anantapur',
    'Angul',
    'Ankleshwar',
    'Asansol',
    'Aurangabad',
    'Azamgarh',
    'Baddi',
    'Badlapur',
    'Bagalkot',
    'Bahadurgarh',
    'Bahraich',
    'Balaghat',
    'Balangir',
    'Baleshwar',
    'Ballari',
    'Balrampur',
    'Banda',
    'Bengaluru',
    'Bareilly',
    'Barmer',
    'Barnala',
    'Barwani',
    'Bastar',
    'Bathinda',
    'Beawar',
    'Begusarai',
    'Belgaum',
    'Bellary',
    'Berhampur',
    'Betul',
    'Bhadohi',
    'Bhadrak',
    'Bhagalpur',
    'Bharatpur',
    'Bharuch',
    'Bhavnagar',
    'Bhilai',
    'Bhilwara',
    'Bhimavaram',
    'Bhind',
    'Bhiwadi',
    'Bhiwani',
    'Bhopal',
    'Bhubaneswar',
    'Bhuj',
    'Bhusawal',
    'Bidar',
    'Bihar Sharif',
    'Bijnor',
    'Bikaner',
    'Bilaspur',
    'Bokaro',
    'Bongaigaon',
    'Botad',
    'Bulandshahr',
    'Bundi',
    'Burhanpur',
    'Buxar',
    'Calicut',
    'Chandigarh',
    'Chandrapur',
    'Chennai',
    'Chhatarpur',
    'Chhindwara',
    'Chikmagalur',
    'Chiplun',
    'Chitradurga',
    'Chittorgarh',
    'Cochin',
    'Coimbatore',
    'Cooch Behar',
    'Cuddalore',
    'Cuttack',
    'Dahod',
    'Damoh',
    'Darbhanga',
    'Darjeeling',
    'Datia',
    'Dausa',
    'Dehradun',
    'Deoghar',
    'Deoria',
    'Dewas',
    'Dhanbad',
    'Dhar',
    'Dharmapuri',
    'Dharwad',
    'Dholpur',
    'Dhule',
    'Dibrugarh',
    'Dimapur',
    'Dindigul',
    'Dindori',
    'Dispur',
    'Durg',
    'Durgapur',
    'Dwarka',
    'Ernakulam',
    'Erode',
    'Etawah',
    'Faizabad',
    'Faridabad',
    'Faridkot',
    'Farrukhabad',
    'Fatehpur',
    'Fazilka',
    'Firozabad',
    'Firozpur',
    'Gadag',
    'Gandhidham',
    'Gandhinagar',
    'Gangtok',
    'Gaya',
    'Ghaziabad',
    'Ghazipur',
    'Giridih',
    'Godhra',
    'Gonda',
    'Gondia',
    'Gorakhpur',
    'Greater Noida',
    'Guntur',
    'Gurdaspur',
    'Gurgaon',
    'Guwahati',
    'Gwalior',
    'Haldia',
    'Haldwani',
    'Hampi',
    'Hansi',
    'Hanumangarh',
    'Hapur',
    'Harda',
    'Hardoi',
    'Haridwar',
    'Hassan',
    'Hathras',
    'Himatnagar',
    'Hisar',
    'Hoshangabad',
    'Hoshiarpur',
    'Hospet',
    'Hosur',
    'Howrah',
    'Hubli',
    'Hyderabad',
    'Idukki',
    'Imphal',
    'Indore',
    'Itanagar',
    'Jabalpur',
    'Jagdalpur',
    'Jaipur',
    'Jaisalmer',
    'Jajpur',
    'Jalandhar',
    'Jalaun',
    'Jalgaon',
    'Jalna',
    'Jalpaiguri',
    'Jammu',
    'Jamnagar',
    'Jamshedpur',
    'Jaunpur',
    'Jhabua',
    'Jhalawar',
    'Jhansi',
    'Jharsuguda',
    'Jhunjhunu',
    'Jind',
    'Jodhpur',
    'Jorhat',
    'Junagadh',
    'Kadapa',
    'Kaithal',
    'Kakinada',
    'Kalaburagi',
    'Kalyan',
    'Kamrup',
    'Kanchipuram',
    'Kandla',
    'Kannur',
    'Kanpur',
    'Kapurthala',
    'Karaikudi',
    'Karawal Nagar',
    'Karimnagar',
    'Karnal',
    'Karur',
    'Kasaragod',
    'Kashipur',
    'Katihar',
    'Katni',
    'Kavali',
    'Khammam',
    'Khandwa',
    'Khanna',
    'Kharagpur',
    'Khargone',
    'Kheda',
    'Kishangarh',
    'Kochi',
    'Kodaikanal',
    'Kohima',
    'Kolar',
    'Kolhapur',
    'Kolkata',
    'Kollam',
    'Korba',
    'Kota',
    'Kottayam',
    'Kozhikode',
    'Krishnagiri',
    'Kullu',
    'Kumbakonam',
    'Kurnool',
    'Kurukshetra',
    'Lakhimpur',
    'Lalitpur',
    'Latur',
    'Leh',
    'Lonavala',
    'Lucknow',
    'Ludhiana',
    'Machilipatnam',
    'Madanapalle',
    'Madgaon',
    'Madikeri',
    'Madurai',
    'Mahabaleshwar',
    'Mahbubnagar',
    'Malappuram',
    'Malda',
    'Malerkotla',
    'Mandi',
    'Mandsaur',
    'Mandya',
    'Mangalore',
    'Moga',
    'Mohali',
    'Moradabad',
    'Morbi',
    'Morena',
    'Motihari',
    'Mount Abu',
    'Muktsar',
    'Mumbai',
    'Munger',
    'Murwara',
    'Mussoorie',
    'Muzaffarnagar',
    'Muzaffarpur',
    'Mysore',
    'Nadiad',
    'Nagercoil',
    'Nagpur',
    'Nainital',
    'Nalgonda',
    'Nanded',
    'Nandurbar',
    'Nandyal',
    'Nashik',
    'Navi Mumbai',
    'Navsari',
    'Neemuch',
    'Nellore',
    'New Delhi',
    'Nizamabad',
    'Noida',
    'Ongole',
    'Ooty',
    'Osmanabad',
    'Palakkad',
    'Palanpur',
    'Pali',
    'Palwal',
    'Panaji',
    'Panchkula',
    'Panipat',
    'Panna',
    'Panvel',
    'Paradip',
    'Parbhani',
    'Pathankot',
    'Patiala',
    'Patna',
    'Pithampur',
    'Porbandar',
    'Port Blair',
    'Puducherry',
    'Pune',
    'Puri',
    'Purnia',
    'Raebareli',
    'Raichur',
    'Raiganj',
    'Raipur',
    'Raisen',
    'Rajahmundry',
    'Rajapalayam',
    'Rajkot',
    'Rajnandgaon',
    'Rajsamand',
    'Ramagundam',
    'Ramanathapuram',
    'Rameshwaram',
    'Rampur',
    'Ranchi',
    'Raniganj',
    'Ratlam',
    'Ratnagiri',
    'Rewa',
    'Rewari',
    'Rishikesh',
    'Rohtak',
    'Roorkee',
    'Rourkela',
    'Sagar',
    'Saharanpur',
    'Saharsa',
    'Salem',
    'Samastipur',
    'Sambalpur',
    'Sangli',
    'Sangrur',
    'Sant Kabir Nagar',
    'Satara',
    'Satna',
    'Sawai Madhopur',
    'Sehore',
    'Seoni',
    'Shahdol',
    'Shahjahanpur',
    'Shajapur',
    'Shamli',
    'Shikohabad',
    'Shillong',
    'Shimla',
    'Shimoga',
    'Shivpuri',
    'Sikar',
    'Silchar',
    'Siliguri',
    'Singrauli',
    'Sirsa',
    'Sitapur',
    'Sivakasi',
    'Siwan',
    'Solan',
    'Solapur',
    'Sonipat',
    'Sri Ganganagar',
    'Srinagar',
    'Sultanpur',
    'Surat',
    'Surendranagar',
    'Suryapet',
    'Tezpur',
    'Thanjavur',
    'Thane',
    'Thiruvananthapuram',
    'Thoothukudi',
    'Thrissur',
    'Tinsukia',
    'Tiruchirappalli',
    'Tirunelveli',
    'Tirupati',
    'Tiruppur',
    'Tonk',
    'Tumkur',
    'Udaipur',
    'Udhampur',
    'Udupi',
    'Ujjain',
    'Ulhasnagar',
    'Umaria',
    'Unnao',
    'Vadodara',
    'Valsad',
    'Varanasi',
    'Vapi',
    'Vasai-Virar',
    'Vellore',
    'Vidisha',
    'Vijayawada',
    'Visakhapatnam',
    'Vizianagaram',
    'Vrindavan',
    'Warangal',
    'Wardha',
    'Yamunanagar',
    'Yavatmal',
    'Zirakpur',
  ];

  @override
  State<SelectCityScreen> createState() => _SelectCityScreenState();
}

class _SelectCityScreenState extends State<SelectCityScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCity(String city) {
    FocusScope.of(context).unfocus();
    Get.back(result: city);
  }

  void _clearCity() {
    FocusScope.of(context).unfocus();
    Get.back(result: '');
  }

  @override
  Widget build(BuildContext context) {
    final queryTrimmed = _query.toLowerCase().trim();
    final filteredCities = queryTrimmed.isEmpty
        ? SelectCityScreen.allCities
        : SelectCityScreen.allCities
        .where((c) => c.toLowerCase().contains(queryTrimmed))
        .toList();

    final hasSelected = widget.selectedCity != null && widget.selectedCity!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation Bar
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 8.h, 16.w, 4.h),
              child: Row(
                children: [
                  AppAdaptiveBackButton(
                    color: const Color(0xFF0F172A),
                    onPressed: () => Get.back(),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Select City',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (hasSelected)
                    TextButton(
                      onPressed: _clearCity,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF00C896),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Subtitle
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
              child: Text(
                'Select city you are looking to buy or rent',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),

            // Popular Cities Section
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
              child: Text(
                'Popular Cities',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            SizedBox(
              height: 42.h,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemCount: SelectCityScreen.popularCities.length,
                separatorBuilder: (context, index) => SizedBox(width: 10.w),
                itemBuilder: (context, index) {
                  final city = SelectCityScreen.popularCities[index];
                  final isSelected = widget.selectedCity?.toLowerCase() == city.toLowerCase();

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _selectCity(city),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE8F7F2) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00C896) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.4 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: isSelected ? const Color(0xFF00C896) : const Color(0xFFEF4444),
                            size: 15.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            city,
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF007A5E) : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 16.h),

            // Search Bar ("Search for a city")
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: AppPillSearchBar(
                controller: _searchController,
                hintText: 'Search for a city...',
                onChanged: (val) {
                  setState(() {
                    _query = val;
                  });
                },
                onSubmitted: (val) {
                  if (filteredCities.isNotEmpty) {
                    _selectCity(filteredCities.first);
                  }
                },
                onClear: () {
                  setState(() {
                    _query = '';
                  });
                },
              ),
            ),

            SizedBox(height: 14.h),

            // All Cities Header
            if (_query.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                child: Text(
                  'All Cities',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),

            // All Cities List with Chevron
            Expanded(
              child: filteredCities.isEmpty
                  ? Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Text(
                    'No city found matching "$_query"',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF64748B),
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              )
                  : ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: filteredCities.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 0.8,
                  color: Color(0xFFF1F5F9),
                ),
                itemBuilder: (context, index) {
                  final city = filteredCities[index];
                  final isSelected = widget.selectedCity?.toLowerCase() == city.toLowerCase();

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _selectCity(city),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 4.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            city,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF00C896) : const Color(0xFF1E293B),
                            ),
                          ),
                          isSelected
                              ? Icon(
                            Icons.check_circle_rounded,
                            color: const Color(0xFF00C896),
                            size: 19.sp,
                          )
                              : Icon(
                            Icons.chevron_right_rounded,
                            color: const Color(0xFFCBD5E1),
                            size: 20.sp,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
