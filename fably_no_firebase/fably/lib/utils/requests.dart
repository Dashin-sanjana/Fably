import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON decoding, if needed
import 'dart:async';

import 'prefs.dart';

class BackendRequests {
   //final url = 'http://192.168.1.102:3000'; // the backend server is defined here.
  final url = 'http://152.53.119.239:5000'; 
  //final url = 'https://fably.omeshapasan.site';
  Future<String> getCsrf() async{
    final csrfUrl = Uri.parse('$url/get-csrf-token');
    final csrfResponse = await http.get(csrfUrl);

    if (csrfResponse.statusCode != 200) {
      throw Exception("Failed to fetch CSRF token: ${csrfResponse.statusCode}");
    }

    String csrfToken = jsonDecode(csrfResponse.body)['csrf_token'];

    return csrfToken;
  }

  Future<http.Response> getRequest(String endpoint, {Map<String, String>? headers}) async {
    final prefs = Prefs();
    String cookies = await prefs.getPrefs('cookies') ?? '';
    String csrfToken = await prefs.getPrefs('csrf_token') ?? '';
    headers = headers ?? {};
    headers['X-CSRFToken'] = csrfToken;
    headers['Cookie'] = cookies;
    try {
      final requestUrl = Uri.parse('$url/$endpoint');
      final response = await http.get(requestUrl, headers: headers);

      /*if (response.statusCode == 200) {
        return response; // Return the full HTTP response
      } else {
        print('Failed to fetch data: ${response.statusCode}');
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }*/
      return response;
    } catch (e) {
      throw Exception('Error occurred during GET request: $e');
    }
  }

  Future<http.Response> postRequest(String endpoint, {Map<String, String>? headers, Map<String, dynamic>? body,}) async {
    final prefs = Prefs();
    String cookies = await prefs.getPrefs('cookies') ?? '';
    String csrfToken = await prefs.getPrefs('csrf_token') ?? '';
    headers = headers ?? {};
    headers['X-CSRFToken'] = csrfToken;
    headers['Content-Type'] = 'application/json'; // Set content type for JSON body
    headers['Cookie'] = cookies;

    try {
      final requestUrl = Uri.parse('$url/$endpoint');
      //print('POST Request Body: ${jsonEncode(body)}');
      final response = await http.post(
        requestUrl,
        headers: headers,
        body: jsonEncode(body), // Encode body to JSON format
      );

      /*if (response.statusCode == 200 || response.statusCode == 201) {
        return response; // Return the full HTTP response
      } else {

        throw Exception('Failed to post data: ${response.statusCode}');
      }*/
      return response;
    } catch (e) {
      throw Exception('Error occurred during POST request: $e');
    }
  }

  String getUrl(){
    return url;
  }
  Future<bool> isLoggedIn() async {
    final prefs = Prefs();

    // Retrieve preferences asynchronously
    final userInfo = await prefs.getPrefs('userInfo') ?? '';
    final cookies = await prefs.getPrefs('cookies') ?? '';

    // Check if preferences are null or empty
    if (userInfo.isEmpty || cookies.isEmpty) {
      print("Prefs are empty or null");
      return false;
    }

    // Check login status via backend
    final response = await getRequest('check_logged_in');
    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401) {
      await prefs.clearPrefs();
      return false;
    }

    // Default to true for other status codes
    return true;
  }

}