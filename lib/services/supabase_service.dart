import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(ref.watch(supabaseClientProvider));
});

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  Future<List<Post>> fetchPosts({
    required int offset,
    required int limit,
  }) async {
    final response = await _client
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List<dynamic>)
        .map((json) => Post.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> toggleLike(String postId, String userId) async {
    await _client.rpc(
      'toggle_like',
      params: {'p_post_id': postId, 'p_user_id': userId},
    );
  }
}
