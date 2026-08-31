import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

bool isCupertinoPlatform(BuildContext context) =>
    Theme.of(context).platform == TargetPlatform.iOS ||
    Theme.of(context).platform == TargetPlatform.macOS;

Route<T> adaptiveRoute<T>(BuildContext context, WidgetBuilder builder) {
  return isCupertinoPlatform(context)
      ? CupertinoPageRoute<T>(builder: builder)
      : MaterialPageRoute<T>(builder: builder);
}

Future<bool?> showAdaptiveDeleteDialog(
  BuildContext context, {
  required String title,
  required String content,
  required Key cancelKey,
  required Key confirmKey,
}) {
  if (isCupertinoPlatform(context)) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            key: cancelKey,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            key: confirmKey,
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          key: cancelKey,
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          key: confirmKey,
          onPressed: () => Navigator.pop(context, true),
          child: const Text('删除'),
        ),
      ],
    ),
  );
}
