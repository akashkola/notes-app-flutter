import 'package:flutter/material.dart';

import 'package:notes_app_yt/services/auth/auth_service.dart';
import 'package:notes_app_yt/services/crud/notes_service.dart';
import 'package:notes_app_yt/utilities/generics/get_arguments.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  DatabaseNote? _note;
  late final NotesService _notesService;
  late final TextEditingController _textController;

  @override
  void initState() {
    _notesService = NotesService();
    _textController = TextEditingController();
    super.initState();
  }

  Future<void> _textControllerListener() async {
    final note = _note;
    if (note != null) {
      await _notesService.updateNote(
        note: note,
        text: _textController.text,
      );
    }
  }

  void _setupTextControllerListener() {
    _textController.removeListener(_textControllerListener);
    _textController.addListener(_textControllerListener);
  }

  Future<DatabaseNote> _createOrGetExistingNote(BuildContext context) async {
    final widgetNote = context.getArgument<DatabaseNote>();
    if (widgetNote != null) {
      _note = widgetNote;
      _textController.text = widgetNote.text;
      return widgetNote;
    }

    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }
    final currentUser = AuthService.fromFirebase().currentUser!;
    final owner = await _notesService.getUser(email: currentUser.email!);
    final newNote = await _notesService.createNote(owner: owner);
    _note = newNote;
    return newNote;
  }

  Future<void> _deleteNoteIfTextIsEmpty() async {
    final note = _note;
    if (note != null && _textController.text.isEmpty) {
      await _notesService.deleteNote(id: note.id);
    }
  }

  Future<void> _saveNoteIfTextIsNotEmpty() async {
    final note = _note;
    final text = _textController.text;
    if (note != null && text.isNotEmpty) {
      await _notesService.updateNote(
        note: note,
        text: text,
      );
    }
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextIsNotEmpty();
    // _notesService.close();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Note"),
      ),
      body: FutureBuilder(
        future: _createOrGetExistingNote(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _setupTextControllerListener();
              return TextField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: "Start typing your note...",
                ),
              );
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
