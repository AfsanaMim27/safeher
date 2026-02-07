import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final _firestore = FirebaseFirestore.instance;

  Stream<AppUser> getUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
          (doc) => AppUser.fromMap(doc.data()!),
    );
  }
}
