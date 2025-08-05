import 'package:flutter/material.dart';
import 'admin/admin_dashboard.dart';
import 'dept/dept_dashboard.dart';
import 'host/host_dashboard.dart';
import 'receptionist/dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/system_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // Added for TimeoutException

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

  // Optimized email-based lookup with parallel queries and shorter timeouts
  Future<Map<String, dynamic>?> _getUserDataByEmail(String email) async {
    // Define collection and field mapping for each role
    final roleMappings = [
      {'collection': 'receptionist', 'field': 'email'},
      {'collection': 'admin', 'field': 'email'},
      {'collection': 'host', 'field': 'emp_email'},
      {'collection': 'department', 'field': 'd_email'},
    ];
    
    // Try parallel queries with shorter timeout
    final futures = roleMappings.map((mapping) async {
      try {
        final query = await _firestore
            .collection(mapping['collection']!)
            .where(mapping['field']!, isEqualTo: email)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 3)); // Reduced timeout
        
        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data();
          data['role'] = mapping['collection'];
          return data;
        }
      } catch (e) {
        // Return null if this query fails
        return null;
      }
      return null;
    });
    
    // Wait for all queries to complete
    final results = await Future.wait(futures);
    
    // Return the first non-null result
    for (final result in results) {
      if (result != null) {
        return result;
      }
    }
    
    return null;
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
        ).timeout(const Duration(seconds: 8)); // Reduced timeout
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
        } else if (e.code == 'network-request-failed') {
          message = 'Network error. Please check your internet connection.';
        } else if (e.code == 'timeout') {
          message = 'Login timeout. Please try again.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } on TimeoutException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login timeout. Please check your internet connection and try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
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
              padding: const EdgeInsets.all(SystemTheme.spacing24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo and Welcome Card
                  Container(
                    padding: const EdgeInsets.all(SystemTheme.spacing24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(SystemTheme.radiusLarge),
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
                          padding: const EdgeInsets.all(SystemTheme.spacing16),
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
                        const SizedBox(height: SystemTheme.spacing16),
                        Text(
                          'Welcome Back',
                          style: SystemTheme.heading2.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: SystemTheme.spacing8),
                        Text(
                          'Sign in to continue',
                          style: SystemTheme.bodyLarge.copyWith(color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SystemTheme.spacing32),
                  // Sign In Form
                  Container(
                    padding: const EdgeInsets.all(SystemTheme.spacing24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(SystemTheme.radiusLarge),
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
                            decoration: SystemTheme.inputDecoration(
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
                          const SizedBox(height: SystemTheme.spacing16),
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _signIn(),
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: SystemTheme.inputDecoration(
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
                          const SizedBox(height: SystemTheme.spacing24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              style: SystemTheme.primaryButtonStyle,
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
          style: SystemTheme.bodyLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}