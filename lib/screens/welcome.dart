import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart';
import 'home.dart';

import 'package:shared_preferences/shared_preferences.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});
  static const id = 'welcome_screen';
  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  final formKey = GlobalKey<ShadFormState>();
    @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }
   void initState() {
    super.initState();
    getName();
  }
   void getName() async {
     SharedPreferences prefs = await SharedPreferences.getInstance();
     _textFieldController.text = prefs.getString('entered_value') ?? '';
  }

  final TextEditingController _textFieldController = TextEditingController();
    Future<void> _storeValueAndNavigate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('entered_value', _textFieldController.text);
    // ignore: use_build_context_synchronously
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>  Home(),
      ),
    );
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello,',
                  style: ShadTheme.of(context).textTheme.h4,
                ),
                 Text(
                  'Nice to meet you',
                  style: ShadTheme.of(context).textTheme.h4,
                ),
                Text(
                  "Let's start with your name",
                  style: ShadTheme.of(context).textTheme.muted
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
                      controller: _textFieldController,
                           style: ShadTheme.of(context).textTheme.h4.copyWith(fontSize: 30),
                       id: 'username',
                      // label: const Text('Username'),
                   //    placeholder: const Text('Enter your username'),
                     //  description: const Text('This is your public display name.'),
                       validator: (v) {
                         if (v.length < 2) {
                           return 'Username must be at least 2 characters.';
                         }
                         return null;
                       },
                     ),
                     const SizedBox(height: 8),
                     ShadButton(
                       child: const Text('Let me in'),
                       onPressed: () {
                         if (formKey.currentState!.saveAndValidate()) {
                          _storeValueAndNavigate();
                           print(
                               'validation succeeded with ${formKey.currentState!.value}');
                         } else {
                           print('validation failed');
                         }
                       },
                     ),
                   ],
                 ),
               ),)
              ]),
        ),
      ),
    );
  }
}
