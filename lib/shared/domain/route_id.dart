/// Path ids the router accepts (host, event, key ids): one URL-safe segment.
/// Shared so a notification route is validated the same way as the router.
final routeIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

bool isRouteId(String v) => routeIdPattern.hasMatch(v);
