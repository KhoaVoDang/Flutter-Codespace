import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'helpers/theme.dart';
import 'screens/home.dart';
import 'screens/welcome.dart';
import 'screens/login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forui/forui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://diivvqktuwuhzocbrvvk.supabase.co', // Replace with your Supabase API URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRpaXZ2cWt0dXd1aHpvY2JydnZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxMzU1NjMsImV4cCI6MjA2MDcxMTU2M30.l7XWnlKNysdGD5_7F5_6hkeFEW4hsaSF_6bmeJBE40k', // Replace with your Supabase API Key
  );

  runApp(
    OverlaySupport.global(
      child: ChangeNotifierProvider(
        create: (context) => ThemeNotifier(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return ShadApp.material(
          title: 'Flutter Demo',
          darkTheme: themeNotifier.currentTheme,
          theme: themeNotifier.currentTheme.copyWith(
            textTheme: ShadTextTheme.fromGoogleFont(
              GoogleFonts.inter,
            ),
          ),
          home: StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final session = snapshot.data!.session;
                if (session != null) {
                  // User is logged in, show Home
                  return const Home();
                } else {
                  // User is not logged in, show Login
                  return const Login();
                }
              } else {
                // Checking auth state, show a loading indicator
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
            },
          ),
          routes: {
            Welcome.id: (_) => Welcome(),
            Login.id: (_) => Login(),
            Home.id: (_) => Home(),
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
