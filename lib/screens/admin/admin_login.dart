import 'package:flutter/material.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    // 🔥 Replace later with real API call

    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacementNamed(context, '/admin_dashboard');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: Center(
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 👇 Responsive width logic
              final double maxCardWidth = 420;
              final double horizontalPadding =
                  constraints.maxWidth > maxCardWidth
                      ? (constraints.maxWidth - maxCardWidth) / 2
                      : 24;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 20,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FF),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ICON
                        const CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 32,
                            color: Colors.teal,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // TITLE
                        const Text(
                          "Admin Login",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 6),

                        

                        const SizedBox(height: 28),

                        // EMAIL
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: "Email Address",
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Email is required";
                            }
                            if (!value.contains('@')) {
                              return "Enter valid email";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // PASSWORD
                        

                        // FORGOT PASSWORD
                        TextFormField(
  controller: _passwordController,
  obscureText: !_isPasswordVisible,
  decoration: InputDecoration(
    labelText: "Password",
    filled: true,
    fillColor: Colors.white,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    suffixIcon: IconButton(
      icon: Icon(
        _isPasswordVisible
            ? Icons.visibility_off
            : Icons.visibility,
        color: Colors.grey,
      ),
      onPressed: () {
        setState(() {
          _isPasswordVisible = !_isPasswordVisible;
        });
      },
    ),
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }
    if (value.length < 6) {
      return "Minimum 6 characters required";
    }
    return null;
  },
),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title:
                                      const Text("Forgot Password"),
                                  content: const Text(
                                      "This feature is not available yet. Stay tuned!"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text("OK"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _loginUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF8ED8B5),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text("Login"),
                          ),
                        ),

                        const SizedBox(height: 20),
                         
                       
                        
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
}