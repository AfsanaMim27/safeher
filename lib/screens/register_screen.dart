import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String? selectedGender;
  bool loading = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            /// NAME (REQUIRED)
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
              ),
            ),
            const SizedBox(height: 12),

            /// PHONE (REQUIRED)
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Emergency Phone *',
              ),
            ),
            const SizedBox(height: 12),

            /// GENDER DROPDOWN
            DropdownButtonFormField<String>(
              value: selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (value) {
                setState(() => selectedGender = value);
              },
            ),
            const SizedBox(height: 12),

            /// EMAIL
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),

            /// PASSWORD
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 30),

            /// REGISTER BUTTON
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                /// 🔒 VALIDATIONS
                if (nameController.text.trim().isEmpty) {
                  _showError('Name cannot be empty');
                  return;
                }

                if (phoneController.text.trim().isEmpty) {
                  _showError('Phone number cannot be empty');
                  return;
                }

                if (selectedGender == null) {
                  _showError('Please select gender');
                  return;
                }

                if (emailController.text.trim().isEmpty ||
                    passwordController.text.trim().isEmpty) {
                  _showError('Email and password are required');
                  return;
                }

                setState(() => loading = true);

                final result = await AuthService().registerUser(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  gender: selectedGender!,
                );

                setState(() => loading = false);

                if (result == null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(),
                    ),
                  );
                } else {
                  _showError(result);
                }
              },
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Register'),
            ),

            const SizedBox(height: 20),

            /// BACK TO LOGIN
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? '),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
