import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } else {
      _showErrorDialog(authProvider.error ?? 'Login failed');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return LoadingOverlay(
              isLoading: authProvider.isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    
                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 80,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: const Icon(
                              Icons.shopping_bag,
                              color: Colors.white,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Title
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    const Text(
                      'Sign in to continue shopping',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Login Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            hintText: 'Enter your email',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!AppConstants.emailRegex.hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hintText: 'Enter your password',
                            obscureText: _obscurePassword,
                            prefixIcon: Icons.lock_outlined,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword 
                                ? Icons.visibility_outlined 
                                : Icons.visibility_off_outlined),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
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
                          
                          const SizedBox(height: 16),
                          
                          // Remember Me & Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                    activeColor: AppColors.primary,
                                  ),
                                  const Text(
                                    'Remember me',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    ForgotPasswordScreen.routeName,
                                  );
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Login Button
                          CustomButton(
                            text: 'Sign In',
                            onPressed: _login,
                            backgroundColor: AppColors.primary,
                            textColor: Colors.white,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Social Login
                          const Text(
                            'or continue with',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _SocialLoginButton(
                                icon: 'assets/images/google_icon.png',
                                label: 'Google',
                                onPressed: () {
                                  // TODO: Implement Google Sign In
                                },
                              ),
                              _SocialLoginButton(
                                icon: 'assets/images/facebook_icon.png',
                                label: 'Facebook',
                                onPressed: () {
                                  // TODO: Implement Facebook Sign In
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              RegisterScreen.routeName,
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                icon,
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}