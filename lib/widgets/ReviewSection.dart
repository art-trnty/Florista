import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewSection extends StatefulWidget {
  final String storeId;
  const ReviewSection({super.key, required this.storeId});

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Map<String, bool> _showRepliesMap = {};

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _commentController.text.trim().isEmpty) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final userData = userDoc.data() ?? {};

      final userName = userData['name'] ?? 'User';
      final userPhotoBase64 = userData['photoBase64'] ?? '';

      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('reviews')
          .add({
            'userId': user.uid,
            'userName': userName,
            'userPhotoBase64': userPhotoBase64,
            'comment': _commentController.text.trim(),
            'likes': [],
            'timestamp': FieldValue.serverTimestamp(),
          });

      _commentController.clear();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal kirim komentar: $e")));
    }
  }

  Future<void> _toggleLike(DocumentSnapshot doc) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final List<String> likes = List<String>.from(doc['likes'] ?? []);

    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }

    await doc.reference.update({'likes': likes});
  }

  void _showReplyDialog(String reviewId) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Balas Komentar"),
            content: TextField(
              controller: replyController,
              decoration: const InputDecoration(hintText: "Tulis balasan..."),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null || replyController.text.trim().isEmpty)
                    return;

                  final userDoc =
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .get();
                  final userData = userDoc.data() ?? {};
                  final userName = userData['name'] ?? 'User';
                  final userPhotoBase64 = userData['photoBase64'] ?? '';

                  await FirebaseFirestore.instance
                      .collection('stores')
                      .doc(widget.storeId)
                      .collection('reviews')
                      .doc(reviewId)
                      .collection('replies')
                      .add({
                        'userId': user.uid,
                        'userName': userName,
                        'userPhotoBase64': userPhotoBase64,
                        'comment': replyController.text.trim(),
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                  Navigator.pop(context);
                },
                child: const Text("Kirim"),
              ),
            ],
          ),
    );
  }

  void _showEditDialog(DocumentSnapshot doc, String currentComment) {
    final editController = TextEditingController(text: currentComment);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edit Komentar"),
            content: TextField(
              controller: editController,
              decoration: const InputDecoration(hintText: "Edit komentar..."),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () async {
                  final updatedText = editController.text.trim();
                  if (updatedText.isNotEmpty) {
                    await doc.reference.update({'comment': updatedText});
                  }
                  Navigator.pop(context);
                },
                child: const Text("Simpan"),
              ),
            ],
          ),
    );
  }

  Widget _buildReplies(String storeId, String reviewId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('stores')
              .doc(storeId)
              .collection('reviews')
              .doc(reviewId)
              .collection('replies')
              .orderBy('timestamp')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final replies = snapshot.data!.docs;
        final showReplies = _showRepliesMap[reviewId] ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _showRepliesMap[reviewId] = !showReplies;
                });
              },
              child: Text(
                showReplies
                    ? "Sembunyikan balasan"
                    : "Lihat ${replies.length} balasan",
                style: const TextStyle(fontSize: 13),
              ),
            ),
            if (showReplies)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      replies.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final timestamp = data['timestamp'];
                        String formattedTime = '';

                        if (timestamp != null && timestamp is Timestamp) {
                          final date = timestamp.toDate();
                          formattedTime = DateFormat(
                            'dd MMM yyyy, HH:mm',
                          ).format(date);
                        }

                        final userPhotoBase64 = data['userPhotoBase64'] ?? '';
                        ImageProvider? imageProvider;
                        if (userPhotoBase64.isNotEmpty) {
                          try {
                            final base64Str =
                                userPhotoBase64.contains(',')
                                    ? userPhotoBase64.split(',').last
                                    : userPhotoBase64;
                            imageProvider = MemoryImage(
                              base64Decode(base64Str),
                            );
                          } catch (_) {
                            imageProvider = null;
                          }
                        }

                        final userName = data['userName'] ?? 'User';
                        final firstInitial =
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?';

                        return Container(
                          margin: const EdgeInsets.only(top: 8.0),
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border(
                              left: BorderSide(
                                color: Colors.grey.shade400,
                                width: 2.0,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.blue.shade100,
                                backgroundImage: imageProvider,
                                child:
                                    imageProvider == null
                                        ? Text(
                                          firstInitial,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            userName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        if (formattedTime.isNotEmpty)
                                          Text(
                                            formattedTime,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data['comment'] ?? '',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: "Tulis komentar...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _submitComment,
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('stores')
                    .doc(widget.storeId)
                    .collection('reviews')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Belum ada komentar."));
              }

              final comments = snapshot.data!.docs;
              return ListView.builder(
                controller: _scrollController,
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final doc = comments[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final likes = List<String>.from(data['likes'] ?? []);
                  final liked = likes.contains(
                    FirebaseAuth.instance.currentUser!.uid,
                  );
                  final isOwner =
                      FirebaseAuth.instance.currentUser!.uid == data['userId'];

                  final userPhotoBase64 = data['userPhotoBase64'] ?? '';
                  ImageProvider? imageProvider;
                  if (userPhotoBase64.isNotEmpty) {
                    try {
                      final base64Str =
                          userPhotoBase64.contains(',')
                              ? userPhotoBase64.split(',').last
                              : userPhotoBase64;
                      imageProvider = MemoryImage(base64Decode(base64Str));
                    } catch (_) {
                      imageProvider = null;
                    }
                  }

                  final userName = data['userName'] ?? 'User';
                  final firstInitial =
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?';

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.green.shade100,
                              backgroundImage: imageProvider,
                              child:
                                  imageProvider == null
                                      ? Text(
                                        firstInitial,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                      : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (data['timestamp'] != null &&
                                      data['timestamp'] is Timestamp)
                                    Text(
                                      DateFormat('dd MMM yyyy, HH:mm').format(
                                        (data['timestamp'] as Timestamp)
                                            .toDate(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isOwner)
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    _showEditDialog(doc, data['comment']);
                                  } else if (value == 'delete') {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (ctx) => AlertDialog(
                                            title: const Text("Hapus Komentar"),
                                            content: const Text(
                                              "Yakin ingin menghapus komentar ini?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      ctx,
                                                      false,
                                                    ),
                                                child: const Text("Batal"),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      ctx,
                                                      true,
                                                    ),
                                                child: const Text("Hapus"),
                                              ),
                                            ],
                                          ),
                                    );
                                    if (confirm == true) {
                                      await doc.reference.delete();
                                    }
                                  }
                                },
                                itemBuilder:
                                    (context) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text("Edit Komentar"),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text("Hapus Komentar"),
                                      ),
                                    ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(data['comment'] ?? ''),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _toggleLike(doc),
                              icon: Icon(
                                liked ? Icons.favorite : Icons.favorite_border,
                                color: liked ? Colors.red : Colors.grey,
                                size: 20,
                              ),
                              label: Text("${likes.length}"),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _showReplyDialog(doc.id),
                              child: const Text("Balas"),
                            ),
                          ],
                        ),
                        _buildReplies(widget.storeId, doc.id),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
