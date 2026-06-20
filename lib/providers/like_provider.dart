import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../services/supabase_service.dart';
import 'feed_provider.dart';
import '../models/post.dart';

class ErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setError(String? error) => state = error;
}

final errorProvider = NotifierProvider<ErrorNotifier, String?>(
  ErrorNotifier.new,
);

final likeProvider = Provider((ref) {
  final service = LikeService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

class LikeService {
  final Ref ref;
  final PublishSubject<String> _likeSubject = PublishSubject<String>();

  static const String currentUserId = 'user_123';

  LikeService(this.ref) {
    _likeSubject
        .groupBy((postId) => postId)
        .flatMap(
          (group) => group.debounceTime(const Duration(milliseconds: 500)),
        )
        .listen((postId) {
          _fireRpc(postId);
        });
  }

  void toggleLike(Post post) {
    // 1. Optimistic UI update
    final bool willBeLiked = !post.isLiked;
    // Ensure likeCount doesn't go below 0
    int newCount = willBeLiked ? post.likeCount + 1 : post.likeCount - 1;
    if (newCount < 0) newCount = 0;

    final updatedPost = post.copyWith(
      isLiked: willBeLiked,
      likeCount: newCount,
    );

    // Mutate local state instantly
    ref.read(feedProvider.notifier).updatePost(updatedPost);

    // 2. Queue for network
    _likeSubject.add(post.id);
  }

  Future<void> _fireRpc(String postId) async {
    try {
      await ref.read(supabaseServiceProvider).toggleLike(postId, currentUserId);
    } catch (e) {
      // 3. Offline Revert
      final feedState = ref.read(feedProvider);
      if (feedState.value != null) {
        try {
          final post = feedState.value!.firstWhere((p) => p.id == postId);

          final revertedPost = post.copyWith(
            isLiked: !post.isLiked,
            likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
          );
          ref.read(feedProvider.notifier).updatePost(revertedPost);

          ref.read(errorProvider.notifier).setError('Offline: Like reverted.');
        } catch (_) {}
      }
    }
  }

  void dispose() {
    _likeSubject.close();
  }
}
