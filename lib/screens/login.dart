import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'signup.dart';
// Import Supabase

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
                 Image(image: AssetImage("lib/assets/icon/logo.png"),
                     width: 50,
                     height: 50),
                 const SizedBox(height: 8),
                 Text(
                   'Got it cover if you got roped',
                   style: ShadTheme.of(context).textTheme.h4,
                 ),
                 Text("Save all of your todo and progress by logging in",
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
                         //  isLoading: _isLoading,
                           child: const Text("Login"),
                           onPressed: _isLoading ? null : _signIn,
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
                           child: const Text(" Login with Google"),
                           onPressed: () {
                             // Implement Google login using Supabase
                             print('Login with Google pressed');
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
                               child: const Text("Create an account",
                                   style: TextStyle(
                                       decoration: TextDecoration.underline)),
                               onPressed: () {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                       builder: (context) =>  Signup()),
                                 );
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