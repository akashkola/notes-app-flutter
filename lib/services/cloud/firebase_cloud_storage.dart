import 'dart:developer' as devtools show log;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:notes_app_yt/services/cloud/cloud_note.dart';
import 'package:notes_app_yt/services/cloud/cloud_storage_constants.dart';
import 'package:notes_app_yt/services/cloud/cloud_storage_exceptions.dart';

class FirebaseCloudStorae {
  final notesCollection =
      FirebaseFirestore.instance.collection(notesCollectionName);

  // listen to changes in stream
  // collectionRef.snapshots returns a stream of querysnapsho
  Stream<Iterable<CloudNote>> allNotes({required String ownerUserId}) =>
      notesCollection.snapshots().map((event) => event.docs
          .map((doc) => CloudNote.fromSnapshot(doc))
          .where((note) => note.ownerUserId == ownerUserId));

  // singleton
  static final _shared = FirebaseCloudStorae._sharedInstance();
  FirebaseCloudStorae._sharedInstance();
  factory FirebaseCloudStorae() => _shared;

  Future<CloudNote> createNewNote({required String ownerUserId}) async {
    final document = await notesCollection.add({
      ownerUserIdFieldName: ownerUserId,
      textFieldName: '',
    });

    final fetchedNote = await document.get();
    return CloudNote(
      documentId: fetchedNote.id,
      text: '',
      ownerUserId: ownerUserId,
    );
  }

  Future<Iterable<CloudNote>> getNotes({required String userId}) async {
    try {
      final userNotes = await notesCollection
          .where(
            ownerUserIdFieldName,
            isEqualTo: userId,
          )
          .get();
      return userNotes.docs.map((note) => CloudNote.fromSnapshot(note));
    } catch (e) {
      devtools.log(e.toString());
      throw CouldNotGetAllNotesException();
    }
  }

  Future<void> updateNote({
    required String documentId,
    required String text,
  }) async {
    try {
      await notesCollection.doc(documentId).update({
        textFieldName: text,
      });
    } catch (e) {
      devtools.log(e.toString());
      throw CouldNotUpdateNoteException();
    }
  }

  Future<void> deleteNote({required String documentId}) async {
    try {
      await notesCollection.doc(documentId).delete();
    } catch (e) {
      devtools.log(e.toString());
      throw CouldNotDeleteNoteException();
    }
  }
}
