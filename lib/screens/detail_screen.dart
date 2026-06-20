import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';

class DetailScreen extends StatefulWidget {
  final Post post;

  const DetailScreen({super.key, required this.post});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _showRaw = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Hero(
          tag: 'post_${widget.post.id}',
          child: _showRaw
              ? CachedNetworkImage(
                  imageUrl: widget.post.mediaRawUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => CachedNetworkImage(
                    imageUrl: widget.post.mediaMobileUrl,
                    fit: BoxFit.contain,
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: widget.post.mediaMobileUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => CachedNetworkImage(
                    imageUrl: widget.post.mediaThumbUrl,
                    fit: BoxFit.contain,
                  ),
                ),
        ),
      ),
      floatingActionButton: !_showRaw
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _showRaw = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Downloading High-Res Image...'),
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Load High-Res'),
            )
          : null,
    );
  }
}
