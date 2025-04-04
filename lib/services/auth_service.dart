// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import "package:shared_preferences/shared_preferences.dart";
import '../config/api_config.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Key for storing token
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get stored user ID
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Login user and store token
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final userId = data['userId'];

      // Save token and user ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setInt(_userIdKey, userId);

      return {
        'success': true,
        'token': token,
        'userId': userId,
      };
    } else if (response.statusCode == 401) {
      return {
        'success': false,
        'message': 'Invalid email or password',
      };
    } else {
      return {
        'success': false,
        'message': 'Login failed. Please try again.',
      };
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final userId = data['userId'];

      // Save token and user ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setInt(_userIdKey, userId);

      return {
        'success': true,
        'token': token,
        'userId': userId,
      };
    } else if (response.statusCode == 409) {
      return {
        'success': false,
        'message': 'Email already in use',
      };
    } else {
      return {
        'success': false,
        'message': 'Registration failed. Please try again.',
      };
    }
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }

  // Get authentication headers
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get authenticated HTTP client for API requests
  Future<http.Client> getAuthClient() async {
    final client = http.Client();
    final token = await getToken();
    if (token == null) {
      return client;
    }
    return client;
  }

  // Make authenticated GET request
  Future<http.Response> authGet(String url) async {
    final headers = await getAuthHeaders();
    return http.get(Uri.parse(url), headers: headers);
  }

  // Make authenticated POST request
  Future<http.Response> authPost(String url, {Map<String, dynamic>? body}) async {
    final headers = await getAuthHeaders();
    return http.post(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  // Make authenticated PUT request
  Future<http.Response> authPut(String url, {Map<String, dynamic>? body}) async {
    final headers = await getAuthHeaders();
    return http.put(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  // Make authenticated DELETE request
  Future<http.Response> authDelete(String url) async {
    final headers = await getAuthHeaders();
    return http.delete(Uri.parse(url), headers: headers);
  }

  // Check if the token is still valid
  Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) {
        return false;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/validate-token'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}