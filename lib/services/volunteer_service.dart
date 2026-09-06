import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/models/volunteer_info_model.dart';
import 'package:you_app/services/base/ttl_cache.dart';
import 'package:you_app/services/base/firestore_base.dart';

class VolunteerService with FirestoreServiceMixin {
  // Short-lived cache so the home screen's volunteer stream doesn't re-read
  // every volunteer's profile on each tick. Invalidated on writes / sign-out.
  final TtlCache<String, VolunteerInfo> _cache =
      TtlCache<String, VolunteerInfo>(ttl: const Duration(minutes: 5));

  VolunteerInfo? _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    // volunteer_info doc id == user uid; backfill if the field is absent.
    data['uid'] ??= doc.id;
    return VolunteerInfo.fromJson(data);
  }

  Future<VolunteerInfo?> get(String uid) async {
    final cached = _cache.get(uid);
    if (cached != null) return cached;

    final doc = await db.collection('volunteer_info').doc(uid).get();
    final info = _fromDoc(doc);
    if (info != null) _cache.put(uid, info);
    return info;
  }

  /// Batch-fetches volunteer info for many uids in one round of queries.
  /// Reads only the uids not already cached, chunked to respect Firestore's
  /// `whereIn` limit (30). Replaces the previous one-query-per-volunteer loop.
  Future<Map<String, VolunteerInfo>> getMany(List<String> uids) async {
    final result = <String, VolunteerInfo>{};
    final missing = <String>[];

    for (final uid in uids) {
      final cached = _cache.get(uid);
      if (cached != null) {
        result[uid] = cached;
      } else {
        missing.add(uid);
      }
    }

    for (final chunk in FirestoreServiceMixin.chunk(missing, 30)) {
      if (chunk.isEmpty) continue;
      final snap = await db
          .collection('volunteer_info')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final info = _fromDoc(doc);
        if (info != null) {
          _cache.put(doc.id, info);
          result[doc.id] = info;
        }
      }
    }

    return result;
  }

  /// Identity-document fields that must NEVER live on the public
  /// `volunteer_info` doc. These are Firebase download URLs carrying their own
  /// access token, so the URL *is* the file — and the public doc is read by
  /// every user browsing the volunteer list.
  static const vettingFields = <String>[
    'idCardUrl',
    'idCardBackUrl',
    'studentIdUrl',
    'studentIdBackUrl',
  ];

  /// SET/CREATE: save the volunteer info document.
  ///
  /// Vetting URLs are split out into `volunteer_info/{uid}/private/vetting`,
  /// which the rules restrict to the owner and admins. Both writes go in one
  /// batch so a volunteer's application can never land half-written.
  Future<void> saveInfo(String uid, Map<String, dynamic> data) async {
    final public = Map<String, dynamic>.from(data)
      ..removeWhere((k, _) => vettingFields.contains(k));
    final vetting = <String, dynamic>{
      for (final k in vettingFields)
        if (data.containsKey(k)) k: data[k],
    };

    final batch = db.batch();
    final infoRef = db.collection('volunteer_info').doc(uid);
    batch.set(infoRef, public);
    if (vetting.isNotEmpty) {
      batch.set(infoRef.collection('private').doc('vetting'), vetting,
          SetOptions(merge: true));
    }
    await batch.commit();
    _cache.invalidate(uid);
  }

  /// Reads a volunteer's vetting documents. Permitted only for the volunteer
  /// themselves and for admins; anyone else gets a permission error.
  Future<Map<String, dynamic>?> getVetting(String uid) async {
    final doc = await db
        .collection('volunteer_info')
        .doc(uid)
        .collection('private')
        .doc('vetting')
        .get();
    return doc.data();
  }

  /// UPDATE: generic update for the volunteer info document.
  ///
  /// Asserts in debug that no vetting field is being written to the public doc
  /// — those belong in the private subcollection (see [saveInfo]).
  Future<void> update(String uid, Map<String, dynamic> data) async {
    assert(
      !data.keys.any(vettingFields.contains),
      'Vetting URLs must not be written to the public volunteer_info doc. '
      'Use saveInfo(), which routes them to volunteer_info/$uid/private/vetting.',
    );
    await db.collection('volunteer_info').doc(uid).update(data);
    _cache.invalidate(uid);
  }

  /// Clears all cached volunteer info (call on sign-out).
  void clearCache() => _cache.clear();

  /// Adds a review for a volunteer and updates their overall statistics.
  ///
  /// When [requestId] is supplied, the request's `userReviewed` flag is flipped
  /// to true inside the SAME transaction as the rating update. This makes the
  /// whole review atomic: the volunteer's aggregate stats and the
  /// "already reviewed" marker commit together or not at all, so a failure
  /// mid-way can never leave the request re-promptable (which would let the
  /// same chat be rated twice and double-count the volunteer's average).
  Future<void> addReviewAndCompleteChat({
    required String volunteerId,
    required String userId,
    required double rating,
    required String comment,
    String? requestId,
  }) async {
    final volunteerRef = db.collection('volunteer_info').doc(volunteerId);
    final reviewsRef = volunteerRef.collection('reviews').doc();
    final requestRef = requestId != null
        ? db.collection('chat_requests').doc(requestId)
        : null;

    await db.runTransaction((transaction) async {
      final volunteerDoc = await transaction.get(volunteerRef);

      if (!volunteerDoc.exists) {
        throw Exception("Volunteer not found");
      }

      final data = volunteerDoc.data()!;
      int completedChats = data['completedChats'] ?? 0;
      int totalReviews = data['totalReviews'] ?? 0;
      double averageRating = (data['averageRating'] ?? 0.0).toDouble();

      // Calculate new averages
      double newAverageRating =
          ((averageRating * totalReviews) + rating) / (totalReviews + 1);

      // Update volunteer document
      transaction.update(volunteerRef, {
        'completedChats': completedChats + 1,
        'totalReviews': totalReviews + 1,
        'averageRating': newAverageRating,
      });

      // Add the review document
      transaction.set(reviewsRef, {
        'userId': userId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Mark the source request reviewed atomically with the rating.
      if (requestRef != null) {
        transaction.set(
            requestRef, {'userReviewed': true}, SetOptions(merge: true));
      }
    });

    // Stats changed — drop the stale cache entry so the next read is fresh.
    _cache.invalidate(volunteerId);
  }
}
