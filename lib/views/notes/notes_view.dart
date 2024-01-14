import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

import 'package:notes_app_yt/constants/routes.dart';
import 'package:notes_app_yt/enums/menu_action.dart';
import 'package:notes_app_yt/services/auth/auth_service.dart';
import 'package:notes_app_yt/services/cloud/cloud_note.dart';
import 'package:notes_app_yt/services/cloud/firebase_cloud_storage.dart';
import 'package:notes_app_yt/utilities/dialogs/logout_dialog.dart';
import 'package:notes_app_yt/views/notes/notes_list_view.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  late final FirebaseCloudStorae _notesService;
  String get userId => AuthService.fromFirebase().currentUser!.id;

  @override
  void initState() {
    _notesService = FirebaseCloudStorae();
    // Don't need anymore as we added auto open database functionality
    // _notesService.open();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Your Notes"),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed(createOrUpdateNoteRoute);
              },
              icon: const Icon(Icons.add),
            ),
            PopupMenuButton<MenuAction>(
              onSelected: (value) async {
                switch (value) {
                  case MenuAction.logout:
                    final logout = await showLogoutDialog(context);
                    devtools.log(logout.toString());
                    if (logout) {
                      await AuthService.fromFirebase().logOut();
                      context.mounted
                          ? Navigator.of(context).pushNamedAndRemoveUntil(
                              loginRoute,
                              (route) => false,
                            )
                          : null;
                    }
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem<MenuAction>(
                    value: MenuAction.logout,
                    child: Text("Log out"),
                  ),
                ];
              },
            )
          ],
        ),
        body: StreamBuilder(
          stream: _notesService.allNotes(ownerUserId: userId),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
              case ConnectionState.active:
                if (snapshot.hasData) {
                  final allNotes = snapshot.data as Iterable<CloudNote>;
                  return NotesListView(
                    notes: allNotes,
                    onDeleteNote: (note) async {
                      await _notesService.deleteNote(
                          documentId: note.documentId);
                    },
                    onTap: (note) {
                      Navigator.of(context).pushNamed(
                        createOrUpdateNoteRoute,
                        arguments: note,
                      );
                    },
                  );
                }
                return const CircularProgressIndicator();
              default:
                return const CircularProgressIndicator();
            }
          },
        ));
  }
}
