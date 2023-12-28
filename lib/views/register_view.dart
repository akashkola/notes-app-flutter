import 'package:flutter/material.dart';

import 'package:notes_app_yt/constants/routes.dart';
import 'package:notes_app_yt/services/auth/auth_exceptions.dart';
import 'package:notes_app_yt/services/auth/auth_service.dart';
import 'package:notes_app_yt/utilities/dialogs/error_dialog.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
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
        title: const Text("Register"),
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
            onPressed: () async {
              final email = _emailController.text;
              final password = _passwordController.text;

              try {
                await AuthService.fromFirebase().createUser(
                  email: email,
                  password: password,
                );

                await AuthService.fromFirebase().sendEmailVerification();

                context.mounted
                    ? Navigator.of(context).pushNamed(verifyEmailRoute)
                    : null;
              } on EmailAlreadyTakenAuthException catch (_) {
                context.mounted
                    ? await showErrorDialog(
                        context,
                        "Email already taken",
                      )
                    : null;
              } on WeakPasswordAuthException catch (_) {
                context.mounted
                    ? await showErrorDialog(
                        context,
                        "Weak password",
                      )
                    : null;
              } on InvalidEmailAuthException catch (_) {
                context.mounted
                    ? await showErrorDialog(
                        context,
                        "Invalid email",
                      )
                    : null;
              } on GenericAuthException catch (_) {
                context.mounted
                    ? await showErrorDialog(
                        context,
                        "Failed to register",
                      )
                    : null;
              }
            },
            child: const Text("Register"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                loginRoute,
                (route) => false,
              );
            },
            child: const Text("Already registered?Login here!"),
          )
        ],
      ),
    );
  }
}
