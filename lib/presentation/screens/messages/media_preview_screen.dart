import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MediaPreviewScreen extends StatefulWidget {
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final String? fileName;

  const MediaPreviewScreen({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    this.fileName,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.fileName ?? 'Xem media',
          style: const TextStyle(color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang tải xuống...')),
              );
            },
          ),
        ],
      ),
      body: widget.mediaType == 'image'
          ? _buildImagePreview()
          : _buildVideoPreview(),
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.5,
        maxScale: 3,
        child: Image.network(
          widget.mediaUrl,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[900],
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Center(
      child: Container(
        color: Colors.grey[900],
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.network(
              widget.mediaUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
