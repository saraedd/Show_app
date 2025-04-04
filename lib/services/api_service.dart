import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/show_model.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();

  // Get all shows
  Future<List<Show>> getShows() async {
    try {
      final response = await _authService.authGet('${ApiConfig.baseUrl}/shows');

      if (response.statusCode == 200) {
        final List jsonShows = jsonDecode(response.body);
        return jsonShows.map((show) => Show.fromJson(show)).toList();
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Authentication error: Please login again');
      } else {
        throw Exception('Failed to load shows: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching shows: $e');
    }
  }

  // Add a new show
  Future<Show> addShow(String title, String description, String category, String image) async {
    var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/shows'));

    final token = await _authService.getToken();
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['category'] = category;

    if (image.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('image', image));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return Show.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Authentication error: Please login again');
      } else {
        throw Exception('Failed to add show: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding show: $e');
    }
  }

  // Update an existing show
  Future<Show> updateShow(int id, String title, String description, String category, String image) async {
    var request = http.MultipartRequest('PUT', Uri.parse('${ApiConfig.baseUrl}/shows/$id'));

    final token = await _authService.getToken();
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['category'] = category;

    if (image.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('image', image));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return Show.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Authentication error: Please login again');
      } else {
        throw Exception('Failed to update show: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating show: $e');
    }
  }

  // Delete a show
  Future<void> deleteShow(int id) async {
    try {
      final response = await _authService.authDelete('${ApiConfig.baseUrl}/shows/$id');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Authentication error: Please login again');
      } else {
        throw Exception('Failed to delete show: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting show: $e');
    }
  }
}
