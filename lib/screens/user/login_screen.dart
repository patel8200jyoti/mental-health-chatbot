import 'package:flutter/material.dart';
import '../../services/chat_api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _api                = AppApi();

  bool    _isLoading         = false;
  bool    _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Login flow ────────────────────────────────────────────────────────────

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final result = await _api.login(
        email:    _emailController.text.trim(),
        password: _passwordController.text,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => {
          "success": false,
          "message": "Request timed out. Check your network or server IP.",
        },
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result["success"] == true) {
        // Token is already saved inside _api.login()
        // Route to admin dashboard or main chat based on email
        final email = _emailController.text.trim().toLowerCase();
        if (email == "admin@admin.com") {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/chat');
        }
      } else {
        setState(() =>
            _errorMessage = result["message"]?.toString() ?? "Login failed");
      }

    } catch (e) {
      debugPrint("❌ Login error: $e");
      if (!mounted) return;
      setState(() {
        _isLoading    = false;
        _errorMessage =
            "Could not connect to server.\n"
            "Make sure your device is on the same Wi-Fi as the server.";
      });
    }
  }

  // ── Forgot password dialog ────────────────────────────────────────────────

  void _showForgotPassword() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text("Forgot Password"),
        content: const Text("Feature coming soon!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: Center(
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double maxW = 420;
              final double hPad = constraints.maxWidth > maxW
                  ? (constraints.maxWidth - maxW) / 2
                  : 24;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 36),
                  decoration: BoxDecoration(
                    color:        const Color(0xFFEAF4FF),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color:      Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset:     const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        // ── Icon ──────────────────────────────────────────
                        const CircleAvatar(
                          radius:          36,
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.spa,
                              size: 36, color: Colors.white),
                        ),
                        const SizedBox(height: 20),

                        // ── Heading ───────────────────────────────────────
                        const Text(
                          "Welcome Back",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Take a deep breath and log in",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 28),

                        // ── Error banner ──────────────────────────────────
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:        Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Email field ───────────────────────────────────
                        TextFormField(
                          controller:   _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration:   _fieldDeco("Email Address"),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return "Email is required";
                            if (!v.contains("@"))
                              return "Enter a valid email";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Password field ────────────────────────────────
                        TextFormField(
                          controller:  _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration:  _fieldDeco("Password").copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(
                                  () => _isPasswordVisible =
                                      !_isPasswordVisible),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return "Password is required";
                            if (v.length < 6) return "Minimum 6 characters";
                            return null;
                          },
                        ),

                        // ── Forgot password ───────────────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPassword,
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: Colors.teal),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // ── Login button ──────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _loginUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8ED8B5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width:  20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize:   15),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Divider ───────────────────────────────────────
                        Row(children: [
                          const Expanded(
                              child: Divider(color: Colors.black12)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            child: Text(
                              "or",
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ),
                          const Expanded(
                              child: Divider(color: Colors.black12)),
                        ]),
                        const SizedBox(height: 16),

                        // ── Login as Professional ─────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/proff_login'),
                            icon: const Icon(
                              Icons.health_and_safety_outlined,
                              color: Colors.teal,
                              size:  20,
                            ),
                            label: const Text(
                              "Login as Professional",
                              style: TextStyle(
                                color:      Colors.teal,
                                fontWeight: FontWeight.w600,
                                fontSize:   14,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              side: const BorderSide(
                                  color: Colors.teal, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Sign up link ──────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("New? ",
                                style: TextStyle(color: Colors.grey)),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/signup'),
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  color:      Colors.teal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Input decoration helper ───────────────────────────────────────────────

  InputDecoration _fieldDeco(String label) => InputDecoration(
    labelText:      label,
    filled:         true,
    fillColor:      Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:   BorderSide.none),
  );
}