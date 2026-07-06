import 'package:flutter/material.dart';

RelativeRect popupMenuPositionForAnchor(BuildContext anchorContext) {
  final buttonBox = anchorContext.findRenderObject() as RenderBox;
  final overlayBox =
      Navigator.of(anchorContext).overlay!.context.findRenderObject()
          as RenderBox;
  final topLeft = buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox);
  return RelativeRect.fromRect(
    Rect.fromLTWH(
      topLeft.dx,
      topLeft.dy,
      buttonBox.size.width,
      buttonBox.size.height,
    ),
    Offset.zero & overlayBox.size,
  );
}
