import 'dart:io';
import 'dart:typed_data'; // For handling image bytes
import 'package:flutter/material.dart';

class VirtualTryOnResultPage extends StatefulWidget {
  final File? inputImage;
  final String id;

  const VirtualTryOnResultPage({super.key, this.inputImage, required this.id});

  @override
  _VirtualTryOnResultPageState createState() => _VirtualTryOnResultPageState();
}

class _VirtualTryOnResultPageState extends State<VirtualTryOnResultPage> {
  Uint8List? resultImageBytes; // To store the image bytes from the backend
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTryOnResult();
  }

  Future<void> _fetchTryOnResult() async {
    if (widget.inputImage == null) {
      setState(() {
        errorMessage = "No image provided for try-on.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });


    // temporarily display the input image as the result image
    widget.inputImage!.readAsBytes().then((bytes) {
      setState(() {
        resultImageBytes = bytes;
      });
    }).catchError((error) {
      setState(() {
        errorMessage = "Failed to load image: $error";
      });
    });

    // --------------------------------------------------------

    setState(() {
      // temporary
      isLoading = false;
    });



    /*
    try {
      final uri = Uri.parse('https://your-backend-url.com/virtual-try-on');
      var request = http.MultipartRequest('POST', uri);

      // Add image file
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        widget.inputImage!.path,
      ));

      // Add ID as a form field
      request.fields['id'] = widget.id;

      // Send request and handle response
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        setState(() {
          resultImageBytes = responseData; // Store the received image bytes
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load result. Status code: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred: $e";
        isLoading = false;
      });
    }*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Try-On Result'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: isLoading
              ? CircularProgressIndicator()
              : errorMessage != null
                  ? Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red),
                    )
                  : resultImageBytes != null
                      ? Image.memory(resultImageBytes!) // Display the received image
                      : Text('No result to display.'),
        ),
      ),
    );
  }
}
