import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:image_picker/image_picker.dart';
import 'package:loading_overlay/loading_overlay.dart';

void main() { runApp(AccessoryMatchApp()); }

class AccessoryMatchApp extends StatelessWidget {
  const AccessoryMatchApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'Accessory Matcher', theme: ThemeData(primarySwatch: Colors.blue,), home: AccessoryMatcher(),
        );
    }
}

class AccessoryMatcher extends StatefulWidget {
  const AccessoryMatcher({super.key});
    @override
    _AccessoryMatcherState createState() => _AccessoryMatcherState();
}

class _AccessoryMatcherState extends State<AccessoryMatcher> {

    final ImagePicker _picker = ImagePicker();
    
    final Map<String, XFile?> _imageFiles = {};
    final Map<String, String> _accessoryColors = {}; // mapping all the accessory colors.
    final Map<String, String> _outfitColors = {}; // mapping all the outfit colors.
    final Map<String, String> _outfitTypes = {}; // mapping all the outfit types.
    final List<String> _selectedAccessoryColors = []; // mapping all the selected accessory colors.

    Map<String, dynamic> _results = {}; // mapping all the results.
    bool _isLoading = false;

    // all the accessory types.
    final List<String> _accessoryTypes = ['belts', 'chains', 'glasses', 'gloves', 'handbags', 'hats', 'rings', 'shoes', 'socks', 'watches'];

    // all the outfit categories.
    final List<String> _ouftitCatgories = ['activewear', 'bohemian', 'casual', 'eveningwear', 'formal', 'indie', 'knitwear', 'loungewear', 'retro', 'romantic', 'smartcasual', 'sporty', 'vintage'];

    // all the colors listed.
    final List<String> _colorsList = ['Amber', 'Black', 'Blue', 'Emerald', 'Gold', 'Green', 'Grey', 'Indigo', 'Jade', 'Lemon', 'Lilac', 'Lime', 'Midnight Blue', 'Mint Green', 'Navy Blue', 'Olive', 'Orange', 'Peach', 'Pink', 'Platinum', 'Plum', 'Purple', 'Red', 'Rose', 'Ruby', 'Sapphire', 'Scarlet', 'Silver', 'Turquoise', 'Ultramarine', 'Violet', 'White', 'Yellow', 'Zucchini'];
    
    @override
    void initState() {
        super.initState();
        for (var type in _accessoryTypes) {
            _accessoryColors[type] = ''; // image upload for accessory colors.
            _imageFiles[type] = null; // image upload for accessories.
        }

        for (var type in _ouftitCatgories) {
            _outfitColors[type] = ''; // image upload for outfit colors.
            _outfitTypes[type] = ''; // image upload for outfit types.
            _imageFiles[type] = null; // image upload for outfits.
        }
    }

    // syncrhonized function to prevent threading conflicts, and to pick images.
    Future<void> _pickImage(String type) async {
        XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
            setState(() { _imageFiles[type] = image; });
        }
    }

    Future<void> _uploadImages() async {
        setState(() {
            _isLoading = false;
            _results = {};
        }); // setting states for loading and results.

        try {
            var formData = dio.FormData();

            _imageFiles.forEach((key, value) async {
                if (value != null) { formData.files.add(MapEntry(key, await dio.MultipartFile.fromFile(value.path))); }
            });

            // sending accessory colors as a list.
            for (var color in _selectedAccessoryColors) {
              formData.fields.add(MapEntry('accessory_colors[]', color));
            }

            // getting the outfit keys for each outfit image.
            String? outfitKey = _imageFiles.keys.firstWhere((k) => _ouftitCatgories.contains(k), orElse: () => null!);
            if (outfitKey != null && _imageFiles[outfitKey] != null) {
              formData.files.add(MapEntry(outfitKey, await dio.MultipartFile.fromFile(_imageFiles[outfitKey]!.path)));
            }
            
            _accessoryColors.forEach((key, value) { formData.fields.add(MapEntry('accessory_${key}_color', value)); });

            _outfitTypes.forEach((key, value) { formData.fields.add(MapEntry('outfit_${key}_type', value)); });

            _outfitColors.forEach((key, value) { formData.fields.add(MapEntry('outfit_${key}_color', value)); });

            // initializing the port url.
            var response = await dio.Dio().post('http://127.0.0.1:5000/match', data: formData,);
            
            setState(() {
              _results = response.data;
              _isLoading = true;});
        }
        catch (e) {
            setState(() {
              _results = {'error': e.toString()};
              _isLoading = false;});
        }
    }

    Widget _buildSection(String title, Map<String, dynamic> data) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${title}', style: TextStyle(fontWeight: FontWeight.w500),),
            for (var key in data.keys)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text('$key: ${jsonEncode(data[key])}'),
              ),
            SizedBox(height: 10,),
          ],
      );
    }

    Widget _buildResults() {
      if (_results.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20,),
            Text("Matching Results: ", style: TextStyle(fontSize: 18.5, fontWeight: FontWeight.bold),),
            SizedBox(height: 10,),
            // to display any errors caught by the backend.
            if (_results['error'] != null) Text("Error: ${_results['error']}", style: TextStyle(color: Colors.red),),

            if (_results['feature similarity'] != null) _buildSection("Feature Similarity", _results['feature similarity']),
            if (_results['image color match'] != null) _buildSection("Image Color Match", _results['image color match']),
            if (_results['image color delta e'] != null) _buildSection("Image Color Delta E", _results['image color delta e']),
            if (_results['provided color match'] != null) _buildSection("Provided Color Match", _results['provided color match']),
          ],
        );
      } else {
        return SizedBox.shrink();
      }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text('Accessory Matching')),
            body: LoadingOverlay(
                    isLoading: _isLoading, 
                    child: SingleChildScrollView(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                        children: [
                            Text('Accessory Matching With Outfits', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
                            SizedBox(height: 20),
                            Text('Outfit Image', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500)),
                            // creating drop down button field.
                            DropdownButtonFormField<String>(
                              value: _outfitTypes.keys.firstWhere( (k) => _imageFiles[k] != null, orElse: () => null!), 
                              // creating drop down menu tiems for outfit images.
                              items: _ouftitCatgories.map((String value) {
                                return DropdownMenuItem(
                                  value: value, 
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                // clearing previous outift selections.
                                setState(() {
                                  for (var key in _ouftitCatgories) {
                                    _imageFiles[key] = null;
                                  }
                                  _pickImage(newValue!);
                                });
                              },
                              decoration: InputDecoration(labelText: "Choose Outfit Style"),
                            ),

                            SizedBox(height: 10),
                            if (_imageFiles.keys.any((k) => _ouftitCatgories.contains(k) && _imageFiles[k] != null))
                              Image.file(
                                // uploading the image file.
                                File(_imageFiles.values.firstWhere((file) => file != null &&
                                    _ouftitCatgories.contains(_imageFiles.keys.firstWhere((key) => _imageFiles[key] == file)), 
                                    orElse: () => null)!.path), height: 10,
                              ),
                            
                            SizedBox(height: 20),
                            Text('Accessory Images', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500)),
                            // choosing accessory images.
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: _accessoryTypes.map((type) {
                                return Column(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _pickImage(type), 
                                      child: Text("Upload ${type.toUpperCase()}"),
                                    ),
                                    if (_imageFiles[type] != null) Image.file(File(_imageFiles[type]!.path), height: 70,),
                                  ],
                                );
                              }).toList(),
                            ),

                            SizedBox(height: 20),
                            Text('Accessory Colors', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500)),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              // for each accessory type in the form field.
                              children: _accessoryTypes.map((type) {
                                return DropdownButtonFormField<String>(
                                  decoration: InputDecoration(labelText: "Choose ${type.toUpperCase()} Color"),
                                  value: _accessoryColors[type],
                                  items: _colorsList.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _accessoryColors[type] = newValue!;
                                      if (newValue.isNotEmpty && !_selectedAccessoryColors.contains(newValue)) {
                                        _selectedAccessoryColors.add(newValue);
                                      } else if (newValue.isEmpty && !_selectedAccessoryColors.contains(_accessoryColors[type])) {
                                        _selectedAccessoryColors.remove(_accessoryColors[type]);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),

                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _uploadImages, 
                              child: Text("Match Outfits With Accessories"),
                            ),
                            _buildResults(),
                        ],
                    ),
                ),
            ),
        );
    }
}






