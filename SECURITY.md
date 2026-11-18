# Security policy

## Supported versions

| Version | Security fixes |
|---|---|
| 0.2.x | Yes |
| Older than 0.2 | No: update to the latest release |

Fixes ship in the next 0.2.x release, published on the
[releases page](https://github.com/lesquel/falconer-app/releases).

## Reporting a vulnerability

Report it privately through GitHub's private vulnerability reporting:
<https://github.com/lesquel/falconer-app/security/advisories/new>.

Do not open a public issue, pull request or discussion about it. If the problem is in the
computer side (`falconer-hook`), report it in
[falconer-hook](https://github.com/lesquel/falconer-hook/security/advisories/new) instead; if you
are not sure, report it here.

Please include:

- the app version (Settings) and, if relevant, the `falconer-hook version` output;
- the phone model and Android version;
- the steps to reproduce, and what an attacker gains.

Remove real addresses, host names, keys and tokens from logs and screenshots. Use placeholder
values such as `100.88.77.66` or `host.tailnet-example.ts.net`.

## What to expect

- An acknowledgement within 7 days.
- A first assessment (confirmed or not, and how severe) within 14 days.
- Updates in the private advisory while a fix is prepared, and credit in the advisory when it is
  published, unless you prefer to stay anonymous.

This is a small, volunteer-maintained project, so these are goals, not guarantees.

## Threat model

### What the app is for

The app is an SSH terminal. Pairing a phone with a computer gives that phone a **full shell on
the computer**, on purpose: it is how you reach your agents. So the main thing to protect is the
phone, and the app is built around that:

- The phone's SSH key is created on the phone and stored under an Android Keystore key that needs
  your fingerprint, face or screen lock for every new connection. The hardware enforces it.
- On the computer, `falconer-hook` adds that key to `authorized_keys` as
  `restrict,pty,from="<phone ip>"`, only after you confirm the pairing on the computer.
- An optional app lock asks for verification when the app opens and after 60 s in the background.
- A lost phone is revoked from the computer with `falconer-hook devices revoke <id>`, or from
  another paired phone in the app.

### Between the phone and the computer

- **Tailscale only.** The phone reaches the computer over SSH inside your tailnet; nothing is
  exposed to the internet.
- **Host key pinning.** The computer's SSH host key is pinned at pairing. If it changes, the
  connection is refused and the app offers no way to continue.
- **End-to-end encrypted notifications.** Notifications go through a UnifiedPush distributor such
  as ntfy. The hook encrypts each one for the phone (X25519, HKDF-SHA256, XChaCha20-Poly1305), so
  ntfy and anything in between only see ciphertext. Old, future-dated and replayed pushes are
  dropped.

### On the phone

- **The push key is not bound to user verification.** Notifications are decrypted in the
  background, without a prompt, so the key that decrypts them cannot require biometrics. Someone
  with root or forensic access to the unlocked device could read past notifications with it. It
  cannot open an SSH connection or answer an agent.
- **No screenshots.** `FLAG_SECURE` is set on the whole app: no screenshots, screen recording or
  recents thumbnail.
- **No backups.** App data is excluded from cloud backups and device transfers.
- **External links are blocked.** Other apps and web pages cannot open a screen in the app, fill in
  a code or preselect an answer. `openmosh://` links only open the app at its home screen (that is
  how a Web Push notification tap launches it). Approve and Deny always need your verification on
  the confirm screen.
- **Notification taps are HMAC-bound to notifications the app itself posted.** Each notification
  carries an HMAC-SHA256 tag under a random per-install key kept in secure storage. A forged
  notification intent from another app, without a valid tag, only opens the home screen and
  cannot preselect an answer.
- **Clipboard and paste.** Copied terminal text and public keys are marked sensitive so keyboards
  do not preview them. Pasted text is stripped of escape and control characters so it cannot end a
  bracketed paste early or inject terminal commands.
- **No third-party SDKs.** No analytics, crash reporting or Google Play services. The app talks to
  your hosts over the tailnet and downloads speech models only when you ask for one.

### Out of scope

Attacks that need control of your Tailscale account, your computer, or your phone while it is
unlocked and the app is open.
