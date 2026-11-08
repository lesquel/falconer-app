/// Freshness window for decrypted pushes (replay of old ciphertext).
library;

/// Pushes whose `ts` is older than this are discarded; the inbox sync over
/// SSH still brings the event in.
const pushMaxAge = Duration(hours: 24);

/// Tolerated clock skew between the host and the phone.
const pushMaxSkew = Duration(minutes: 5);

bool isFreshPush(DateTime at, DateTime now) =>
    !at.isBefore(now.subtract(pushMaxAge)) && !at.isAfter(now.add(pushMaxSkew));
