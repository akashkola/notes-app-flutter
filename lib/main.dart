import 'package:flutter/material.dart';

import 'package:notes_app_yt/constants/routes.dart';
import 'package:notes_app_yt/services/auth/auth_service.dart';
import 'package:notes_app_yt/views/login_view.dart';
import 'package:notes_app_yt/views/notes/create_update_note_view.dart';
import 'package:notes_app_yt/views/notes/notes_view.dart';
import 'package:notes_app_yt/views/register_view.dart';
import 'package:notes_app_yt/views/verify_email_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
        ),
        useMaterial3: true,
      ),
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
        notesRoute: (context) => const NotesView(),
        verifyEmailRoute: (context) => const VerifyEmailView(),
        createOrUpdateNoteRoute: (context) => const CreateUpdateNoteView(),
      },
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.fromFirebase().initialize(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            final user = AuthService.fromFirebase().currentUser;
            if (user == null) {
              return const LoginView();
            }
            if (!user.isEmailVerified) {
              return const VerifyEmailView();
            }

            return const NotesView();

          default:
            return const CircularProgressIndicator();
        }
      },
    );
  }
}
