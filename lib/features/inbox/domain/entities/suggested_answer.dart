/// An answer the confirm screen preselects. It travels as navigation `extra`,
/// never in a URL, so only in-app navigation (an inbox tap or the app's own
/// notification buttons) can set it. The screen still asks for the answer to
/// be confirmed with biometrics.
library;

class SuggestedAnswer {
  const SuggestedAnswer(this.action);

  /// A `ResponseKind` name: `allow` or `deny`.
  final String action;

  @override
  bool operator ==(Object other) => other is SuggestedAnswer && other.action == action;

  @override
  int get hashCode => action.hashCode;

  @override
  String toString() => 'SuggestedAnswer($action)';
}
