import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/admin_api.dart';

/// Launched when admin taps "View Details" on a pending professional card.
/// Shows full registration info + two-step verification workflow.
class DoctorVerificationPage extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final VoidCallback onStatusChanged;

  const DoctorVerificationPage({
    super.key,
    required this.doctor,
    required this.onStatusChanged,
  });

  @override
  State<DoctorVerificationPage> createState() => _DoctorVerificationPageState();
}

enum _VerifyStatus { idle, running, passed, warnings}

class _CheckResult {
  final bool passed;
  final String label;
  final String detail;
  const _CheckResult(this.passed, this.label, this.detail);
}

class _DoctorVerificationPageState extends State<DoctorVerificationPage> {
  final _api = AdminApi();
  bool _isActing = false;
  _VerifyStatus _verifyStatus = _VerifyStatus.idle;
  List<_CheckResult> _checks = [];

  Map<String, dynamic> get doc => widget.doctor;

  String get _id =>
      doc["_id"]?.toString() ?? doc["user_id"]?.toString() ?? '';

  String _f(dynamic v) =>
      (v == null || v.toString().trim().isEmpty) ? '—' : v.toString().trim();

  String _ago(dynamic raw) {
    if (raw == null) return '';
    try {
      final d = DateTime.now().difference(
          DateTime.parse(raw.toString()).toLocal());
      if (d.inMinutes < 60) return '${d.inMinutes}m ago';
      if (d.inHours < 24) return '${d.inHours}h ago';
      return '${d.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  // ── Step 1 : Automated data checks ────────────────────────────────────────
  Future<void> _runChecks() async {
    setState(() {
      _verifyStatus = _VerifyStatus.running;
      _checks = [];
    });
    await Future.delayed(const Duration(milliseconds: 700));

    final reg     = doc["medical_registration_number"]?.toString() ?? '';
    final year    = doc["year_of_registration"]?.toString() ?? '';
    final name    = (doc["full_name"] ?? doc["user_name"] ?? '').toString();
    final qual    = doc["educational_qualifications"]?.toString() ?? '';
    final council = doc["state_medical_council"]?.toString() ?? '';
    final email   = doc["user_email"]?.toString() ?? '';

    final results = <_CheckResult>[
      // Registration number
      RegExp(r'^[A-Za-z0-9\-\/]{5,}$').hasMatch(reg.replaceAll(' ', ''))
          ? _CheckResult(true,  'Registration Number', '$reg — format OK')
          : _CheckResult(false, 'Registration Number',
              'Too short or invalid characters ($reg)'),

      // Year
      () {
        final y = int.tryParse(year);
        return (y != null && y >= 1970 && y <= DateTime.now().year)
            ? _CheckResult(true,  'Year of Registration', '$year — valid range')
            : _CheckResult(false, 'Year of Registration',
                '"$year" is outside 1970–${DateTime.now().year}');
      }(),

      // Full name (2+ words)
      name.trim().split(RegExp(r'\s+')).length >= 2 && name.length >= 5
          ? _CheckResult(true,  'Full Name', '"$name" — first + last name present')
          : _CheckResult(false, 'Full Name', 'Should include first and last name'),

      // Recognised degree
      ['mbbs','md','ms','bds','mds','do','bams','bhms','bums']
              .any((d) => qual.toLowerCase().contains(d))
          ? _CheckResult(true,  'Educational Qualification',
              '"$qual" contains a recognised degree')
          : _CheckResult(false, 'Educational Qualification',
              'No recognised degree found (MBBS/MD/MS/BDS…)'),

      // Council
      council.length > 3
          ? _CheckResult(true,  'State Medical Council', '"$council"')
          : _CheckResult(false, 'State Medical Council',
              'Name too short or missing'),

      // Email
      email.contains('@') && email.contains('.') && email.length > 5
          ? _CheckResult(true,  'Email Address', email)
          : _CheckResult(false, 'Email Address', 'Invalid format'),
    ];

    final allOk = results.every((r) => r.passed);
    setState(() {
      _checks = results;
      _verifyStatus =
          allOk ? _VerifyStatus.passed : _VerifyStatus.warnings;
    });
  }

  // ── Step 2 : NMR portal deep-link ─────────────────────────────────────────
  // NMR (nmr-nmc.abdm.gov.in) has NO public REST API — lookups require
  // Aadhaar OTP + CAPTCHA. Best UX: auto-copy reg number → open portal.
  Future<void> _openNmr() async {
    final reg = doc["medical_registration_number"]?.toString() ?? '';
    if (reg.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: reg));
    }
    final uri = Uri.parse('https://nmr-nmc.abdm.gov.in/nmr/v3/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(reg.isNotEmpty
              ? 'Reg. No "$reg" copied — paste it in the NMR portal'
              : 'NMR portal opened'),
          backgroundColor: Colors.teal,
          duration: const Duration(seconds: 4),
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Could not open browser. Visit nmr-nmc.abdm.gov.in manually.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ── Approve / Reject ───────────────────────────────────────────────────────
  Future<void> _act(bool approve) async {
    final name = _f(doc["full_name"] ?? doc["user_name"]);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(approve ? 'Approve $name?' : 'Reject Application?'),
        content: Text(approve
            ? 'This grants $name access to the professional portal. '
              'Ensure you have verified on NMR before approving.'
            : 'The application will be rejected. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? Colors.green : Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(approve ? 'Yes, Approve' : 'Yes, Reject',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _isActing = true);
    try {
      await _api.approveProfessional(_id, approve);
      widget.onStatusChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approve ? '✓ $name approved' : 'Application rejected'),
        backgroundColor: approve ? Colors.green : Colors.red,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final name    = _f(doc["full_name"] ?? doc["user_name"]);
    final email   = _f(doc["user_email"]);
    final role    = _f(doc["professional_role"] ?? doc["specialty"]);
    final regNo   = _f(doc["medical_registration_number"]);
    final council = _f(doc["state_medical_council"]);
    final year    = _f(doc["year_of_registration"]);
    final qual    = _f(doc["educational_qualifications"]);
    final dob     = _f(doc["user_dob"]);
    final gender  = _f(doc["user_gender"]);
    final ago     = _ago(doc["created_at"]);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text('Doctor Verification',
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        actions: [
          Container(
            margin:
                const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
            child: const Center(
              child: Text('PENDING',
                  style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [

          // ── Identity ───────────────────────────────────────────────────
          _card(child: Row(children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.withOpacity(0.12),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.email_outlined,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(email,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(role,
                      style: const TextStyle(
                          color: Colors.indigo,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Icon(Icons.access_time, size: 13, color: Colors.grey),
              const SizedBox(height: 2),
              Text(ago,
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
          ])),
          const SizedBox(height: 14),

          // ── Registration details ───────────────────────────────────────
          _label('Medical Registration Details'),
          _card(child: Column(children: [
            _row(Icons.badge_outlined, 'Registration Number', regNo,
                highlight: true, copyable: true),
            _div(),
            _row(Icons.location_city_outlined, 'State Medical Council',
                council, copyable: true),
            _div(),
            _row(Icons.calendar_today_outlined,
                'Year of Registration', year),
            _div(),
            _row(Icons.school_outlined, 'Educational Qualifications',
                qual),
          ])),
          const SizedBox(height: 14),

          // ── Personal details ───────────────────────────────────────────
          _label('Personal Details'),
          _card(child: Column(children: [
            _row(Icons.cake_outlined, 'Date of Birth', dob),
            _div(),
            _row(Icons.wc_outlined, 'Gender', gender),
          ])),
          const SizedBox(height: 20),

          // ── Step 1: Internal checks ────────────────────────────────────
          _label('Step 1 — Automated Data Validation'),
          _card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _stepBadge('1', Colors.blue),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Internal Field Checks',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              if (_verifyStatus == _VerifyStatus.passed)
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 20)
              else if (_verifyStatus == _VerifyStatus.warnings)
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 20),
            ]),
            const SizedBox(height: 6),
            const Text(
              'Validates registration number format, year, name, '
              'qualification and council for obvious issues.',
              style: TextStyle(color: Colors.grey, fontSize: 12)),

            // Results
            if (_checks.isNotEmpty) ...[
              const SizedBox(height: 14),
              ..._checks.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Icon(
                    r.passed
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: r.passed ? Colors.green : Colors.red,
                    size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(r.label,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: r.passed
                                  ? Colors.black87
                                  : Colors.red[700])),
                      Text(r.detail,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ]),
                  ),
                ]),
              )),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _verifyStatus == _VerifyStatus.passed
                      ? Colors.green.withOpacity(0.08)
                      : Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _verifyStatus == _VerifyStatus.passed
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(
                    _verifyStatus == _VerifyStatus.passed
                        ? Icons.verified_outlined
                        : Icons.warning_amber_outlined,
                    color: _verifyStatus == _VerifyStatus.passed
                        ? Colors.green
                        : Colors.orange,
                    size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _verifyStatus == _VerifyStatus.passed
                          ? 'All checks passed — data looks consistent'
                          : '${_checks.where((r) => !r.passed).length} issue(s) — review before approving',
                      style: TextStyle(
                          fontSize: 12,
                          color: _verifyStatus == _VerifyStatus.passed
                              ? Colors.green[700]
                              : Colors.orange[700])),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
            ] else
              const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side:
                      const BorderSide(color: Colors.blue, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _verifyStatus == _VerifyStatus.running
                    ? null
                    : _runChecks,
                icon: _verifyStatus == _VerifyStatus.running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.blue, strokeWidth: 2))
                    : const Icon(Icons.fact_check_outlined,
                        color: Colors.blue, size: 17),
                label: Text(
                  _verifyStatus == _VerifyStatus.idle
                      ? 'Run Validation Checks'
                      : _verifyStatus == _VerifyStatus.running
                          ? 'Checking…'
                          : 'Re-run Checks',
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.w600)),
              ),
            ),
          ])),
          const SizedBox(height: 12),

          // ── Step 2: NMR portal ─────────────────────────────────────────
          _label('Step 2 — NMR Portal Cross-Check'),
          _card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _stepBadge('2', Colors.teal),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('National Medical Register',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
                child: const Text('OFFICIAL',
                    style: TextStyle(
                        color: Colors.teal,
                        fontSize: 9,
                        fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 6),
            const Text(
              'NMR has no public REST API — it requires Aadhaar OTP + '
              'CAPTCHA. Tapping below auto-copies the reg. number and '
              'opens the portal so you can verify in seconds.',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 14),

            // How-to steps
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAF7),
                borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                _step('1', 'Tap the button — reg. number is auto-copied'),
                _step('2', 'On NMR portal → Search / Verify Doctor'),
                _step('3', 'Paste the registration number'),
                _step('4',
                    'Confirm name, council and qualification match'),
              ]),
            ),
            const SizedBox(height: 12),

            // Copyable reg number tile
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                    ClipboardData(text: _f(doc["medical_registration_number"])));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Registration number copied'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.teal.withOpacity(0.35))),
                child: Row(children: [
                  const Icon(Icons.badge_outlined,
                      size: 16, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text('Reg No:  ',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
                  Text(regNo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.teal,
                          letterSpacing: 0.5)),
                  const Spacer(),
                  const Icon(Icons.copy, size: 14, color: Colors.teal),
                  const SizedBox(width: 3),
                  Text('Copy',
                      style: TextStyle(
                          color: Colors.teal.shade700, fontSize: 11)),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _openNmr,
                icon: const Icon(Icons.open_in_browser,
                    color: Colors.white, size: 17),
                label: const Text('Open NMR Portal  →',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                  'nmr-nmc.abdm.gov.in — National Medical Commission India',
                  style: TextStyle(color: Colors.grey, fontSize: 10)),
            ),
          ])),
          const SizedBox(height: 28),

          // ── Decision ───────────────────────────────────────────────────
          _card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Decision',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              'Complete both steps above before deciding. '
              'Approved doctors get immediate portal access.',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: Colors.red.withOpacity(0.35))),
                  ),
                  onPressed: _isActing ? null : () => _act(false),
                  icon: _isActing
                      ? const SizedBox()
                      : const Icon(Icons.close,
                          color: Colors.red, size: 17),
                  label: _isActing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))
                      : const Text('Reject',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isActing ? null : () => _act(true),
                  icon: _isActing
                      ? const SizedBox()
                      : const Icon(Icons.check,
                          color: Colors.white, size: 17),
                  label: _isActing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Approve',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ])),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  // ── Reusable widgets ───────────────────────────────────────────────────────
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2))
      ],
    ),
    child: child,
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
            letterSpacing: 0.4)),
  );

  Widget _row(IconData icon, String label, String value,
      {bool highlight = false, bool copyable = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Icon(icon, size: 17, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: highlight
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color:
                          highlight ? Colors.blue[800] : Colors.black87,
                      letterSpacing: highlight ? 0.4 : 0)),
            ]),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$label copied'),
                  duration: const Duration(seconds: 1),
                ));
              },
              child: Icon(Icons.copy_outlined,
                  size: 15, color: Colors.grey[400]),
            ),
        ]),
      );

  Widget _div() =>
      Divider(height: 1, color: Colors.grey.withOpacity(0.12));

  Widget _stepBadge(String n, Color color) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
        color: color.withOpacity(0.12), shape: BoxShape.circle),
    child: Center(
      child: Text(n,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _step(String n, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 18,
        height: 18,
        margin: const EdgeInsets.only(right: 8, top: 1),
        decoration:
            const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
        child: Center(
          child: Text(n,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
      ),
      Expanded(
        child: Text(text,
            style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ),
    ]),
  );
}