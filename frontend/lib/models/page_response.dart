import 'package:json_annotation/json_annotation.dart';

part 'page_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.hasNext,
    required this.totalElements,
    this.number = 0,
    this.size = 10,
    this.totalPages = 0,
  });

  final List<T> content;
  final bool hasNext;
  final int totalElements;

  /// Zero-based page index, as the server counts (docs/API.md).
  final int number;
  final int size;
  final int totalPages;

  bool get last => !hasNext;

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PageResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$PageResponseToJson(this, toJsonT);
}
