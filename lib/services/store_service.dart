import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:florista/models/StoreModel.dart';

class StoreService {
  static Future<List<StoreModel>> fetchStores() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('stores').get();

    return snapshot.docs
        .map((doc) => StoreModel.fromMap(doc.data(), doc.id)) // ✅ Kirim doc.id
        .toList();
  }

  static Future<void> addStore(StoreModel store) async {
    await FirebaseFirestore.instance.collection('stores').add(store.toMap());
  }
}
