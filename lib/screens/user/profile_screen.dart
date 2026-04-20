import 'package:flutter/material.dart';
import '../../services/chat_api_service.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends State<PersonalInformationScreen> {
  final AppApi _api = AppApi();

  bool _loadingProfile = true;
  bool _loadingReport  = false;

  String fullName    = "";
  String email       = "";
  String dateOfBirth = "Not set";
  String gender      = "Not set";

  static const Color _teal      = Color(0xFF6BBFB5);
  static const Color _fieldBg   = Color(0xFFEAF2FB);
  static const Color _reportBg  = Color(0xFFF9D9C5);
  static const Color _btnGreen  = Color(0xFF8ED8B5);
  static const Color _logoutGrey= Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _api.getProfile();
      setState(() {
        fullName    = data["user_name"]   ?? "";
        email       = data["user_email"]  ?? "";
        dateOfBirth = data["user_dob"]    ?? "Not set";
        gender      = data["user_gender"] ?? "Not set";
        _loadingProfile = false;
      });
    } catch (e) {
      setState(() => _loadingProfile = false);
      _snack("Failed to load profile");
    }
  }

  Future<void> _viewReport() async {
    setState(() => _loadingReport = true);
    try {
      final report = await _api.getReport();
      setState(() => _loadingReport = false);
      if (!mounted) return;
      if (report == null) { _snack("No report available yet."); return; }
      _showReportSheet(
        reportText:  report["report_text"] as String,
        generatedAt: report["generated_at"] as String,
      );
    } catch (e) {
      setState(() => _loadingReport = false);
      _snack("Could not load report.");
    }
  }

  Future<void> _regenerateReport() async {
    Navigator.pop(context);
    setState(() => _loadingReport = true);
    try {
      final report = await _api.regenerateReport();
      setState(() => _loadingReport = false);
      if (!mounted) return;
      _showReportSheet(
        reportText:  report["report_text"] as String,
        generatedAt: report["generated_at"] as String,
      );
    } catch (e) {
      setState(() => _loadingReport = false);
      _snack("Could not regenerate report.");
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showReportSheet({required String reportText, required String generatedAt}) {
    String displayDate = generatedAt;
    try {
      final dt = DateTime.parse(generatedAt);
      displayDate = "${dt.day}/${dt.month}/${dt.year} "
          "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                const Icon(Icons.insights, color: _teal),
                const SizedBox(width: 10),
                const Expanded(child: Text("Your Progress Report",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(alignment: Alignment.centerLeft,
                child: Text("Generated: $displayDate",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade200, thickness: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Text(reportText,
                    style: const TextStyle(fontSize: 15, height: 1.7, color: Colors.black87)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _teal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _regenerateReport,
                  icon: const Icon(Icons.refresh, color: _teal),
                  label: const Text("Regenerate Report",
                      style: TextStyle(color: _teal, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Personal Information",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17)),
        centerTitle: true,
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                const SizedBox(height: 24),

                // ── Doodle Avatar ──────────────────────────────────────────
                Stack(alignment: Alignment.bottomRight, children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12, offset: const Offset(0, 4),
                      )],
                    ),
                    child: const CircleAvatar(
                      radius: 52,
                      backgroundColor: Color(0xFFD8EEF7),
                      child: _DoodleFace(),
                    ),
                  ),
                  // GestureDetector(
                  //   onTap: () { /* TODO: image picker */ },
                  //   child: Container(
                  //     padding: const EdgeInsets.all(7),
                  //     decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
                  //     child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  //   ),
                  // ),
                ]),
                const SizedBox(height: 10),
                const Text(" ",
                    style: TextStyle(color: _teal, fontWeight: FontWeight.w500, fontSize: 14)),

                const SizedBox(height: 28),

                // ── Info Cards ─────────────────────────────────────────────
                _infoCard(icon: Icons.person_outline,       label: "FULL NAME",      value: fullName),
                const SizedBox(height: 14),
                _infoCard(icon: Icons.mail_outline,         label: "EMAIL ADDRESS",  value: email),
                const SizedBox(height: 14),
                _infoCard(icon: Icons.calendar_month_outlined, label: "DATE OF BIRTH", value: dateOfBirth),
                const SizedBox(height: 14),
                _infoCard(icon: Icons.transgender,          label: "GENDER",         value: gender),

                const SizedBox(height: 28),

                // ── Report Card ────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _reportBg, borderRadius: BorderRadius.circular(20)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Text("Report",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const Spacer(),
                      Text("✳", style: TextStyle(fontSize: 22, color: Colors.brown.shade300)),
                    ]),
                    const SizedBox(height: 6),
                    const Text("Summary of how much progress you have made.",
                        style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4)),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _btnGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _loadingReport ? null : _viewReport,
                        child: _loadingReport
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text("View Report",
                                style: TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 32),

                // ── Log Out ────────────────────────────────────────────────
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  },
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                    Icon(Icons.logout, color: _logoutGrey, size: 20),
                    SizedBox(width: 8),
                    Text("Log Out",
                        style: TextStyle(color: _logoutGrey, fontSize: 16,
                            fontWeight: FontWeight.w500)),
                  ]),
                ),

                const SizedBox(height: 36),
              ]),
            ),
    );
  }

  Widget _infoCard({required IconData icon, required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _teal, size: 20),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
              fontSize: 10, color: Colors.black45, letterSpacing: 0.8, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
        ]),
      ]),
    );
  }
}

// ── Doodle Face Widget ────────────────────────────────────────────────────────

class _DoodleFace extends StatelessWidget {
  const _DoodleFace();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(104, 104),
      painter: _DoodlePainter(),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final skinPaint   = Paint()..color = const Color(0xFFF5CBA7);
    final hairPaint   = Paint()..color = const Color(0xFF5C3D2E);
    final darkPaint   = Paint()..color = const Color(0xFF2C2C2C);
    final whitePaint  = Paint()..color = Colors.white;
    final blushPaint  = Paint()..color = const Color(0xFFF1948A).withOpacity(0.4);
    final strokePaint = Paint()
      ..color = const Color(0xFF5C3D2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final lipPaint = Paint()
      ..color = const Color(0xFFE07B6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // Hair (back layer)
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - 14), width: 68, height: 52), hairPaint);
    // Side hair strands
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 34, cy - 4, 10, 30), const Radius.circular(5)), hairPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 24, cy - 4, 10, 30), const Radius.circular(5)), hairPaint);

    // Face
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 4), width: 56, height: 60), skinPaint);

    // Ears
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 28, cy + 4), width: 10, height: 14), skinPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 28, cy + 4), width: 10, height: 14), skinPaint);

    // Eyebrows
    final leftBrowPath = Path()
      ..moveTo(cx - 18, cy - 10)
      ..quadraticBezierTo(cx - 13, cy - 14, cx - 8, cy - 10);
    canvas.drawPath(leftBrowPath, strokePaint);

    final rightBrowPath = Path()
      ..moveTo(cx + 8, cy - 10)
      ..quadraticBezierTo(cx + 13, cy - 14, cx + 18, cy - 10);
    canvas.drawPath(rightBrowPath, strokePaint);

    // Eyes (whites)
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 13, cy - 2), width: 14, height: 12), whitePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 13, cy - 2), width: 14, height: 12), whitePaint);

    // Pupils
    canvas.drawCircle(Offset(cx - 12, cy - 2), 4, darkPaint);
    canvas.drawCircle(Offset(cx + 14, cy - 2), 4, darkPaint);

    // Eye shine
    canvas.drawCircle(Offset(cx - 10.5, cy - 3.5), 1.5, whitePaint);
    canvas.drawCircle(Offset(cx + 15.5, cy - 3.5), 1.5, whitePaint);

    // Nose (two small dots)
    canvas.drawCircle(Offset(cx - 3, cy + 8), 1.8, darkPaint..color = const Color(0xFFD4A57A));
    canvas.drawCircle(Offset(cx + 3, cy + 8), 1.8, darkPaint..color = const Color(0xFFD4A57A));

    // Blush
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 19, cy + 8), width: 14, height: 8), blushPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 19, cy + 8), width: 14, height: 8), blushPaint);

    // Smile
    final smilePath = Path()
      ..moveTo(cx - 10, cy + 16)
      ..quadraticBezierTo(cx, cy + 24, cx + 10, cy + 16);
    canvas.drawPath(smilePath, lipPaint);

    // Hair fringe detail lines
    final fringePaint = Paint()
      ..color = const Color(0xFF3D2B1F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 8, cy - 34), Offset(cx - 12, cy - 22), fringePaint);
    canvas.drawLine(Offset(cx, cy - 36), Offset(cx - 2, cy - 23), fringePaint);
    canvas.drawLine(Offset(cx + 8, cy - 34), Offset(cx + 10, cy - 22), fringePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}