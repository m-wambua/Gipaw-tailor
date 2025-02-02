import 'package:flutter/material.dart';
import 'package:gipaw_tailor/homepage.dart';
import 'package:gipaw_tailor/signinpage/authorization.dart';
import 'package:gipaw_tailor/signinpage/signuppage.dart';
import 'package:gipaw_tailor/signinpage/users.dart';
import 'package:provider/provider.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  SignInMethod _method = SignInMethod.email;
  String get _identifierLabel {
    switch (_method) {
      case SignInMethod.username:
        return 'Username';
      case SignInMethod.email:
        return 'Email';
      case SignInMethod.phoneNumber:
        return 'Phone Number';
    }
  }

  String? _validateIdentifier(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your $_identifierLabel';
    }
    switch (_method) {
      case SignInMethod.email:
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        break;
      case SignInMethod.phoneNumber:
        final phoneRegex = RegExp(r'^\+?[\d\s-]+$');
        if (!phoneRegex.hasMatch(value)) {
          return 'Please enter a valid phone number';
        }
        break;
      case SignInMethod.username:
        if (value.length < 3) {
          return 'Username must be at least 3 characters long';
        }
        break;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Sign In'),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SegmentedButton<SignInMethod>(
                    segments: [
                      ButtonSegment(
                          value: SignInMethod.username,
                          label: Text("Username")),
                      ButtonSegment(
                          value: SignInMethod.email, label: Text("Email")),
                      ButtonSegment(
                          value: SignInMethod.phoneNumber,
                          label: Text("Phone Number")),
                    ],
                    selected: {_method},
                    onSelectionChanged: (Set<SignInMethod> selected) {
                      setState(() {
                        _method = selected.first;
                        _identifierController.clear();
                      });
                    },
                  ),
                  SizedBox(
                    height: 24,
                  ),
                  TextFormField(
                    controller: _identifierController,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: _identifierLabel,
                        hintText: 'Enter your $_identifierLabel'),
                    validator: _validateIdentifier,
                    keyboardType: _method == SignInMethod.phoneNumber
                        ? TextInputType.phone
                        : _method == SignInMethod.email
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                        hintText: 'Enter your password'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),
                  SizedBox(
                    height: 24,
                  ),
                  ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final success = await context
                              .read<AuthProvider>()
                              .signIn(_identifierController.text,
                                  _passwordController.text, _method);
                          if (success) {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MyHomePage()));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Invalid $_identifierLabel or password. Please try again'),
                              backgroundColor: Colors.red,
                            ));
                          }
                        }
                      },
                      child: Text("Sign in"))
                ],
              ),
            )));
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Sign In'),
            content: Column(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(labelText: 'Email/Usernmae'),
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                )
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Sign In'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }
}
