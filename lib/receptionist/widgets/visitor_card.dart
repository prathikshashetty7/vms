import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/receptionist_theme.dart';
import 'package:image_picker/image_picker.dart';

class VisitorCard extends StatefulWidget {
  final String name;
  final String subtitle;
  final String status;
  final Color color;
  final bool showCheckout;
  final VoidCallback? onCheckout;

  const VisitorCard({
    Key? key,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.color,
    this.showCheckout = false,
    this.onCheckout,
  }) : super(key: key);

  @override
  State<VisitorCard> createState() => _VisitorCardState();
}

class _VisitorCardState extends State<VisitorCard> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: widget.color.withOpacity(0.15),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: widget.color,
              radius: 24,
              backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
              child: _imageFile == null
                  ? Text(widget.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.edit, size: 16, color: Colors.blueAccent),
                ),
              ),
            ),
          ],
        ),
        title: Text(widget.name, style: TextStyle(fontWeight: FontWeight.bold, color: ReceptionistTheme.text)),
        subtitle: Text(widget.subtitle, style: TextStyle(color: ReceptionistTheme.text)),
        trailing: widget.showCheckout
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ReceptionistTheme.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: widget.onCheckout,
                child: const Text('Check Out'),
              )
            : Text(widget.status, style: TextStyle(color: widget.color, fontWeight: FontWeight.bold)),
      ),
    );
  }
} 