/// Browser push services a Web Push registration may point at. The endpoint
/// is user-supplied (pasted from the PWA), so the host must belong to one of
/// the services browsers actually use; anything else would make the OpenMosh
/// host POST to an arbitrary https URL.
library;

const _exactHosts = {
  'fcm.googleapis.com',
  'web.push.apple.com',
  'updates.push.services.mozilla.com',
};

/// Domains whose subdomains are accepted (`*.push.apple.com`, ...).
const _suffixDomains = ['push.apple.com', 'push.services.mozilla.com', 'notify.windows.com'];

/// True for an `https` URL whose parsed host is a known push service, matched
/// exactly or as a proper dot-suffix (never as a substring).
bool isKnownWebPushEndpoint(String url) {
  final u = Uri.tryParse(url);
  if (u == null || u.scheme != 'https') return false;
  final host = u.host.toLowerCase();
  if (host.isEmpty) return false;
  if (_exactHosts.contains(host)) return true;
  return _suffixDomains.any((d) => host.endsWith('.$d'));
}
