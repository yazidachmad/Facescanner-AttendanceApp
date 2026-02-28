import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordObscure = true;
  bool _isConfirmObscure = true;
  bool _agreeToTerms = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Stack(
        children: [
          // Blue curved header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A56DB), Color(0xFF1E90FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Stack(children: [
                Positioned(top: -40, right: -40,
                  child: Container(width: 160, height: 160,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.07)))),
                Positioned(bottom: 10, left: -20,
                  child: Container(width: 100, height: 100,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06)))),
              ]),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white.withOpacity(0.2)),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text("Create Account",
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                              color: Colors.white)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Icon + title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.person_add_alt_1_rounded,
                              color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Face Scan",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                              Text("Fill in your details below",
                                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Scrollable form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1A56DB).withOpacity(0.1),
                                blurRadius: 24, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Full Name
                                _buildLabel("Full Name"),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _fullNameController,
                                  hint: "Your full name",
                                  icon: Icons.person_outline_rounded,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return 'Please enter your full name';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Email
                                _buildLabel("Email Address"),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _emailController,
                                  hint: "you@example.com",
                                  icon: Icons.mail_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return 'Please enter your email';
                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                                      return 'Please enter a valid email address';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Username
                                _buildLabel("Username"),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _usernameController,
                                  hint: "Choose a username",
                                  icon: Icons.alternate_email_rounded,
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return 'Please enter a username';
                                    if (value.length < 3)
                                      return 'Username must be at least 3 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Password
                                _buildLabel("Password"),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _passwordController,
                                  hint: "Min. 8 characters",
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _isPasswordObscure,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordObscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey[400], size: 20),
                                    onPressed: () => setState(
                                        () => _isPasswordObscure = !_isPasswordObscure),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return 'Please enter a password';
                                    if (value.length < 8)
                                      return 'Password must be at least 8 characters';
                                    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)')
                                        .hasMatch(value))
                                      return 'Must contain uppercase, lowercase, and number';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Confirm Password
                                _buildLabel("Confirm Password"),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _confirmPasswordController,
                                  hint: "Re-enter your password",
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _isConfirmObscure,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isConfirmObscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey[400], size: 20),
                                    onPressed: () => setState(
                                        () => _isConfirmObscure = !_isConfirmObscure),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return 'Please confirm your password';
                                    if (value != _passwordController.text)
                                      return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Terms
                                GestureDetector(
                                  onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: _agreeToTerms
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFF8FAFF),
                                      border: Border.all(
                                        color: _agreeToTerms
                                            ? const Color(0xFF1A56DB).withOpacity(0.4)
                                            : Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 20, height: 20,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5),
                                            color: _agreeToTerms
                                                ? const Color(0xFF1A56DB)
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: _agreeToTerms
                                                  ? const Color(0xFF1A56DB)
                                                  : Colors.grey.shade300,
                                              width: 1.5),
                                          ),
                                          child: _agreeToTerms
                                              ? const Icon(Icons.check_rounded,
                                                  color: Colors.white, size: 13)
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Wrap(
                                            children: [
                                              Text("I agree to the ",
                                                style: TextStyle(fontSize: 12,
                                                  color: Colors.grey[600])),
                                              const Text("Terms & Conditions",
                                                style: TextStyle(fontSize: 12,
                                                  color: Color(0xFF1A56DB),
                                                  fontWeight: FontWeight.w600)),
                                              Text(" and ",
                                                style: TextStyle(fontSize: 12,
                                                  color: Colors.grey[600])),
                                              const Text("Privacy Policy",
                                                style: TextStyle(fontSize: 12,
                                                  color: Color(0xFF1A56DB),
                                                  fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Sign Up Button
                                _buildPrimaryButton(
                                  label: "Create Account",
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      if (!_agreeToTerms) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Please agree to Terms & Conditions'),
                                            backgroundColor: Colors.redAccent.withOpacity(0.9),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10)),
                                          ),
                                        );
                                        return;
                                      }
                                      Navigator.pushReplacement(context,
                                        MaterialPageRoute(
                                          builder: (context) => const HomeScreen()));
                                    }
                                  },
                                ),
                                const SizedBox(height: 20),

                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Already have an account? ",
                                        style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                                      GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: const Text("Sign In",
                                          style: TextStyle(fontSize: 13,
                                            color: Color(0xFF1A56DB),
                                            fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
        color: Color(0xFF374151), letterSpacing: 0.2));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF1A56DB).withOpacity(0.6), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.5)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1)),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
      ),
    );
  }

  Widget _buildPrimaryButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF1E90FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1A56DB).withOpacity(0.35),
              blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onPressed,
          child: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
        ),
      ),
    );
  }
}