import 'package:flutter/material.dart';

class DiscountCardFields {
  static const String table = 'discount_cards';
  
  static const String id = '_id';
  static const String storeName = 'storeName';
  static const String code = 'code';
  static const String format = 'format'; // Соответствует твоей БД
  static const String color = 'color';  // Добавили поле
}

class DiscountCardModel {
  final int? id;
  final String storeName;
  final String code;
  final String format;
  final int color; // Храним цвет как int (0xFF...)

  DiscountCardModel({
    this.id,
    required this.storeName,
    required this.code,
    required this.format,
    required this.color,
  });

  DiscountCardModel copyWith({
    int? id,
    String? storeName,
    String? code,
    String? format,
    int? color,
  }) =>
      DiscountCardModel(
        id: id ?? this.id,
        storeName: storeName ?? this.storeName,
        code: code ?? this.code,
        format: format ?? this.format,
        color: color ?? this.color,
      );

  static DiscountCardModel fromMap(Map<String, dynamic> map) => DiscountCardModel(
        id: map[DiscountCardFields.id] as int?,
        storeName: map[DiscountCardFields.storeName] as String,
        code: map[DiscountCardFields.code] as String,
        format: map[DiscountCardFields.format] as String,
        color: map[DiscountCardFields.color] as int,
      );

  Map<String, dynamic> toMap() => {
        DiscountCardFields.id: id,
        DiscountCardFields.storeName: storeName,
        DiscountCardFields.code: code,
        DiscountCardFields.format: format,
        DiscountCardFields.color: color,
      };
}