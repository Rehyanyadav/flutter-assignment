import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../services/supabase_service.dart';

class FeedNotifier extends AsyncNotifier<List<Post>> {
  @override
  FutureOr<List<Post>> build() async {
    return _fetchPosts(0);
  }

  Future<List<Post>> _fetchPosts(int offset) async {
    return ref
        .read(supabaseServiceProvider)
        .fetchPosts(offset: offset, limit: 10);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPosts(0));
  }

  Future<void> fetchNextPage() async {
    final currentPosts = state.value;
    if (currentPosts == null) return;

    try {
      final newPosts = await _fetchPosts(currentPosts.length);
      state = AsyncData([...currentPosts, ...newPosts]);
    } catch (e) {
      // Handle error gracefully without overriding state to error
      debugPrint('Error fetching next page: $e');
    }
  }

  void updatePost(Post updatedPost) {
    if (state.value == null) return;
    final posts = state.value!;
    final index = posts.indexWhere((p) => p.id == updatedPost.id);
    if (index != -1) {
      final newPosts = List<Post>.from(posts);
      newPosts[index] = updatedPost;
      state = AsyncData(newPosts);
    }
  }
}

final feedProvider = AsyncNotifierProvider<FeedNotifier, List<Post>>(() {
  return FeedNotifier();
});
