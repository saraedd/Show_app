import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:show_app/screens/profile_page.dart';
import 'package:show_app/screens/update_show_page.dart';
import 'package:show_app/screens/add_show_page.dart';
import '../models/show_model.dart';
import '../services/api_service.dart';
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  late Future<List<Show>> _showsFuture;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadShows();
  }

  void _loadShows() {
    setState(() {
      _isLoading = true;
      _showsFuture = _apiService.getShows();
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.getShows();
      _loadShows(); // Reload shows after successful refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shows'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('All', 'all'),
                  _buildCategoryChip('Movies', 'movie'),
                  _buildCategoryChip('Series', 'serie'),
                  _buildCategoryChip('Anime', 'anime'),
                ],
              ),
            ),
          ),

          // Shows list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: FutureBuilder<List<Show>>(
                future: _showsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _handleRefresh,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.movie_filter_outlined, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No shows available'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              await _navigateToAddShow(context);
                            },
                            child: const Text('Add a Show'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Filter shows by selected category if not 'all'
                    final shows = _selectedCategory == 'all'
                        ? snapshot.data!
                        : snapshot.data!
                        .where((show) => show.category == _selectedCategory)
                        .toList();

                    if (shows.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.filter_alt_outlined, size: 60, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text('No shows in the "$_selectedCategory" category'),
                          ],
                        ),
                      );
                    }

                    setState(() {
                      _isLoading = false;
                    });

                    return ListView.builder(
                      itemCount: shows.length,
                      itemBuilder: (context, index) {
                        final show = shows[index];
                        return _buildShowCard(context, show);
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () async {
          await _navigateToAddShow(context);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _selectedCategory == value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = value;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blueAccent.withOpacity(0.2),
        checkmarkColor: Colors.blueAccent,
        labelStyle: TextStyle(
          color: isSelected ? Colors.blueAccent : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildShowCard(BuildContext context, Show show) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: InkWell(
        onTap: () async {
          await _navigateToUpdateShow(context, show);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: show.image.isNotEmpty
                    ? Image.network(
                  show.image,
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.white),
                    );
                  },
                )
                    : Container(
                  width: 80,
                  height: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.movie_outlined, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),

              // Show details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      show.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(
                        show.category,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: _getCategoryColor(show.category),
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      show.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Action buttons
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    onPressed: () async {
                      await _navigateToUpdateShow(context, show);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      _showDeleteDialog(context, show);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'movie':
        return Colors.blue.withOpacity(0.2);
      case 'serie':
        return Colors.green.withOpacity(0.2);
      case 'anime':
        return Colors.orange.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Future<void> _navigateToAddShow(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddShowPage()),
    );

    if (result == true) {
      // If a show was added, refresh the list
      _handleRefresh();
    }
  }

  Future<void> _navigateToUpdateShow(BuildContext context, Show show) async {
    // Convert Show to a Map to match the expected format in UpdateShowPage
    final showMap = {
      'id': show.id,
      'title': show.title,
      'description': show.description,
      'category': show.category,
      'image': show.image,
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdateShowPage(show: showMap)),
    );

    if (result == true) {
      // If a show was updated, refresh the list
      _handleRefresh();
    }
  }

  void _showDeleteDialog(BuildContext context, Show show) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Show'),
        content: Text('Are you sure you want to delete "${show.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                await _apiService.deleteShow(show.id);

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Show deleted successfully')),
                );

                // Refresh the list
                _handleRefresh();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting show: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
