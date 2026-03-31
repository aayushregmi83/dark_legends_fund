import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DarkLegendsFund());
}

class DarkLegendsFund extends StatelessWidget {
  const DarkLegendsFund({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dark Legends Fund',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050508),
      ),
      home: const HomeScreen(),
    );
  }
}

class AppColors {
  static const Color gold = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFFF0D080);
  static const Color goldDark = Color(0xFF8B6914);
  static const Color crimson = Color(0xFF8B1A1A);
  static const Color crimsonLight = Color(0xFFC0392B);
  static const Color bgDeep = Color(0xFF050508);
  static const Color bgCard = Color(0xFF0D0D14);
  static const Color bgPanel = Color(0xFF111118);
  static const Color textLight = Color(0xFFE8E8F0);
  static const Color textMid = Color(0xFFA0A0B8);
  static const Color textDim = Color(0xFF6B6B7A);
}

class WeekData {
  DateTime date;
  int amount;
  List<bool> paid;

  WeekData({required this.date, required this.amount, required this.paid});

  Map<String, dynamic> toJson() {
    return {'date': date.toIso8601String(), 'amount': amount, 'paid': paid};
  }

  factory WeekData.fromJson(Map<String, dynamic> json) {
    return WeekData(
      date: DateTime.parse(json['date']),
      amount: json['amount'],
      paid: List<bool>.from(json['paid']),
    );
  }
}

class AppState {
  List<WeekData> weeks;
  int currentWeek;

  AppState({required this.weeks, required this.currentWeek});

  Map<String, dynamic> toJson() {
    return {
      'weeks': weeks.map((w) => w.toJson()).toList(),
      'currentWeek': currentWeek,
    };
  }

  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      weeks: List<WeekData>.from(
        (json['weeks'] as List).map((w) => WeekData.fromJson(w)),
      ),
      currentWeek: json['currentWeek'] ?? 0,
    );
  }
}

const List<String> MEMBERS = [
  "Aayush Regmi",
  "Abhishek Niraula",
  "Bijaya Khanal",
  "Gaurav Shah",
  "Loresh Kunwar",
  "Nishchal Pokhrel",
  "Niraj Bista",
  "Prashan Rai",
  "Ram Gautam",
  "Ritesh Bogati",
  "Sushil Kr. Mandal",
];

DateTime getLastTuesday({DateTime? fromDate}) {
  final d = fromDate ?? DateTime.now();
  final day = d.weekday; // 1=Monday, 7=Sunday
  final diff = day == 2 ? 0 : (day < 2 ? day + 5 : day - 2);
  final result = d.subtract(Duration(days: diff));
  return DateTime(result.year, result.month, result.day);
}

DateTime addWeeks(DateTime date, int n) {
  return date.add(Duration(days: n * 7));
}

String formatDate(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}-${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]}-${d.year}';
}

String getInitials(String name) {
  return name.split(' ').take(2).map((w) => w[0]).join('').toUpperCase();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AppState state;
  String toastMessage = '';
  bool showToast = false;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _loadState();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateStr = prefs.getString('dlf_state');

    final prevTuesday = getLastTuesday();
    final onWeekBack = prevTuesday.subtract(const Duration(days: 7));
    final thisTuesday = getLastTuesday();

    if (stateStr != null) {
      state = AppState.fromJson(jsonDecode(stateStr));
    } else {
      state = AppState(
        weeks: [
          WeekData(date: onWeekBack, amount: 10, paid: List.filled(11, false)),
          WeekData(date: thisTuesday, amount: 20, paid: List.filled(11, false)),
        ],
        currentWeek: 1,
      );
    }

    if (state.currentWeek >= state.weeks.length) {
      state.currentWeek = state.weeks.length - 1;
    }

    setState(() {});
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dlf_state', jsonEncode(state));
  }

  void _togglePaid(int memberIdx) {
    final week = state.weeks[state.currentWeek];
    week.paid[memberIdx] = !week.paid[memberIdx];
    final name = MEMBERS[memberIdx];
    final isPaid = week.paid[memberIdx];

    _showToast(
      '${isPaid ? '✓' : '✗'} $name — ${isPaid ? 'Collected' : 'Unmarked'}',
    );

    _saveState();
    setState(() {});
  }

  void _showToast(String message) {
    setState(() {
      toastMessage = message;
      showToast = true;
    });

    Future.delayed(const Duration(milliseconds: 2600), () {
      setState(() {
        showToast = false;
      });
    });
  }

  void _changeWeek(int dir) {
    final next = state.currentWeek + dir;
    if (next < 0 || next >= state.weeks.length) return;

    setState(() {
      state.currentWeek = next;
    });

    _saveState();
  }

  void _addNewWeek() {
    final lastWeek = state.weeks.last;
    final newDate = addWeeks(lastWeek.date, 1);

    state.weeks.add(
      WeekData(date: newDate, amount: 20, paid: List.filled(11, false)),
    );

    setState(() {
      state.currentWeek = state.weeks.length - 1;
    });

    _showToast(
      '✦ Week ${state.currentWeek + 1} added — ${formatDate(newDate)}',
    );
    _saveState();
  }

  int _getTotalCollected() {
    int total = 0;
    for (var week in state.weeks) {
      final count = week.paid.where((p) => p).length;
      total += count * week.amount;
    }
    return total;
  }

  int _getPaidThisWeek() {
    return state.weeks[state.currentWeek].paid.where((p) => p).length;
  }

  @override
  Widget build(BuildContext context) {
    if (state.weeks.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // SPLASH HEADER
                _buildSplashHeader(),

                // STATS BAR
                _buildStatsBar(),

                // CURRENT WEEK SECTION
                _buildWeeklyCollectionSection(),

                // HISTORY SECTION
                _buildHistorySection(),

                // FOOTER
                _buildFooter(),
              ],
            ),
          ),
          // TOAST
          if (showToast)
            Positioned(bottom: 24, left: 24, right: 24, child: _buildToast()),
        ],
      ),
    );
  }

  Widget _buildSplashHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          // EMBLEM WITH SPINNING RINGS
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer rotating ring
                RotationTransition(
                  turns: _spinController,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                // Inner rotating ring (reverse)
                RotationTransition(
                  turns: Tween(begin: 1.0, end: 0.0).animate(_spinController),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.3),
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignCenter,
                      ),
                    ),
                  ),
                ),
                // Icon in center
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.15).animate(
                    CurvedAnimation(
                      parent: _spinController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: const Text('⚔️', style: TextStyle(fontSize: 52)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // TITLE
          Text(
            'Dark Legends Fund',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: AppColors.gold,
              letterSpacing: 0.04,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          // SUBTITLE
          Text(
            'BROTHERHOOD · DISCIPLINE · LEGACY',
            style: GoogleFonts.cinzel(
              fontSize: 12,
              letterSpacing: 0.35,
              color: AppColors.gold,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 12),

          // DIVIDER
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.gold,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Transform.rotate(
                angle: 0.785,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    boxShadow: [
                      BoxShadow(color: AppColors.gold, blurRadius: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.gold,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // POWERED BY
          RichText(
            text: TextSpan(
              style: GoogleFonts.rajdhani(
                fontSize: 11,
                letterSpacing: 0.2,
                color: AppColors.textDim,
              ),
              children: [
                const TextSpan(text: 'POWERED BY '),
                TextSpan(
                  text: '@AAYUSHREGMI',
                  style: GoogleFonts.rajdhani(
                    fontSize: 11,
                    letterSpacing: 0.2,
                    color: AppColors.gold.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final total = _getTotalCollected();
    final paid = _getPaidThisWeek();
    final weeks = state.weeks.length;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.gold.withOpacity(0.25)),
          bottom: BorderSide(color: AppColors.gold.withOpacity(0.25)),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatCell('Rs.$total', 'Total Collected')),
          Container(width: 1, color: AppColors.gold.withOpacity(0.25)),
          Expanded(child: _buildStatCell('$paid/11', 'This Week')),
          Container(width: 1, color: AppColors.gold.withOpacity(0.25)),
          Expanded(child: _buildStatCell('$weeks', 'Weeks Run')),
        ],
      ),
    );
  }

  Widget _buildStatCell(String value, String label) {
    return Container(
      color: AppColors.bgPanel,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.cinzel(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.rajdhani(
              fontSize: 10,
              letterSpacing: 0.2,
              color: AppColors.textDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCollectionSection() {
    final week = state.weeks[state.currentWeek];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Section header with week nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    color: AppColors.gold,
                    margin: const EdgeInsets.only(right: 8),
                  ),
                  Text(
                    'WEEKLY COLLECTION',
                    style: GoogleFonts.cinzel(
                      fontSize: 12,
                      letterSpacing: 0.25,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildWeekButton('‹', () => _changeWeek(-1)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: Text(
                      'Week ${state.currentWeek + 1} — Rs.${week.amount}',
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildWeekButton('›', () => _changeWeek(1)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Member cards
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: MEMBERS.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _buildMemberCard(i),
          ),
          const SizedBox(height: 8),

          // Add week button
          GestureDetector(
            onTap: _addNewWeek,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.3),
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+ ADD NEW WEEK',
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  letterSpacing: 0.2,
                  color: AppColors.goldDark,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.bgPanel,
          border: Border.all(color: AppColors.gold.withOpacity(0.25), width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.gold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(int index) {
    final week = state.weeks[state.currentWeek];
    final isPaid = week.paid[index];
    final name = MEMBERS[index];
    final initials = getInitials(name);

    return GestureDetector(
      onTap: () => _togglePaid(index),
      child: Container(
        decoration: BoxDecoration(
          color: isPaid ? AppColors.bgCard.withOpacity(0.8) : AppColors.bgCard,
          border: Border.all(
            color: isPaid
                ? AppColors.gold.withOpacity(0.35)
                : AppColors.gold.withOpacity(0.25),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 3,
              height: 70,
              decoration: BoxDecoration(
                color: isPaid
                    ? AppColors.gold
                    : AppColors.gold.withOpacity(0.25),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Member number
            SizedBox(
              width: 22,
              child: Text(
                (index + 1).toString().padLeft(2, '0'),
                style: GoogleFonts.cinzel(
                  fontSize: 11,
                  color: AppColors.textDim,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 12),

            // Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPaid
                      ? AppColors.gold
                      : AppColors.gold.withOpacity(0.25),
                  width: 1.5,
                ),
                color: isPaid
                    ? AppColors.gold.withOpacity(0.15)
                    : AppColors.gold.withOpacity(0.08),
                boxShadow: isPaid
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isPaid ? AppColors.gold : AppColors.goldDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Member info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isPaid ? AppColors.goldLight : AppColors.textLight,
                      letterSpacing: 0.03,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPaid ? '✦ COLLECTED' : 'PENDING',
                    style: GoogleFonts.rajdhani(
                      fontSize: 11,
                      letterSpacing: 0.1,
                      color: isPaid
                          ? AppColors.gold.withOpacity(0.6)
                          : AppColors.textDim,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              'Rs.${week.amount}',
              style: GoogleFonts.cinzel(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isPaid ? AppColors.gold : AppColors.textDim,
              ),
            ),
            const SizedBox(width: 12),

            // Check icon
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPaid
                      ? AppColors.gold
                      : AppColors.gold.withOpacity(0.25),
                  width: 1.5,
                ),
                color: isPaid
                    ? AppColors.gold.withOpacity(0.15)
                    : Colors.transparent,
                boxShadow: isPaid
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  isPaid ? '✓' : '',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                color: AppColors.gold,
                margin: const EdgeInsets.only(right: 8),
              ),
              Text(
                'COLLECTION HISTORY',
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  letterSpacing: 0.25,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // History table header
          Container(
            color: AppColors.bgPanel,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    'WEEK',
                    style: GoogleFonts.cinzel(
                      fontSize: 10,
                      letterSpacing: 0.2,
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'DATE',
                    style: GoogleFonts.cinzel(
                      fontSize: 10,
                      letterSpacing: 0.2,
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'COLLECTED',
                    style: GoogleFonts.cinzel(
                      fontSize: 10,
                      letterSpacing: 0.2,
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'RATE',
                    style: GoogleFonts.cinzel(
                      fontSize: 10,
                      letterSpacing: 0.2,
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'STATUS',
                    style: GoogleFonts.cinzel(
                      fontSize: 10,
                      letterSpacing: 0.2,
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // History table rows
          ...List.generate(state.weeks.length, (ri) {
            final idx = state.weeks.length - 1 - ri;
            final week = state.weeks[idx];
            final paidCount = week.paid.where((p) => p).length;
            final collected = paidCount * week.amount;
            final isComplete = paidCount == 11;

            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.gold.withOpacity(0.08),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      'Week ${idx + 1}',
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      formatDate(week.date),
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        color: AppColors.textDim,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Rs.$collected',
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Rs.${week.amount}/head',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        color: AppColors.textMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isComplete
                            ? AppColors.gold.withOpacity(0.12)
                            : AppColors.crimson.withOpacity(0.15),
                        border: Border.all(
                          color: isComplete
                              ? AppColors.gold.withOpacity(0.3)
                              : AppColors.crimson.withOpacity(0.4),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '$paidCount/11',
                        style: GoogleFonts.rajdhani(
                          fontSize: 11,
                          color: isComplete
                              ? AppColors.gold
                              : const Color(0xFFE07070),
                          letterSpacing: 0.1,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      border: Border(top: BorderSide(color: AppColors.gold.withOpacity(0.25))),
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.rajdhani(
            fontSize: 11,
            letterSpacing: 0.2,
            color: AppColors.textDim,
          ),
          children: [
            const TextSpan(text: 'DARK LEGENDS FUND · '),
            TextSpan(
              text: 'EST. 2025',
              style: GoogleFonts.rajdhani(
                fontSize: 11,
                letterSpacing: 0.2,
                color: AppColors.gold.withOpacity(0.7),
              ),
            ),
            const TextSpan(text: ' · EVERY TUESDAY'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildToast() {
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgPanel,
          border: Border.all(color: AppColors.gold, width: 1),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 32,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Text(
          toastMessage,
          style: GoogleFonts.rajdhani(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: AppColors.gold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
