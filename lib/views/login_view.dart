import 'package:flutter/material.dart';

import 'package:notes_app_yt/constants/routes.dart';
import 'package:notes_app_yt/services/auth/auth_exceptions.dart';
import 'package:notes_app_yt/services/auth/auth_service.dart';
import 'package:notes_app_yt/utilities/dialogs/error_dialog.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: Column(
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: "Enter your email here",
            ),
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: "Enter your password here",
            ),
          ),
          TextButton(
            child: const Text("Login"),
            onPressed: () async {
              final email = _emailController.text;
              final password = _passwordController.text;

              try {
                await AuthService.fromFirebase().logIn(
                  email: email,
                  password: password,
                );

                final user = AuthService.fromFirebase().currentUser;

                if (user?.isEmailVerified ?? false) {
                  context.mounted
                      ? Navigator.of(context).pushNamedAndRemoveUntil(
                          notesRoute,
                          (route) => false,
                        )
                      : null;
                } else {
                  context.mounted
                      ? Navigator.of(context).pushNamedAndRemoveUntil(
                          verifyEmailRoute,
                          (route) => false,
                        )
                      : null;
                }
              } on InvalidCredentialsAuthException catch (_) {
                context.mounted
                    ? await showErrorDialog(
                        context,
                        "Invalid credentials",
                      )
                    : null;
              } on GenericAuthException catch (_) {
                context.mounted
                    ? await showErrorDialog(
                        context,
                        'Authentication Error',
                      )
                    : null;
              }
            },
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                registerRoute,
                (route) => false,
              );
            },
            child: const Text("Not registered yet? Register here!"),
          ),
        ],
      ),
    );
  }
}
