// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:path_provider/path_provider.dart'
//     show getApplicationDocumentsDirectory, MissingPlatformDirectoryException;
// import 'package:path/path.dart' show join;
// import 'package:sqflite/sqflite.dart';
// import 'dart:developer' as devtools show log;

// import 'package:notes_app_yt/services/crud/crud_exceptions.dart';
// import 'package:notes_app_yt/extensions/list/filter.dart';

// @immutable
// class DatabaseUser {
//   final int id;
//   final String email;

//   const DatabaseUser({
//     required this.id,
//     required this.email,
//   });

//   DatabaseUser.fromRow(Map<String, Object?> map)
//       : id = map[idColumn] as int,
//         email = map[emailColumn] as String;

//   @override
//   String toString() => "Person, ID = $id, email = $email";

//   @override
//   bool operator ==(covariant DatabaseUser other) => id == other.id;

//   @override
//   int get hashCode => id.hashCode;
// }

// class DatabaseNote {
//   final int id;
//   final int userId;
//   final String text;
//   final bool isSyncedwithCloud;

//   DatabaseNote({
//     required this.id,
//     required this.userId,
//     required this.text,
//     required this.isSyncedwithCloud,
//   });

//   DatabaseNote.fromRow(Map<String, Object?> map)
//       : id = map[idColumn] as int,
//         userId = map[userIdColumn] as int,
//         text = map[textColumn] as String,
//         isSyncedwithCloud =
//             (map[isSyncedwithCloudColumn] as int) == 0 ? true : false;

//   @override
//   String toString() =>
//       "Note id=$id, userId=$userId, isSyncedWithCloud=$isSyncedwithCloud, text=$text";

//   @override
//   bool operator ==(covariant DatabaseNote other) => id == other.id;

//   @override
//   int get hashCode => id.hashCode;
// }

// class NotesService {
//   Database? _db;

//   List<DatabaseNote> _notes = [];

//   DatabaseUser? _user;

//   // make class singleton
//   NotesService._sharedInstance() {
//     _notesStreamController = StreamController<List<DatabaseNote>>.broadcast(
//       onListen: () {
//         _notesStreamController.sink.add(_notes);
//       },
//     );
//   }
//   static final NotesService _shared = NotesService._sharedInstance();
//   factory NotesService() => _shared;

//   late final StreamController<List<DatabaseNote>> _notesStreamController;

//   Stream<List<DatabaseNote>> get allNotes =>
//       _notesStreamController.stream.filter((note) {
//         final currentUser = _user;
//         if (currentUser != null) {
//           return note.userId == currentUser.id;
//         } else {
//           throw UserShouldBeSetBeforeReadingAllNotesException();
//         }
//       });

//   Future<void> _cacheNotes() async {
//     final allNotes = await getAllNotes();
//     _notes = allNotes.toList();
//     _notesStreamController.add(_notes);
//   }

//   Database _getDatabaseOrThrow() {
//     final db = _db;
//     if (db == null) {
//       throw DatabaseNotOpenedException();
//     } else {
//       return db;
//     }
//   }

//   Future<void> _ensureDbIsOpened() async {
//     try {
//       await open();
//     } on DatabaseArlreadyOpenedException catch (_) {
//       // Do nothing
//     }
//   }

//   Future<DatabaseNote> updateNote({
//     required DatabaseNote note,
//     required String text,
//   }) async {
//     await _ensureDbIsOpened();
//     final db = _getDatabaseOrThrow();
//     final updatedCount = await db.update(
//       noteTable,
//       {
//         textColumn: text,
//         isSyncedwithCloudColumn: 0,
//       },
//       where: 'id = ?',
//       whereArgs: [note.id],
//     );
//     if (updatedCount == 0) {
//       throw CouldNotUpdateNoteException();
//     }
//     final updatedNote = await getNote(id: note.id);
//     _notes.removeWhere((note) => note.id == updatedNote.id);
//     _notes.add(updatedNote);
//     _notesStreamController.add(_notes);
//     return updatedNote;
//   }

//   Future<Iterable<DatabaseNote>> getAllNotes() async {
//     await _ensureDbIsOpened();
//     final db = _getDatabaseOrThrow();
//     final results = await db.query(noteTable);
//     final notes = results.map((row) => DatabaseNote.fromRow(row));
//     return notes;
//   }

//   Future<DatabaseNote> getNote({required int id}) async {
//     await _ensureDbIsOpened();
//     final db = _getDatabaseOrThrow();
//     final results = await db.query(
//       noteTable,
//       limit: 1,
//       where: "id = ?",
//       whereArgs: [id],
//     );
//     if (results.isEmpty) {
//       throw NoteNotFoundException();
//     }
//     final note = DatabaseNote.fromRow(results.first);
//     _notes.removeWhere((note) => note.id == id);
//     _notes.add(note);
//     _notesStreamController.add(_notes);
//     return note;
//   }

//   Future<int> deleteAllNotes() async {
//     await _ensureDbIsOpened();
//     final db = _getDatabaseOrThrow();

//     final numberOfDeletions = await db.delete(noteTable);
//     _notes = [];
//     _notesStreamController.add(_notes);

//     return numberOfDeletions;
//   }

//   Future<void> deleteNote({required int id}) async {
//     await _ensureDbIsOpened();
//     final db = _getDatabaseOrThrow();
//     final deletedCount = await db.delete(
//       noteTable,
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//     if (deletedCount == 0) {
//       throw NoteNotFoundException();
//     } else {
//       _notes.removeWhere((note) => note.id == id);
//       _notesStreamController.add(_notes);
//     }
//   }

//   Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
//     await _ensureDbIsOpened();
//     final db = _getDatabaseOrThrow();

//     // make sure owner exists in the database with the correct id
//     final dbUser = await getUser(email: owner.email);
//     if (owner != dbUser) {
//       throw UserNotFoundException();
//     }

//     const text = '';
//     final id = await db.insert(noteTable, {
//       userIdColumn: owner.id,
//       textColumn: text,
//       isSyncedwithCloudColumn: 1,
//     });

//     final note = DatabaseNote(
//       id: id,
//       userId: owner.id,
//       text: text,
//       isSyncedwithCloud: true,
//     );

//     _notes.add(note);
//     _notesStreamController.add(_notes);

//     return note;
//   }

//   Future<DatabaseUser> getOrCreateUser({
//     required String email,
//     bool setAsCurrentUser = true,
//   }) async {
//     // await _ensureDbIsOpened();
//     try {
//       final user = await getUser(email: email);
//       if (setAsCurrentUser) {
//         _user = user;
//       }
//       return user;
//     } on UserNotFoundException catch (_) {
//       final newUser = await createUser(email: email);
//       if (setAsCurrentUser) {
//         _user = newUser;
//       }
//       return newUser;
//     } catch (e) {
//       devtools.log(e.toString());
//       rethrow;
//     }
//   }

//   Future<DatabaseUser> getUser({required String email}) async {
//     await _ensureDbIsOpened();
//     final db = _getDatabaseOrThrow();
//     final results = await db.query(
//       userTable,
//       limit: 1,
//       where: 'email = ?',
//       whereArgs: [email.toLowerCase()],
//     );
//     if (results.isEmpty) {
//       throw UserNotFoundException();
//     }

//     return DatabaseUser.fromRow(results.first);
//   }

//   Future<DatabaseUser> createUser({required String email}) async {
//     await _ensureDbIsOpened();
//     final db = _getDatabaseOrThrow();
//     final results = await db.query(
//       userTable,
//       limit: 1,
//       where: 'email = ?',
//       whereArgs: [email.toLowerCase()],
//     );
//     if (results.isNotEmpty) {
//       throw UserAlreadyExistsException();
//     }

//     final id = await db.insert(userTable, {
//       emailColumn: email.toLowerCase(),
//     });

//     return DatabaseUser(
//       id: id,
//       email: email,
//     );
//   }

//   Future<void> deleteUser({required String email}) async {
//     await _ensureDbIsOpened();
//     final db = _getDatabaseOrThrow();
//     final deletedCount = await db.delete(
//       userTable,
//       where: 'email = ?',
//       whereArgs: [email.toLowerCase()],
//     );
//     if (deletedCount == 0) {
//       throw CouldNotDeleteUserException();
//     }
//   }

//   Future<void> close() async {
//     final db = _getDatabaseOrThrow();
//     await db.close();
//     _db = null;
//   }

//   Future<void> open() async {
//     if (_db != null) {
//       throw DatabaseArlreadyOpenedException();
//     }
//     try {
//       final docsPath = await getApplicationDocumentsDirectory();
//       final dbPath = join(docsPath.path, dbName);
//       final db = await openDatabase(dbPath);
//       _db = db;

//       await db.execute(createUsersTable);
//       await db.execute(createNotesTable);

//       await _cacheNotes();
//     } on MissingPlatformDirectoryException catch (_) {
//       throw UnableToGetDocumentsDirectoryException();
//     } catch (e) {
//       devtools.log(e.toString());
//     }
//   }
// }

// // columns
// const idColumn = 'id';
// const emailColumn = 'email';
// const userIdColumn = 'user_id';
// const textColumn = 'text';
// const isSyncedwithCloudColumn = 'is_synced_with_cloud';

// // db, tables
// const dbName = 'notes.db';
// const userTable = 'user';
// const noteTable = 'note';

// // queries
// const createUsersTable = '''CREATE TABLE IF NOT EXISTS "user" (
//         "id"	INTEGER NOT NULL,
//         "email"	INTEGER NOT NULL UNIQUE,
//         PRIMARY KEY("id" AUTOINCREMENT)
//       );''';

// const createNotesTable = '''CREATE TABLE IF NOT EXISTS "note" (
//         "id"	INTEGER NOT NULL,
//         "user_id"	INTEGER NOT NULL,
//         "text"	TEXT,
//         "is_synced_with_cloud"	INTEGER DEFAULT 0,
//         FOREIGN KEY("user_id") REFERENCES "user"("id"),
//         PRIMARY KEY("id" AUTOINCREMENT)
//       );''';
