import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learn_with_ar/modals/avatar.dart';
import 'dart:async';

class AvatarRepo {
  final avatarReference = FirebaseFirestore.instance.collection('modal');
  List<Avatar> convertAvatar(QuerySnapshot snapshot) {
    return snapshot.docs.map((e) {
      Map<String, dynamic> item = e.data();
      try {
        var here = createAvatar(item);
        here.id = e.id;
        return here;
      } catch (error) {
        print(error.toString());
      }
    }).toList();
  }

  Stream<List<Avatar>> get avatars {
    return avatarReference.snapshots().map(
          (event) => convertAvatar(event),
        );
  }

  Future<void> updateLikes(Avatar curr) {
    print(curr.id);
    return avatarReference.doc(curr.id).update({'likes': curr.likes});

  }
}
