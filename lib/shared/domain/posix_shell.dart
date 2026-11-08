/// Strict POSIX single-quote escaping for commands sent over an SSH exec
/// channel. SSH has no argv: the remote login shell parses one string, so
/// every argument (including the program path) is single-quoted.
library;

/// Quotes [arg] so a POSIX shell sees it as exactly one literal word.
String shQuote(String arg) {
  if (arg.contains('\u0000')) {
    throw ArgumentError('NUL byte in shell argument');
  }
  return "'${arg.replaceAll("'", r"'\''")}'";
}

final _plainWord = RegExp(r'^[A-Za-z0-9._/~+@%=:,-]+$');

/// Leaves [arg] as is when a shell would read it as one word anyway, else
/// [shQuote]s it. Agents recognise an image path pasted without quotes.
String shQuoteIfNeeded(String arg) => _plainWord.hasMatch(arg) ? arg : shQuote(arg);

/// Joins [argv] into a command line where each element is one word.
String shJoin(List<String> argv) => argv.map(shQuote).join(' ');
