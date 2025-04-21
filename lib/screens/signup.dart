import 'package:shadcn_ui/shadcn_ui.dart';
 import 'package:flutter/material.dart';
 import 'home.dart';
 import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
 import 'login.dart'; // Import Login screen for navigation

 class Signup extends StatefulWidget {
   const Signup({super.key});
   static const id = 'signup_screen';
   @override
   State<Signup> createState() => _SignupState();
 }

 class _SignupState extends State<Signup> {
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

   Future<void> _signUp() async {
     if (formKey.currentState!.saveAndValidate()) {
       setState(() {
         _isLoading = true;
         _errorMessage = null;
       });
       try {
         final email = _emailController.text.trim();
         final password = _passwordController.text.trim();
         await Supabase.instance.client.auth.signUp(
           email: email,
           password: password,
         );
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Sign up successful! Please check your email to confirm.')),
         );
         Navigator.pushReplacement(
           context,
           MaterialPageRoute(builder: (context) => const Login()),
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

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       resizeToAvoidBottomInset: true,
       body: Padding(
         padding: const EdgeInsets.only(
             left: 32.0, top: 10.0, right: 32.0, bottom: 10.0),
         child: Center(
           child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               crossAxisAlignment: CrossAxisAlignment.center,
               children: [
                 Image(image: AssetImage("lib/assets/icon/logo_png.png"),
                     width: 50,
                     height: 50),
                 const SizedBox(height: 8),
                 Text(
                   'Join our community!',
                   style: ShadTheme.of(context).textTheme.h4,
                 ),
                 Text("Create an account to save all of your todo and progress",
                     style: ShadTheme.of(context).textTheme.muted),
                 if (_errorMessage != null)
                   Padding(
                     padding: const EdgeInsets.only(bottom: 16.0),
                     child: Text(
                       _errorMessage!,
                       style: const TextStyle(color: Colors.red),
                     ),
                   ),
                 ShadForm(
                   key: formKey,
                   child: ConstrainedBox(
                     constraints: const BoxConstraints(maxWidth: 350),
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
                           suffix: ShadButton(
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
                         const SizedBox(height: 8),
                         ShadButton(
                           width: double.infinity,
                      //     isLoading: _isLoading,
                           child: const Text("Create an account"),
                           onPressed: _isLoading ? null : _signUp,
                         ),
                         Row(
                           children: [
                             const Expanded(child: Divider()),
                             Text("or",
                                 style: ShadTheme.of(context).textTheme.muted),
                             const Expanded(child: Divider()),
                           ],
                         ),
                         ShadButton.secondary(
                           width: double.infinity,
                           icon: const Icon(LucideIcons.mail, size: 16),
                           child: const Text(" Sign up with Google"),
                           onPressed: () {
                             // Implement Google signup using Supabase
                             print('Sign up with Google pressed');
                           },
                         ),
                         Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             ShadButton.link(
                               child: Text("Nah I'm good",
                                   style: TextStyle(
                                       color: ShadTheme.of(context)
                                           .textTheme
                                           .muted
                                           .color)),
                               onPressed: () {
                                 Navigator.pushReplacement(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => const Home(),
                                   ),
                                 );
                               },
                             ),
                             ShadButton.link(
                               child: const Text("I already have an account",
                                   style: TextStyle(
                                       decoration: TextDecoration.underline)),
                               onPressed: () {
                                 Navigator.pop(context); // Go back to login
                               },
                             )
                           ],
                         ),
                       ],
                     ),
                   ),
                 )
               ]),
         ),
       ),
     );
   }
 }