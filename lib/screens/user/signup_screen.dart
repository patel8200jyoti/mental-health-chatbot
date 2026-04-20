import 'package:flutter/material.dart';
import '../../services/chat_api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey            = GlobalKey<FormState>();
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController      = TextEditingController();
  final _genderController   = TextEditingController();
  final _api                = AppApi();

  bool      _obscurePassword = true;
  bool      _isLoading       = false;
  String?   _errorMessage;
  DateTime? _selectedDob;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  // ── Registration + auto-login flow ────────────────────────────────────────

  Future<void> _signupUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Register
      debugPrint("📡 Sending register request...");

      final registerResult = await _api.register(
        email:      _emailController.text.trim(),
        password:   _passwordController.text,
        userName:   _nameController.text.trim(),
        dob:        _selectedDob,
        userGender: _genderController.text.isNotEmpty
                        ? _genderController.text
                        : null,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => {
          "success": false,
          "message": "Request timed out. Check your network or server IP.",
        },
      );

      debugPrint("📥 Register result: $registerResult");

      if (!mounted) return;

      if (registerResult["success"] != true) {
        setState(() {
          _errorMessage = registerResult["message"]?.toString()
              ?? "Registration failed. Please try again.";
          _isLoading = false;
        });
        return;
      }

      // Step 2: Auto-login
      debugPrint("📡 Sending login request...");

      final loginResult = await _api.login(
        email:    _emailController.text.trim(),
        password: _passwordController.text,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => {
          "success": false,
          "message": "Login timed out. Please log in manually.",
        },
      );

      debugPrint("📥 Login result: $loginResult");

      if (!mounted) return;

      final loginSuccess =
          loginResult["success"] == true || loginResult["token"] != null;

      if (loginSuccess) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/chat');
      } else {
        // Registration succeeded but auto-login failed → send to login screen
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created! Please log in."),
            backgroundColor: Colors.teal,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint("❌ Signup error: $e");
      if (!mounted) return;
      setState(() {
        _errorMessage = "Could not connect to server.\n"
            "Make sure your device is on the same Wi-Fi as the server.";
        _isLoading = false;
      });
    }
  }

  // ── Gender picker ─────────────────────────────────────────────────────────

  void _selectGender() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              "Select Gender",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          ...["Female", "Male", "Other"].map(
            (g) => ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.teal),
              title: Text(g),
              onTap: () {
                setState(() => _genderController.text = g);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _selectDob() async {
    final date = await showDatePicker(
      context:     context,
      firstDate:   DateTime(1900),
      lastDate:    DateTime.now(),
      initialDate: DateTime(2000),
    );
    if (date != null) {
      setState(() {
        _selectedDob       = date;
        _dobController.text =
            "${date.day.toString().padLeft(2, '0')}/"
            "${date.month.toString().padLeft(2, '0')}/"
            "${date.year}";
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Form(
                  key: _formKey,
                  child: Stack(children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // ── App icon ──────────────────────────────────────
                          Center(
                            child: CircleAvatar(
                              radius:          28,
                              backgroundColor: Colors.teal,
                              child: const Icon(Icons.spa,
                                  color: Colors.white, size: 28),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Heading ───────────────────────────────────────
                          const Text(
                            "Create Account",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize:   22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Your journey to emotional wellness\nstarts here.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),

                          // ── Error banner ──────────────────────────────────
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:  Colors.red.shade50,
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

                          // ── Form fields ───────────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:        const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(children: [
                              _buildField(
                                label:      "Full Name",
                                controller: _nameController,
                                icon:       Icons.person_outline,
                                validator:  (v) => (v == null || v.trim().isEmpty)
                                    ? "Name required"
                                    : null,
                              ),
                              _buildField(
                                label:        "Email Address",
                                controller:   _emailController,
                                icon:         Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return "Email is required";
                                  if (!v.contains("@"))
                                    return "Enter a valid email";
                                  return null;
                                },
                              ),
                              _buildPasswordField(),
                              _buildField(
                                label:      "Date of Birth",
                                controller: _dobController,
                                icon:       Icons.calendar_today_outlined,
                                readOnly:   true,
                                onTap:      _selectDob,
                              ),
                              _buildField(
                                label:      "Gender",
                                controller: _genderController,
                                icon:       Icons.wc_outlined,
                                readOnly:   true,
                                onTap:      _selectGender,
                              ),
                            ]),
                          ),
                          const SizedBox(height: 24),

                          // ── Sign Up button ────────────────────────────────
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB6EBD3),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              onPressed: _isLoading ? null : _signupUser,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width:  20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black54),
                                    )
                                  : const Text(
                                      "Sign Up →",
                                      style: TextStyle(
                                        color:      Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                                    color: Colors.grey.shade500,
                                    fontSize: 13),
                              ),
                            ),
                            const Expanded(
                                child: Divider(color: Colors.black12)),
                          ]),
                          const SizedBox(height: 16),

                          // ── Sign Up as Professional ───────────────────────
                          SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                  context, '/proff_signup'),
                              icon: const Icon(
                                Icons.health_and_safety_outlined,
                                color: Colors.teal,
                                size:  20,
                              ),
                              label: const Text(
                                "Sign Up as Professional",
                                style: TextStyle(
                                  color:      Colors.teal,
                                  fontWeight: FontWeight.w600,
                                  fontSize:   14,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Colors.teal, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Already have an account ───────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account? "),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(
                                    context, "/login"),
                                child: const Text(
                                  "Login",
                                  style: TextStyle(
                                    color:      Color(0xFF4FBFA5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Legal footnote ────────────────────────────────
                          const Text(
                            "By signing up you agree to our Terms of Service\n"
                            "and Privacy Policy. Your data is encrypted.",
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    // ── Back arrow ────────────────────────────────────────
                    Positioned(
                      top:  0,
                      left: 0,
                      child: IconButton(
                        icon:      const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly             = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller:   controller,
          validator:    validator,
          keyboardType: keyboardType,
          readOnly:     readOnly,
          onTap:        onTap,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.teal, size: 20),
            filled:     true,
            fillColor:  Colors.white,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Password",
            style:
                TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller:  _passwordController,
          obscureText: _obscurePassword,
          validator: (v) {
            if (v == null || v.length < 6)
              return "Min 6 characters";
            if (!v.contains(RegExp(r'[A-Z]')))
              return "Include at least one uppercase letter";
            if (!v.contains(RegExp(r'[0-9]')))
              return "Include at least one digit";
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline,
                color: Colors.teal, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey,
                size:  20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled:    true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}