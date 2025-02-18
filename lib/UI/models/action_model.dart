import 'package:flutter/material.dart';

class ActionModel {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback action;

  ActionModel({
    required this.title,
    required this.icon,
    required this.color,
    required this.action,
  });
}
