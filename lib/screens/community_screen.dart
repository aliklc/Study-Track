import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/comment_model.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final DatabaseService _dbService = DatabaseService();

  void _showAddPostDialog() {
    showDialog(context: context, builder: (context) => const AddPostDialog());
  }

  // Yorum Penceresini Açan Fonksiyon
  void _showCommentsSheet(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Tam ekran efekti için
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CommentsSheet(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Topluluk Duvarı")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        onPressed: _showAddPostDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: _dbService.getPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Henüz kimse bir şey paylaşmamış.\nİlk paylaşan sen ol!",
                textAlign: TextAlign.center,
              ),
            );
          }

          final posts = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final isLiked = user != null && post.likes.contains(user.uid);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- ÜST KISIM: KULLANICI BİLGİSİ ---
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: post.userPhotoUrl != null
                                ? NetworkImage(post.userPhotoUrl!)
                                : null,
                            child: post.userPhotoUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'dd MMM HH:mm',
                                  'tr',
                                ).format(post.timestamp),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // --- İÇERİK ---
                      Text(post.message, style: const TextStyle(fontSize: 15)),

                      if (post.postImageUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              post.postImageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                      const Divider(height: 30),

                      // --- AKSİYON BUTONLARI (BEĞEN & YORUM) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // BEĞEN BUTONU
                          TextButton.icon(
                            onPressed: user == null
                                ? null
                                : () {
                                    _dbService.togglePostLike(
                                      post.id,
                                      user.uid,
                                      post.likes,
                                    );
                                  },
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                            ),
                            label: Text(
                              "${post.likes.length} Beğeni",
                              style: TextStyle(
                                color: isLiked ? Colors.red : Colors.grey,
                              ),
                            ),
                          ),

                          // YORUM BUTONU
                          TextButton.icon(
                            onPressed: () => _showCommentsSheet(context, post),
                            icon: const Icon(
                              Icons.comment_outlined,
                              color: Colors.grey,
                            ),
                            label: const Text(
                              "Yorum Yap",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- YENİ WIDGET: YORUMLAR PENCERESİ ---
class CommentsSheet extends StatefulWidget {
  final PostModel post;
  const CommentsSheet({super.key, required this.post});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      final userDetails = await _dbService.getUser(user.uid);

      final newComment = CommentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        postId: widget.post.id,
        userId: user.uid,
        userName: userDetails?.displayName ?? "Kullanıcı",
        userPhotoUrl: userDetails?.photoUrl,
        message: _commentController.text.trim(),
        timestamp: DateTime.now(),
        likes: [],
      );

      await _dbService.addComment(newComment);
      _commentController.clear();
      // Klavye açık kalsın, belki yine yazar
    }
  }

  @override
  Widget build(BuildContext context) {
    // Klavye açılınca ekranın yukarı kayması için padding
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final user = context.watch<AuthService>().currentUser;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75, // Ekranın %75'i
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        children: [
          // Başlık ve Kapatma Çubuğu
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            "Yorumlar",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(),

          // Yorum Listesi
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _dbService.getComments(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("Henüz yorum yok. İlk sen yaz!"),
                  );
                }

                final comments = snapshot.data!;
                return ListView.builder(
                  itemCount: comments.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isCommentLiked =
                        user != null && comment.likes.contains(user.uid);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundImage: comment.userPhotoUrl != null
                            ? NetworkImage(comment.userPhotoUrl!)
                            : null,
                        child: comment.userPhotoUrl == null
                            ? const Icon(Icons.person, size: 20)
                            : null,
                      ),
                      title: Row(
                        children: [
                          Text(
                            comment.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm', 'tr').format(comment.timestamp),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(comment.message),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isCommentLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: isCommentLiked ? Colors.red : Colors.grey,
                            ),
                            onPressed: user == null
                                ? null
                                : () {
                                    _dbService.toggleCommentLike(
                                      widget.post.id,
                                      comment.id,
                                      user.uid,
                                      comment.likes,
                                    );
                                  },
                          ),
                          if (comment.likes.isNotEmpty)
                            Text(
                              "${comment.likes.length}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Yorum Yazma Alanı
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Yorum yaz...",
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sendComment,
                  icon: const Icon(Icons.send, color: Color(0xFF6C63FF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ... AddPostDialog sınıfı aynı kalacak, sadece PostModel oluştururken likes: [] eklemeyi unutma!
class AddPostDialog extends StatefulWidget {
  const AddPostDialog({super.key});

  @override
  State<AddPostDialog> createState() => _AddPostDialogState();
}

class _AddPostDialogState extends State<AddPostDialog> {
  // ... Değişkenler aynı ...
  final _messageController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _sharePost() async {
    if (_messageController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      final userDetails = await _dbService.getUser(user.uid);

      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadPostImage(_selectedImage!);
      }

      final newPost = PostModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        userName: userDetails?.displayName ?? "Kullanıcı",
        userPhotoUrl: userDetails?.photoUrl,
        message: _messageController.text.trim(),
        postImageUrl: imageUrl,
        timestamp: DateTime.now(),
        likes: [], // YENİ: Başlangıçta beğeni yok
      );

      await _dbService.addPost(newPost);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Yeni Paylaşım"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Neler yaptın? Motive et!",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),

            // Resim Seçme Alanı
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.grey),
                          Text("Fotoğraf Ekle"),
                        ],
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("İptal"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sharePost,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                )
              : const Text("Paylaş"),
        ),
      ],
    );
  }
}
