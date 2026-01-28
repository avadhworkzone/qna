import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:convert';
import 'dart:async';

class SuperAdminPanel extends StatefulWidget {
  final Function(Locale) onLanguageChange;
  const SuperAdminPanel({super.key, required this.onLanguageChange});

  @override
  State<SuperAdminPanel> createState() => _SuperAdminPanelState();
}

class _SuperAdminPanelState extends State<SuperAdminPanel> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  Future<void> _pickImage() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files!.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _selectedImageBytes = reader.result as Uint8List;
            _selectedImageName = file.name;
          });
        });
      }
    });
  }

  Future<Uint8List?> _compressImage(Uint8List imageBytes) async {
    try {
      // Create canvas element
      final canvas = html.CanvasElement();
      final ctx = canvas.getContext('2d') as html.CanvasRenderingContext2D;
      
      // Create image element
      final img = html.ImageElement();
      final blob = html.Blob([imageBytes]);
      final url = html.Url.createObjectUrl(blob);
      
      // Load image
      img.src = url;
      await img.onLoad.first;
      
      // Calculate new dimensions (max 300x300)
      int maxSize = 300;
      double ratio = img.naturalWidth! / img.naturalHeight!;
      int newWidth, newHeight;
      
      if (img.naturalWidth! > img.naturalHeight!) {
        newWidth = maxSize;
        newHeight = (maxSize / ratio).round();
      } else {
        newHeight = maxSize;
        newWidth = (maxSize * ratio).round();
      }
      
      // Set canvas size
      canvas.width = newWidth;
      canvas.height = newHeight;
      
      // Draw resized image
      ctx.drawImageScaled(img, 0, 0, newWidth, newHeight);
      
      // Convert canvas to data URL then to bytes
      String dataUrl = canvas.toDataUrl('image/jpeg', 0.7);
      String base64Data = dataUrl.split(',')[1];
      Uint8List compressedBytes = base64Decode(base64Data);
      
      html.Url.revokeObjectUrl(url);
      return compressedBytes;
    } catch (e) {
      print('Image compression error: $e');
      return null;
    }
  }

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    print('Starting admin creation...');
    setState(() => _isLoading = true);

    try {
      print('Creating admin with email: ${_emailController.text.trim()}');
      
      // Convert image to Base64 if selected
      String? profileImageBase64;
      if (_selectedImageBytes != null) {
        print('Processing image...');
        print('Original image size: ${_selectedImageBytes!.length} bytes');
        
        Uint8List? processedImage = _selectedImageBytes;
        
        // Compress if image is too large
        if (_selectedImageBytes!.length > 200000) { // 200KB limit
          print('Compressing large image...');
          processedImage = await _compressImage(_selectedImageBytes!);
          if (processedImage != null) {
            print('Compressed image size: ${processedImage.length} bytes');
          } else {
            print('Compression failed, using original');
            processedImage = _selectedImageBytes;
          }
        }
        
        if (processedImage != null) {
          profileImageBase64 = base64Encode(processedImage);
          print('Image converted to Base64 (${profileImageBase64.length} chars)');
        }
      }
      
      print('Adding admin to Firestore...');
      // Add admin to Firestore with Base64 image
      DocumentReference docRef = await _firestore.collection('admins').add({
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'password': _passwordController.text,
        'profileImageBase64': profileImageBase64,
        'isSuperAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'authCreated': false,
      });
      print('Firestore add completed');
      
      print('Admin created with ID: ${docRef.id}');

      // Clear form
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      setState(() {
        _selectedImageBytes = null;
        _selectedImageName = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin created successfully!')),
        );
      }
    } catch (e) {
      print('Error creating admin: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      print('Admin creation completed');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Panel'),
        backgroundColor: Colors.red.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Column(
                children: [
                  Icon(Icons.admin_panel_settings, size: 48, color: Colors.red),
                  SizedBox(height: 8),
                  Text(
                    'Super Admin Dashboard',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text('Create and manage admin accounts'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Add Admin Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add New Admin',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Profile Image
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: _selectedImageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.memory(
                                      _selectedImageBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _selectedImageName != null 
                              ? 'Selected: $_selectedImageName'
                              : 'Tap to select profile image',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Admin Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter admin name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createAdmin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Create Admin',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Existing Admins List
            const Text(
              'Existing Admins',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('admins').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final admins = snapshot.data!.docs;
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: admins.length,
                  itemBuilder: (context, index) {
                    final admin = admins[index].data() as Map<String, dynamic>;
                    final isSuperAdmin = admin['isSuperAdmin'] ?? false;
                    
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: admin['profileImageBase64'] != null
                              ? MemoryImage(base64Decode(admin['profileImageBase64']))
                              : null,
                          child: admin['profileImageBase64'] == null
                              ? Text(admin['name']?[0]?.toUpperCase() ?? 'A')
                              : null,
                        ),
                        title: Text(admin['name'] ?? 'No Name'),
                        subtitle: Text(admin['email'] ?? 'No Email'),
                        trailing: isSuperAdmin
                            ? const Chip(
                                label: Text('Super Admin'),
                                backgroundColor: Colors.red,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                            : const Chip(
                                label: Text('Admin'),
                                backgroundColor: Colors.blue,
                                labelStyle: TextStyle(color: Colors.white),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}