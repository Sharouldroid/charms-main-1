import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProofAttachmentViewer extends StatelessWidget {
  final String? fileUrl;
  final String? fileName;
  final String? fileType;

  const ProofAttachmentViewer({
    super.key,
    required this.fileUrl,
    this.fileName,
    this.fileType,
  });

  bool _isImage(String url) {
    final u = url.toLowerCase();
    return u.endsWith('.jpg') ||
        u.endsWith('.jpeg') ||
        u.endsWith('.png') ||
        u.endsWith('.webp') ||
        u.endsWith('.gif');
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final url = (fileUrl ?? '').trim();
    if (url.isEmpty) return const SizedBox.shrink();

    final isImage = _isImage(url) || (fileType?.toLowerCase() == 'image');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Attachment: ${fileName ?? 'View file'}',
          style: const TextStyle(color: Colors.blue),
        ),
        const SizedBox(height: 8),
        if (isImage)
          GestureDetector(
            onTap: () => _open(url),
            child: SizedBox(
              height: 100,
              width: 100,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: () => _open(url),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Attachment'),
          ),
      ],
    );
  }
}