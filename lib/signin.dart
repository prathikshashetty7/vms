import 'package:flutter/material.dart';
import 'admin/admin_dashboard.dart';
import 'dept/dept_dashboard.dart';
import 'host/host_dashboard.dart';
import 'receptionist/dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/design_system.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  // Add this for password visibility
  bool _obscurePassword = true;

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // Replace the UID-based lookup with an email-based lookup
  Future<Map<String, dynamic>?> _getUserDataByEmail(String email) async {
    final collections = ['admin', 'department', 'host', 'receptionist'];
    final fieldNames = [
      'email', // receptionist, admin
      'emp_email', // host
      'd_email', // department
    ];
    // Prepare all queries in parallel
    List<Future<Map<String, dynamic>?>> futures = [];
    for (final collection in collections) {
      for (final field in fieldNames) {
        futures.add(_firestore
            .collection(collection)
            .where(field, isEqualTo: email)
            .limit(1)
            .get()
            .then((query) {
              if (query.docs.isNotEmpty) {
                final data = query.docs.first.data();
                data['role'] = collection;
                return data;
              }
              return null;
            }));
      }
    }
    // Wait for all queries to complete and return the first non-null result
    final results = await Future.wait(futures);
    return results.firstWhere((data) => data != null, orElse: () => null);
  }

  void _signIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      try {
        // Sign in with Firebase Auth for all users
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        final email = _emailController.text.trim();
        // If admin, skip Firestore lookup
        if (email.toLowerCase() == 'admin@gmail.com') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else {
          // Fetch user data by email for other roles
          final userData = await _getUserDataByEmail(email);
          if (userData == null) throw Exception('User data not found');
          final role = userData['role'] as String?;
          if (role == null) throw Exception('User role not found');
          // Navigate based on role (case-insensitive)
          if (role.toLowerCase() == 'department') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DeptDashboard()),
            );
          } else if (role.toLowerCase() == 'host') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HostMainScreen()),
            );
          } else if (role.toLowerCase() == 'receptionist') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ReceptionistDashboard()),
            );
          } else {
            throw Exception('Invalid user role');
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = 'An error occurred during login.';
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF068FFF),
              Colors.black,
              Color(0xFF222831),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignSystem.spacing24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo and Welcome Card
                  Container(
                    padding: const EdgeInsets.all(DesignSystem.spacing24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF068FFF).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(DesignSystem.spacing16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF068FFF).withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.asset(
                              'assets/images/rdl.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: DesignSystem.spacing16),
                        Text(
                          'Welcome Back',
                          style: DesignSystem.heading2.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: DesignSystem.spacing8),
                        Text(
                          'Sign in to continue',
                          style: DesignSystem.bodyLarge.copyWith(color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignSystem.spacing32),
                  // Sign In Form
                  Container(
                    padding: const EdgeInsets.all(DesignSystem.spacing24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
                      border: Border.all(
                        color: const Color(0xFF068FFF).withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF068FFF).withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                            style: const TextStyle(color: Colors.white),
                            decoration: DesignSystem.inputDecoration(
                              label: 'Email',
                              hint: 'Enter your email',
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                            ).copyWith(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: DesignSystem.spacing16),
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _signIn(),
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: DesignSystem.inputDecoration(
                              label: 'Password',
                              hint: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ).copyWith(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: DesignSystem.spacing24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              style: DesignSystem.primaryButtonStyle,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Sign In'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignSystem.spacing32),
                  // Quick Login Buttons (now at the bottom)
                  Column(
                    children: [
                      _QuickLoginButton(
                        text: 'Go to Admin Dashboard',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminDashboard()),
                          );
                        },
                      ),
                      const SizedBox(height: DesignSystem.spacing8),
                      _QuickLoginButton(
                        text: 'Go to Department Dashboard',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DeptDashboard()),
                          );
                        },
                      ),
                      const SizedBox(height: DesignSystem.spacing8),
                      _QuickLoginButton(
                        text: 'Go to Host Dashboard',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HostMainScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: DesignSystem.spacing8),
                      _QuickLoginButton(
                        text: 'Go to Receptionist Dashboard',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReceptionistDashboard()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widget for quick login buttons
class _QuickLoginButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _QuickLoginButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          text,
          style: DesignSystem.bodyLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }
} 