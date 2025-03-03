import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gipaw_tailor/homepage.dart';
import 'package:gipaw_tailor/signinpage/admindash.dart';
import 'package:gipaw_tailor/signinpage/authorization.dart';
import 'package:gipaw_tailor/signinpage/signinpage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String ADMIN_USERNAME_KEY = 'admin_username';
const String ADMIN_PASSWORD_KEY = 'Summerday1998';
const String IS_FIRST_RUN_KEY = 'is_first_run';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  // Check if it's the first run
  final prefs = await SharedPreferences.getInstance();
  final isFirstRun = prefs.getBool(IS_FIRST_RUN_KEY) ?? true;
  AuthProvider();

  runApp(MyApp(isFirstRun: isFirstRun));
}

class MyApp extends StatelessWidget {
  final bool isFirstRun;

  const MyApp({super.key, required this.isFirstRun});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Gipaw Tailor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: isFirstRun ? const AdminSetupPage() : const SignInPage(),
      ),
    );
  }
}

class AdminSetupPage extends StatefulWidget {
  const AdminSetupPage({super.key});

  @override
  _AdminSetupPageState createState() => _AdminSetupPageState();
}

class _AdminSetupPageState extends State<AdminSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Initial Admin Setup'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome! Please set up your admin credentials.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Admin Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  if (value.length < 4) {
                    return 'Username must be at least 4 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Admin Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _setupAdmin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Complete Setup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setupAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Store admin credentials
      await prefs.setString(ADMIN_USERNAME_KEY, _usernameController.text);
      await prefs.setString(ADMIN_PASSWORD_KEY, _passwordController.text);
      await prefs.setBool(IS_FIRST_RUN_KEY, false);

      // Initialize admin user in AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initializeAdmin(
        username: _usernameController.text,
        password: _passwordController.text,
      );

      // Navigate to sign in page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error setting up admin account'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
