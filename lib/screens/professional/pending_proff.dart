import 'package:flutter/material.dart';
import '../../services/professional_api.dart';
import 'package:mindease/services/core/api_service.dart'; // AppApi is HERE

/// Shown when a professional logs in but is_approved == false.
class ProffPendingScreen extends StatefulWidget {
  const ProffPendingScreen({super.key});

  @override
  State<ProffPendingScreen> createState() => _ProffPendingScreenState();
}

class _ProffPendingScreenState extends State<ProffPendingScreen> {
  bool _checking = false;
  final _api     = ProfessionalApi();
  final _authApi = AppApi(); // from core/api_service.dart

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    try {
      final profile = await _api.getProfessionalMe();
      if (!mounted) return;

      if (profile["is_approved"] == true) {
        // Approved — go to dashboard
        Navigator.pushReplacementNamed(context, '/proff');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Still pending approval. Check back soon.'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not reach server: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _logout() async {
    await _authApi.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/proff_login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded,
                    size: 64, color: Colors.amber),
              ),
              const SizedBox(height: 28),
              const Text(
                'Account Pending Approval',
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your professional account has been submitted and is '
                'awaiting review by our admin team.\n\n'
                'You will be able to access the platform once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _checking
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                      _checking ? 'Checking…' : 'Check Status',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FBFA5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _checking ? null : _checkStatus,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _logout,
                child: const Text('Log Out',
                    style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}