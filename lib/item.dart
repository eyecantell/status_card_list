//import 'package:flutter/material.dart';

class Item {
  final String id;
  final String title;
  final String subtitle;
  final String html;
  String status; // Optional, can be removed if not needed later

  Item({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.html,
    this.status = 'pending', // Default value
  });
}