part of '../media_attachment_fields.dart';

bool _isHttpUrl(String value) =>
    value.startsWith('http://') || value.startsWith('https://');
