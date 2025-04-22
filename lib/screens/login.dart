import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup.dart';

class Login extends StatefulWidget {
  const Login({super.key});
  static const id = 'login_screen';
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final formKey = GlobalKey<ShadFormState>();
  bool obscure = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signIn() async {
    if (formKey.currentState!.saveAndValidate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      } on AuthException catch (error) {
        setState(() {
          _errorMessage = error.message;
        });
      } catch (error) {
        setState(() {
          _errorMessage = 'An unexpected error occurred';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget sectionTitle(String text) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: theme.textTheme.h4?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Divider(thickness: 1, color: theme.colorScheme.border),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image(image: AssetImage("lib/assets/icon/logo.png"), width: 50, height: 50),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back!',
                    style: theme.textTheme.h3,
                  ),
                  Text(
                    "Save all of your todo and progress by logging in",
                    style: theme.textTheme.muted,
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  // sectionTitle("Login"),
                  ShadForm(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShadInputFormField(
                          controller: _emailController,
                          id: 'email',
                          placeholder: const Text('Enter your email'),
                          validator: (v) {
                            if (v == null || v.isEmpty || !v.contains('@')) {
                              return 'Please enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        ShadInputFormField(
                          obscureText: obscure,
                          controller: _passwordController,
                          id: 'password',
                          placeholder: const Text('Enter your password'),
                          validator: (v) {
                            if (v == null || v.isEmpty || v.length < 8) {
                              return 'Password must be at least 8 characters.';
                            }
                            return null;
                          },
                          trailing: ShadButton(
                              trailing: obscure
                                ? const Icon(LucideIcons.eye, size: 16)
                                : const Icon(LucideIcons.eyeClosed, size: 16),
                            width: 24,
                            height: 24,
                            padding: EdgeInsets.zero,
                            decoration: const ShadDecoration(
                              secondaryBorder: ShadBorder.none,
                              secondaryFocusedBorder: ShadBorder.none,
                            ),
                            onPressed: () {
                              setState(() => obscure = !obscure);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        ShadButton(
                          width: double.infinity,
                          child: const Text("Login"),
                          onPressed: _isLoading ? null : _signIn,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text("or", style: theme.textTheme.muted),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),
                  ShadButton.secondary(
                    width: double.infinity,
                    icon: const Icon(Icons.mail, size: 16),
                    child: const Text(" Login with Google"),
                    onPressed: () {
                      // Implement Google login using Supabase
                      print('Login with Google pressed');
                    },
                  ),
                  // sectionTitle("Other"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    
                      ShadButton.link(
                        child: const Text("Create an account",
                            style: TextStyle(
                                decoration: TextDecoration.underline)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Signup()),
                          );
                        },
                      )
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