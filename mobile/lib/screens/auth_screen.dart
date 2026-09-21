import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import 'main_navigation_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _emailController = TextEditingController(text: 'priya@example.com');
  final _passwordController = TextEditingController(text: 'SakhiUser123!');
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  Future<void> _submit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your email and password.')),
      );
      return;
    }

    bool success;
    if (_isLogin) {
      success = await auth.login(email, password);
    } else {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide your full name.')),
        );
        return;
      }
      success = await auth.register(
        email,
        password,
        name,
        _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emergencyCoral,
          content: Text(auth.errorMessage ?? 'Authentication failed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.softLavender,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.primaryViolet, size: 28),
              ),
              const SizedBox(height: 24),
              Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isLogin
                    ? 'Sign in to access your journey tracking and emergency network.'
                    : 'Join Sakhi to connect with your emergency support network.',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),

              if (!_isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.mail_outline, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline, size: 20),
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(_isLogin ? 'Sign In' : 'Create Account'),
                ),
              ),
              const SizedBox(height: 20),

              // Toggle button
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Create one"
                        : "Already have an account? Sign In",
                    style: const TextStyle(color: AppColors.primaryViolet, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
