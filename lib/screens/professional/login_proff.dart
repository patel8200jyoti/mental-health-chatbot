import 'package:flutter/material.dart';
import '../../services/professional_api.dart';
import 'package:mindease/services/core/api_service.dart'; // AppApi is HERE, not chat_api_service

class ProffLogin extends StatefulWidget {
  const ProffLogin({super.key});

  @override
  State<ProffLogin> createState() => _ProffLoginState();
}

class _ProffLoginState extends State<ProffLogin> {
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading         = false;
  bool _isPasswordVisible = false;

  final _api    = ProfessionalApi();
  final _appApi = AppApi(); // from core/api_service.dart

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Step 1 – get JWT
      final loginResult = await _appApi.login(
        email:    _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!loginResult["success"]) {
        _showError(loginResult["message"] ?? "Login failed");
        return;
      }

      // Step 2 – verify role + approval
      final profile = await _api.getMe();

      if (profile["role"] != "professional") {
        await _appApi.logout();
        _showError("This account is not registered as a professional.");
        return;
      }

      if (profile["is_approved"] != true) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/proff_pending');
        return;
      }

      // Step 3 – success
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/proff');
    } catch (e) {
      _showError("Unexpected error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: Center(
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double maxCardWidth      = 420;
              final double horizontalPadding = constraints.maxWidth > maxCardWidth
                  ? (constraints.maxWidth - maxCardWidth) / 2
                  : 24;

              return Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 36),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FF),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.health_and_safety_outlined,
                              size: 32, color: Colors.teal),
                        ),
                        const SizedBox(height: 20),
                        const Text('Professional Login',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text(
                            'Sign in to access your patient dashboard',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 28),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(
                              'Email Address', Icons.email_outlined),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Email is required';
                            if (!v.contains('@'))
                              return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: _inputDecoration(
                            'Password',
                            Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Password is required';
                            if (v.length < 6) return 'Minimum 6 characters';
                            return null;
                          },
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Forgot Password'),
                                content: const Text(
                                    'Password reset is not available yet. '
                                    'Please contact support.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            ),
                            child: const Text('Forgot Password?',
                                style: TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _loginUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4FBFA5),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Login',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('New professional? ',
                                style: TextStyle(color: Colors.grey)),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                  context, '/proff_signup'),
                              child: const Text('Sign Up',
                                  style: TextStyle(
                                      color: Colors.teal,
                                      fontWeight: FontWeight.bold)),
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

  InputDecoration _inputDecoration(String label, IconData icon,
          {Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      );
}