import 'package:flutter/material.dart';
import '../../services/professional_api.dart'; 



class ProffSignupScreen extends StatefulWidget {
  const ProffSignupScreen({super.key});

  @override
  State<ProffSignupScreen> createState() => _ProffSignupScreenState();
}

class _ProffSignupScreenState extends State<ProffSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController      = TextEditingController();
  final _regNoController     = TextEditingController();
  final _councilController   = TextEditingController();
  final _yearController      = TextEditingController();
  final _educationController = TextEditingController();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();
  final _dobController       = TextEditingController();
  final _genderController    = TextEditingController();

  DateTime? _selectedDob;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // ProfessionalApi.register() — NOT registerProfessional()
  final _api = ProfessionalApi();

  @override
  void dispose() {
    _nameController.dispose();
    _regNoController.dispose();
    _councilController.dispose();
    _yearController.dispose();
    _educationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  Future<void> _signupUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Method is now register(), not registerProfessional()
      final result = await _api.register(
        fullName:                   _nameController.text.trim(),
        medicalRegistrationNumber:  _regNoController.text.trim(),
        stateMedicalCouncil:        _councilController.text.trim(),
        yearOfRegistration:         _yearController.text.trim(),
        educationalQualifications:  _educationController.text.trim(),
        email:                      _emailController.text.trim(),
        password:                   _passwordController.text,
        dob:                        _selectedDob,
        gender: _genderController.text.isNotEmpty ? _genderController.text : null,
      );

      if (!mounted) return;

      if (result["success"] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [
              Icon(Icons.check_circle, color: Colors.teal),
              SizedBox(width: 8),
              Text('Registration Submitted'),
            ]),
            content: const Text(
              'Your account has been created and is pending admin approval.\n\n'
              'You will be able to log in once your account is approved.',
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/proff_login');
                },
                child: const Text('Go to Login',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        _showError(result["message"] ?? "Registration failed");
      }
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
            child: Text('Select Gender',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          ...['Female', 'Male', 'Other'].map((g) => ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.teal),
                title: Text(g),
                onTap: () {
                  setState(() => _genderController.text = g);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F6F0),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(Icons.psychology,
                                    color: Color(0xFF4FBFA5), size: 30),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Create Professional Account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 21, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            const Text(
                                'Your profile will be reviewed\nbefore activation.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.amber.withOpacity(0.4)),
                              ),
                              child: const Row(children: [
                                Icon(Icons.info_outline,
                                    color: Colors.amber, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      'Accounts require admin approval before you can log in.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87)),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFEAF2FF),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Column(children: [
                                _buildField(
                                    'Full Name (as per medical degree)',
                                    _nameController,
                                    Icons.person_outline,
                                    'Name is required'),
                                _buildField(
                                    'Medical Registration Number',
                                    _regNoController,
                                    Icons.badge_outlined,
                                    'Registration Number is required'),
                                _buildField(
                                    'State Medical Council',
                                    _councilController,
                                    Icons.location_city_outlined,
                                    'State Medical Council is required'),
                                _buildField(
                                    'Year of Registration',
                                    _yearController,
                                    Icons.calendar_today_outlined,
                                    'Year is required',
                                    keyboardType: TextInputType.number),
                                _buildField(
                                    'Educational Qualifications',
                                    _educationController,
                                    Icons.school_outlined,
                                    'Educational Qualification is required',
                                    helperText: 'e.g., MBBS, MD, MS'),
                                _buildField(
                                    'Email Address',
                                    _emailController,
                                    Icons.email_outlined,
                                    'Email is required',
                                    keyboardType: TextInputType.emailAddress),
                                _buildPasswordField(),
                                _buildField(
                                  'Date of Birth',
                                  _dobController,
                                  Icons.calendar_today_outlined,
                                  null,
                                  readOnly: true,
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(1940),
                                      lastDate: DateTime.now().subtract(
                                          const Duration(days: 365 * 18)),
                                      initialDate: DateTime(1990),
                                    );
                                    if (date != null) {
                                      _selectedDob = date;
                                      _dobController.text =
                                          '${date.day}/${date.month}/${date.year}';
                                    }
                                  },
                                ),
                                _buildField('Gender', _genderController,
                                    Icons.wc_outlined, null,
                                    readOnly: true, onTap: _selectGender),
                              ]),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4FBFA5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                  elevation: 0,
                                ),
                                onPressed: _isLoading ? null : _signupUser,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2))
                                    : const Text('Create Account →',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account? ',
                                    style: TextStyle(color: Colors.grey)),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacementNamed(
                                      context, '/proff_login'),
                                  child: const Text('Login',
                                      style: TextStyle(
                                          color: Color(0xFF4FBFA5),
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                                'By signing up you agree to our Terms of Service.\nYour data is encrypted and secure.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
    String? validatorMsg, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          validator: validatorMsg != null
              ? (v) => v == null || v.isEmpty ? validatorMsg : null
              : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.teal, size: 20),
            helperText: helperText,
            helperStyle: const TextStyle(fontSize: 11, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        const Text('Password',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: (v) =>
              v == null || v.length < 6 ? 'Minimum 6 characters' : null,
          decoration: InputDecoration(
            prefixIcon:
                const Icon(Icons.lock_outline, color: Colors.teal, size: 20),
            suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                    size: 20),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword)),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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