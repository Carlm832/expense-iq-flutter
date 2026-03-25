import 'package:image_picker/image_picker.dart';

class OcrResult {
  final String? merchant;
  final double? amount;
  final String? date;
  final String? currency;
  final String? category;
  final String rawText;
  final bool success;

  OcrResult({
    this.merchant,
    this.amount,
    this.date,
    this.currency,
    this.category,
    required this.rawText,
    required this.success,
  });
}

class OcrService {
  Future<XFile?> scanReceipt() async {
    return ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 2048,
    );
  }

  Future<OcrResult> processImage(XFile imageFile) async {
    // Stub implementation does nothing
    return OcrResult(rawText: '', success: false);
  }

  void dispose() {}
}
