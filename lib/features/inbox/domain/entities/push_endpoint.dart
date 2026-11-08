/// Client-side mirror of the host's endpoint rule (TRD §6.6).
library;

import '../../../../shared/domain/tailnet.dart';

bool isAllowedPushEndpoint(String url) {
  final u = Uri.tryParse(url);
  if (u == null || u.host.isEmpty || u.userInfo.isNotEmpty) return false;
  if (u.scheme == 'https') return true;
  return u.scheme == 'http' && isTailnetHostName(u.host);
}
