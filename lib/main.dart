import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/theme.dart';
import 'screens/home.dart';
import 'screens/welcome.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? enteredValue = prefs.getString('entered_value');
  print("Entered Value: $enteredValue"); // Debug print to check enteredValue
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeNotifier(),
      child: MyApp(enteredValue: enteredValue),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? enteredValue;
  const MyApp({required this.enteredValue, super.key});

  @override
  Widget build(BuildContext context) {
    print(
        "Initial Route: ${enteredValue != null ? Home.id : Welcome.id}"); // Debug print to check initialRoute

    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return ShadApp.material(
          title: 'Flutter Demo',
          //    textTheme: themeNotifier.currentTheme.textTheme,
          darkTheme: themeNotifier.currentTheme,
          theme: themeNotifier.currentTheme.copyWith(
            textTheme: ShadTextTheme.fromGoogleFont(
              GoogleFonts.inter,
            ),
          ),
          //   themeMode: ThemeMode.light,
          initialRoute: enteredValue != null ? Home.id : Welcome.id,
          routes: {
            Welcome.id: (_) => Welcome(),
            Home.id: (_) => Home(),
            // Login.id: (_) => Login(),
            // ColorSelectionScreen.id: (_) => ColorSelectionScreen(),
          },
        );
      },
    );
  }
}

class TaskListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Colors.white.withOpacity(0.8), // Adjust opacity as needed
        elevation: 0, // Remove shadow
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.purple
                  .shade100, // Placeholder for the toggle button background
              borderRadius:
                  BorderRadius.circular(20), // Adjust radius as needed
            ),
            width: 40,
            height: 40,
            child: Center(
              child: Icon(Icons.circle,
                  color: Colors.purple), // Placeholder for the inner circles
            ),
          ),
        ),
        actions: [
          IconButton(
            icon:
                Icon(Icons.menu, color: Colors.black87), // Hamburger menu icon
            onPressed: () {
              // Handle menu action
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        // To handle potential overflow
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hey, Khoa!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You have 4 task to complete',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              Text(
                'Pinned',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.blue.shade100
                          .withOpacity(0.8), // Placeholder color
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.radio_button_unchecked), // Empty circle
                            SizedBox(height: 8),
                            Text('Meeting'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      color: Colors.blue.shade100
                          .withOpacity(0.8), // Placeholder color
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors
                                    .purple), // Filled circle with checkmark
                            SizedBox(height: 8),
                            Text(
                              'Lorem- ipsum dolor sit amet,',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'Todo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.radio_button_unchecked),
                      SizedBox(width: 12),
                      Text('Meeting'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.radio_button_unchecked),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Lorem ipsum dolor sit amet, consetetur',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.radio_button_unchecked),
                      SizedBox(width: 12),
                      Text('Meeting'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle add new task
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
