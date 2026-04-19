import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/models/volunteer_info_model.dart';

class VolunteerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<VolunteerInfo?> get(String uid) async {
    final doc = await _firestore.collection('volunteer_info').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;

    // Convert the Firestore Map to the VolunteerInfo model
    return VolunteerInfo.fromJson(doc.data()!);
  }

  // SET/CREATE: Save or overwrite the volunteer info document
  Future<void> saveInfo(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('volunteer_info').doc(uid).set(data);
  }

  // UPDATE: Generic update for the volunteer info document
  Future<void> update(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('volunteer_info').doc(uid).update(data);
  }
}
