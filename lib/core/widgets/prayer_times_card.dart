import 'dart:async';
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../constants.dart';

class PrayerTimesCard extends StatefulWidget {
  final bool isBn;

  const PrayerTimesCard({super.key, this.isBn = true});

  @override
  State<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends State<PrayerTimesCard> {
  String _selectedDistrict = 'Dhaka';
  String _selectedDistrictBn = 'ঢাকা';
  bool _loading = true;
  Map<String, dynamic>? _prayerData;
  Timer? _countdownTimer;
  int _countdownSeconds = 0;

  final List<Map<String, String>> _districts = [
    {'id': 'dhaka', 'name': 'Dhaka', 'bn': 'ঢাকা'},
    {'id': 'chittagong', 'name': 'Chittagong', 'bn': 'চট্টগ্রাম'},
    {'id': 'sylhet', 'name': 'Sylhet', 'bn': 'সিলেট'},
    {'id': 'rajshahi', 'name': 'Rajshahi', 'bn': 'রাজশাহী'},
    {'id': 'khulna', 'name': 'Khulna', 'bn': 'খুলনা'},
    {'id': 'barisal', 'name': 'Barisal', 'bn': 'বরিশাল'},
    {'id': 'rangpur', 'name': 'Rangpur', 'bn': 'রংপুর'},
    {'id': 'mymensingh', 'name': 'Mymensingh', 'bn': 'ময়মনসিংহ'},
    {'id': 'comilla', 'name': 'Comilla', 'bn': 'কুমিল্লা'},
    {'id': 'coxsbazar', 'name': "Cox's Bazar", 'bn': 'কক্সবাজার'},
    {'id': 'bogura', 'name': 'Bogura', 'bn': 'বগুড়া'},
    {'id': 'jessore', 'name': 'Jessore', 'bn': 'যশোর'},
    {'id': 'dinajpur', 'name': 'Dinajpur', 'bn': 'দিনাজপুর'},
    {'id': 'noakhali', 'name': 'Noakhali', 'bn': 'নোয়াখালী'},
    {'id': 'tangail', 'name': 'Tangail', 'bn': 'টাঙ্গাইল'},
    {'id': 'faridpur', 'name': 'Faridpur', 'bn': 'ফরিদপুর'},
    {'id': 'kushtia', 'name': 'Kushtia', 'bn': 'কুষ্টিয়া'},
    {'id': 'pabna', 'name': 'Pabna', 'bn': 'পাবনা'},
    {'id': 'brahmanbaria', 'name': 'Brahmanbaria', 'bn': 'ব্রাহ্মণবাড়িয়া'},
    {'id': 'gazipur', 'name': 'Gazipur', 'bn': 'গাজীপুর'},
    {'id': 'narayanganj', 'name': 'Narayanganj', 'bn': 'নারায়ণগঞ্জ'},
    {'id': 'feni', 'name': 'Feni', 'bn': 'ফেনী'},
    {'id': 'jamalpur', 'name': 'Jamalpur', 'bn': 'জামালপুর'},
    {'id': 'sirajganj', 'name': 'Sirajganj', 'bn': 'সিরাজগঞ্জ'},
    {'id': 'bagerhat', 'name': 'Bagerhat', 'bn': 'বাগেরহাট'},
    {'id': 'satkhira', 'name': 'Satkhira', 'bn': 'সাতক্ষীরা'},
    {'id': 'bhola', 'name': 'Bhola', 'bn': 'ভোলা'},
    {'id': 'patuakhali', 'name': 'Patuakhali', 'bn': 'পটুয়াখালী'},
    {'id': 'kishoreganj', 'name': 'Kishoreganj', 'bn': 'কিশোরগঞ্জ'},
    {'id': 'netrokona', 'name': 'Netrokona', 'bn': 'নেত্রকোণা'},
    {'id': 'chandpur', 'name': 'Chandpur', 'bn': 'চাঁদপুর'},
    {'id': 'lakshmipur', 'name': 'Lakshmipur', 'bn': 'লক্ষ্মীপুর'},
    {'id': 'habiganj', 'name': 'Habiganj', 'bn': 'হবিগঞ্জ'},
    {'id': 'moulvibazar', 'name': 'Moulvibazar', 'bn': 'মৌলভীবাজার'},
    {'id': 'sunamganj', 'name': 'Sunamganj', 'bn': 'সুনামগঞ্জ'},
    {'id': 'kurigram', 'name': 'Kurigram', 'bn': 'কুড়িগ্রাম'},
    {'id': 'gaibandha', 'name': 'Gaibandha', 'bn': 'গাইবান্ধা'},
    {'id': 'panchagarh', 'name': 'Panchagarh', 'bn': 'পঞ্চগড়'},
    {'id': 'thakurgaon', 'name': 'Thakurgaon', 'bn': 'ঠাকুরগাঁও'},
    {'id': 'chapainawabganj', 'name': 'Chapai Nawabganj', 'bn': 'চাঁপাইনবাবগঞ্জ'},
    {'id': 'natore', 'name': 'Natore', 'bn': 'নাটোর'},
    {'id': 'chuadanga', 'name': 'Chuadanga', 'bn': 'চুয়াডাঙ্গা'},
    {'id': 'meherpur', 'name': 'Meherpur', 'bn': 'মেহেরপুর'},
    {'id': 'jhenaidah', 'name': 'Jhenaidah', 'bn': 'ঝিনাইদহ'},
    {'id': 'magura', 'name': 'Magura', 'bn': 'মাগুরা'},
    {'id': 'narail', 'name': 'Narail', 'bn': 'নড়াইল'},
    {'id': 'gopalganj', 'name': 'Gopalganj', 'bn': 'গোপালগঞ্জ'},
    {'id': 'madaripur', 'name': 'Madaripur', 'bn': 'মাদারীপুর'},
    {'id': 'shariatpur', 'name': 'Shariatpur', 'bn': 'শরীয়তপুর'},
    {'id': 'rajbari', 'name': 'Rajbari', 'bn': 'রাজবাড়ী'},
    {'id': 'munshiganj', 'name': 'Munshiganj', 'bn': 'মুন্সীগঞ্জ'},
    {'id': 'manikganj', 'name': 'Manikganj', 'bn': 'মানিকগঞ্জ'},
    {'id': 'narsingdi', 'name': 'Narsingdi', 'bn': 'নরসিংদী'},
    {'id': 'sherpur', 'name': 'Sherpur', 'bn': 'শেরপুর'},
    {'id': 'pirojpur', 'name': 'Pirojpur', 'bn': 'পিরোজপুর'},
    {'id': 'jhalokati', 'name': 'Jhalokati', 'bn': 'ঝালকাঠি'},
    {'id': 'barguna', 'name': 'Barguna', 'bn': 'বরগুনা'},
    {'id': 'khagrachhari', 'name': 'Khagrachhari', 'bn': 'খাগড়াছড়ি'},
    {'id': 'rangamati', 'name': 'Rangamati', 'bn': 'রাঙ্গামাটি'},
    {'id': 'bandarban', 'name': 'Bandarban', 'bn': 'বান্দরবান'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchPrayerTimes();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPrayerTimes() async {
    setState(() => _loading = true);
    try {
      final res = await CustomerApiService.instance.getPrayerTimes(district: _selectedDistrict);
      if (res['data'] != null) {
        if (mounted) {
          setState(() {
            _prayerData = res['data'];
            _countdownSeconds = _prayerData?['countdownSeconds'] ?? 0;
            _selectedDistrict = _prayerData?['district'] ?? _selectedDistrict;
            _selectedDistrictBn = _prayerData?['districtBn'] ?? _selectedDistrictBn;
            _loading = false;
          });
          _startCountdown();
        }
      }
    } catch (_) {
      // Fallback offline calculation
      if (mounted) {
        setState(() {
          _prayerData = _getOfflineData();
          _countdownSeconds = 3600;
          _loading = false;
        });
        _startCountdown();
      }
    }
  }

  Map<String, dynamic> _getOfflineData() {
    return {
      'district': _selectedDistrict,
      'districtBn': _selectedDistrictBn,
      'currentPrayer': 'Dhuhr',
      'currentPrayerBn': 'যোহর',
      'nextPrayer': 'Asr',
      'nextPrayerBn': 'আসর',
      'nextPrayerTime': '04:18 PM',
      'timings': {
        'fajr': '04:38 AM',
        'fajrBn': '০৪:৩৮',
        'sunrise': '05:51 AM',
        'sunriseBn': '০৫:৫১',
        'dhuhr': '11:54 AM',
        'dhuhrBn': '১১:৫৪',
        'asr': '04:18 PM',
        'asrBn': '০৪:১৮',
        'maghrib': '05:56 PM',
        'maghribBn': '০৫:৫৬',
        'isha': '07:09 PM',
        'ishaBn': '০৭:০৯',
        'sehriEnd': '04:32 AM',
        'sehriEndBn': '০৪:৩২',
        'iftar': '05:56 PM',
        'iftarBn': '০৫:৫৬',
      }
    };
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownSeconds > 0) {
        setState(() => _countdownSeconds--);
      } else {
        _fetchPrayerTimes();
      }
    });
  }

  String _formatCountdown(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (widget.isBn) {
      final toBn = (int n) => n.toString().split('').map((d) => ['০','১','২','৩','৪','৫','৬','৭','৮','৯'][int.parse(d)]).join('');
      if (hours > 0) {
        return '${toBn(hours)} ঘণ্টা ${toBn(minutes)} মিনিট';
      }
      return '${toBn(minutes)} মি. ${toBn(seconds)} সে.';
    } else {
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${minutes}m ${seconds}s';
    }
  }

  void _showDistrictPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF0D5E36), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        widget.isBn ? 'জেলা নির্বাচন করুন (নামাজের সময়সূচি)' : 'Select District for Prayer Times',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _districts.length,
                    itemBuilder: (ctx, idx) {
                      final d = _districts[idx];
                      final isSelected = _selectedDistrict.toLowerCase() == d['name']!.toLowerCase();

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isSelected ? const Color(0xFF0D5E36) : const Color(0xFFE2E8F0),
                          child: Icon(
                            Icons.mosque,
                            size: 16,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                        title: Text(
                          widget.isBn ? '${d['bn']} (${d['name']})' : '${d['name']} (${d['bn']})',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFF0D5E36) : const Color(0xFF0F172A),
                          ),
                        ),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF0D5E36)) : null,
                        onTap: () {
                          setState(() {
                            _selectedDistrict = d['name']!;
                            _selectedDistrictBn = d['bn']!;
                          });
                          Navigator.pop(ctx);
                          _fetchPrayerTimes();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _prayerData == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF06351E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
        ),
      );
    }

    final timings = _prayerData?['timings'] ?? {};
    final nextPrayer = widget.isBn ? (_prayerData?['nextPrayerBn'] ?? 'আসর') : (_prayerData?['nextPrayer'] ?? 'Asr');
    final nextPrayerTime = _prayerData?['nextPrayerTime'] ?? '04:18 PM';
    final currentPrayer = widget.isBn ? (_prayerData?['currentPrayerBn'] ?? 'যোহর') : (_prayerData?['currentPrayer'] ?? 'Dhuhr');

    final List<Map<String, dynamic>> waqts = [
      {'name': widget.isBn ? 'ফজর' : 'Fajr', 'time': timings['fajr'] ?? '04:38 AM', 'icon': Icons.nights_stay_outlined},
      {'name': widget.isBn ? 'যোহর' : 'Dhuhr', 'time': timings['dhuhr'] ?? '11:54 AM', 'icon': Icons.wb_sunny_outlined},
      {'name': widget.isBn ? 'আসর' : 'Asr', 'time': timings['asr'] ?? '04:18 PM', 'icon': Icons.wb_twilight_outlined},
      {'name': widget.isBn ? 'মাগরিব' : 'Maghrib', 'time': timings['maghrib'] ?? '05:56 PM', 'icon': Icons.wb_twilight},
      {'name': widget.isBn ? 'এশা' : 'Isha', 'time': timings['isha'] ?? '07:09 PM', 'icon': Icons.bedtime_outlined},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF06351E), Color(0xFF0D5E36), Color(0xFF0B4628)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06351E).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative mosque silhouette opacity
          Positionright(
            right: -10,
            bottom: -10,
            child: Opacity(
              opacity: 0.08,
              child: const Icon(Icons.mosque, size: 140, color: Colors.white),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Location & Islamic Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _showDistrictPicker,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFFBBF24), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              widget.isBn ? _selectedDistrictBn : _selectedDistrict,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),

                    // Sehri & Iftar Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wb_sunny, color: Color(0xFFFCD34D), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            widget.isBn
                                ? 'ইফতার: ${timings['iftar'] ?? '05:56 PM'}'
                                : 'Iftar: ${timings['iftar'] ?? '05:56 PM'}',
                            style: const TextStyle(
                              color: Color(0xFFFDE68A),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Upcoming Prayer Highlight Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.access_time_filled, color: Color(0xFF34D399), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isBn ? 'পরবর্তী ওয়াক্ত: $nextPrayer' : 'Next Prayer: $nextPrayer',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                nextPrayerTime,
                                style: const TextStyle(
                                  color: Color(0xFF6EE7B7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'বাকি ${_formatCountdown(_countdownSeconds)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 5 Waqts Horizontal Strip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: waqts.map((w) {
                    final isCurrent = w['name'].toString().toLowerCase() == currentPrayer.toLowerCase() ||
                        w['name'].toString().toLowerCase() == nextPrayer.toLowerCase();

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF15803D).withOpacity(0.7)
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent
                                ? const Color(0xFF4ADE80)
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(w['icon'] as IconData, size: 15, color: isCurrent ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1)),
                            const SizedBox(height: 4),
                            Text(
                              w['name'] as String,
                              style: TextStyle(
                                color: isCurrent ? Colors.white : const Color(0xFFE2E8F0),
                                fontSize: 11,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (w['time'] as String).replaceAll(' AM', '').replaceAll(' PM', ''),
                              style: TextStyle(
                                color: isCurrent ? const Color(0xFFFBBF24) : Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Positionright extends StatelessWidget {
  final double? right;
  final double? bottom;
  final Widget child;

  const Positionright({super.key, this.right, this.bottom, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: right,
      bottom: bottom,
      child: child,
    );
  }
}
