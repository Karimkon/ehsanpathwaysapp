import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ehsan_pathways/core/services/api_service.dart';

/// The link the server hands back for a share. When the user is signed in it
/// is a short /s/ link that counts the people it reaches (shown on My
/// Impact); otherwise it is the plain page.
class GuidedLink {
  const GuidedLink({required this.url, required this.tracked});

  final String url;
  final bool tracked;
}

/// "Whoever guides someone to good has a reward like the one who does it"
/// (Sahih Muslim 1893). Every share in the app goes through here so the
/// sharer can see what their sharing did.
class GuidedShare {
  GuidedShare._();

  static const _site = 'https://ehsanpathways.com';

  /// Ask the server for the link. Never throws: a slow or failed request
  /// falls back to the plain page so the share still happens.
  static Future<GuidedLink> resolve(
    Dio dio, {
    required String type,
    required String key,
    required String fallbackPath,
  }) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/share',
        data: {'type': type, 'key': key},
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final url = res.data?['url'];
      if (url is String && url.startsWith('http')) {
        return GuidedLink(url: url, tracked: res.data?['tracked'] == true);
      }
    } catch (_) {
      // Offline or the item is unknown to the server: share the page itself.
    }
    return GuidedLink(url: '$_site$fallbackPath', tracked: false);
  }

  /// Resolve the link, then open the system share sheet with [text] built
  /// around it.
  static Future<void> share(
    BuildContext context, {
    required String type,
    required String key,
    required String fallbackPath,
    required String subject,
    required String Function(String url) text,
  }) async {
    final dio = ProviderScope.containerOf(context, listen: false).read(apiProvider);
    final box = context.findRenderObject() as RenderBox?;
    final link = await resolve(dio, type: type, key: key, fallbackPath: fallbackPath);

    await Share.share(
      text(link.url),
      subject: subject,
      // iPad needs an anchor for the share popover.
      sharePositionOrigin: box != null && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }
}
