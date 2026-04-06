import 'dart:convert';
import 'dart:typed_data';
import 'package:charms/base64_image_viewer.dart';
import 'package:flutter/material.dart';

class ImageUtils {
  /// Attempts to convert various image data formats to a Uint8List
  static Uint8List? tryDecodeImage(dynamic imageData) {
    try {
      if (imageData == null) {
        print('ImageUtils: Image data is null');
        return null;
      }
      
      print('ImageUtils: Image data type: ${imageData.runtimeType}');
      
      // Case 1: Already a Uint8List
      if (imageData is Uint8List) {
        print('ImageUtils: Data is already Uint8List');
        return imageData;
      }
      
      // Case 2: Node.js Buffer format
      if (imageData is Map) {
        print('ImageUtils: Data is a Map with keys: ${imageData.keys.join(', ')}');
        
        if (imageData['type'] == 'Buffer' && imageData['data'] is List) {
          final List<dynamic> data = imageData['data'];
          print('ImageUtils: Buffer data length: ${data.length}');
          
          if (data.isEmpty) {
            print('ImageUtils: Buffer data is empty');
            return null;
          }
          
          // Print first few bytes for debugging
          final sample = data.take(10).toList();
          print('ImageUtils: First few bytes: $sample');
          
          // Regular buffer handling
          return Uint8List.fromList(
            data.map<int>((item) => item is int ? item : 0).toList()
          );
        }
      }
      
      // Case 3: Base64 string
      if (imageData is String) {
        print('ImageUtils: Data is a String of length: ${imageData.length}');
        
        // Print a sample of the string for debugging
        final sampleLength = imageData.length > 50 ? 50 : imageData.length;
        print('ImageUtils: String sample: ${imageData.substring(0, sampleLength)}...');
        
        try {
          // Remove any data URL prefix
          String base64String = imageData;
          if (base64String.contains(',')) {
            base64String = base64String.split(',').last;
          }
          
          // Try to decode the base64 string
          return base64Decode(base64String);
        } catch (e) {
          print('ImageUtils: Error decoding base64: $e');
          
          // Try to clean up the string
          try {
            String cleaned = imageData.trim();
            // Remove any non-base64 characters
            cleaned = cleaned.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
            // Ensure the length is a multiple of 4
            while (cleaned.length % 4 != 0) {
              cleaned += '=';
            }
            
            return base64Decode(cleaned);
          } catch (e) {
            print('ImageUtils: Error decoding cleaned base64: $e');
          }
        }
      }
      
      print('ImageUtils: Could not decode image data');
      return null;
    } catch (e) {
      print('ImageUtils: Error in tryDecodeImage: $e');
      return null;
    }
  }
  
  /// Creates a widget to display an image from various data formats
  static Widget buildImageWidget(dynamic imageData, {
    double height = 100,
    double width = 100,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageData == null) {
      return Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: Icon(Icons.no_photography),
      );
    }
    
    // For string data that looks like base64, use our custom WebView-based viewer
    if (imageData is String && imageData.length > 100) {
      return Base64ImageViewer(
        base64String: imageData,
        height: height,
        width: width,
        fit: fit,
      );
    }
    
    // Try the regular approach with Uint8List for other cases
    final Uint8List? bytes = tryDecodeImage(imageData);
    if (bytes == null || bytes.isEmpty) {
      return Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: Icon(Icons.broken_image),
      );
    }
    
    // Use Image.memory to display the image
    return Image.memory(
      bytes,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        print('Error displaying image: $error');
        return Container(
          height: height,
          width: width,
          color: Colors.grey[200],
          child: Icon(Icons.image_not_supported),
        );
      },
    );
  }
}
