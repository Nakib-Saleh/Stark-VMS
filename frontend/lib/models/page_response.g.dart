// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageResponse<T> _$PageResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => PageResponse<T>(
  content: (json['content'] as List<dynamic>).map(fromJsonT).toList(),
  hasNext: json['hasNext'] as bool,
  totalElements: (json['totalElements'] as num).toInt(),
  number: (json['number'] as num?)?.toInt() ?? 0,
  size: (json['size'] as num?)?.toInt() ?? 10,
  totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$PageResponseToJson<T>(
  PageResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'content': instance.content.map(toJsonT).toList(),
  'hasNext': instance.hasNext,
  'totalElements': instance.totalElements,
  'number': instance.number,
  'size': instance.size,
  'totalPages': instance.totalPages,
};
