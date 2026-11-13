//! Error type crossing the bridge. The Display form is `<code>: <detail>` so the
//! Dart side can map codes to domain failures. Details never contain secrets.
use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CoreError {
    /// Server presented a host key whose fingerprint differs from the pin.
    /// Not overridable.
    HostKeyMismatch {
        expected: String,
        actual: String,
    },
    /// Probe completed: the observed fingerprint is carried for confirmation.
    HostKeyObserved {
        actual: String,
    },
    AuthFailed,
    /// The server completed the handshake but never answered the key (for
    /// example Tailscale SSH holding port 22 in "check" mode).
    AuthTimeout,
    Connect(String),
    Channel(String),
    InvalidKey(String),
    Sftp(String),
    Timeout,
    TooLarge,
}

impl CoreError {
    pub fn code(&self) -> &'static str {
        match self {
            CoreError::HostKeyMismatch { .. } => "host_key_mismatch",
            CoreError::HostKeyObserved { .. } => "host_key_observed",
            CoreError::AuthFailed => "auth_failed",
            CoreError::AuthTimeout => "auth_timeout",
            CoreError::Connect(_) => "connect_failed",
            CoreError::Channel(_) => "channel_failed",
            CoreError::InvalidKey(_) => "invalid_key",
            CoreError::Sftp(_) => "sftp_failed",
            CoreError::Timeout => "timeout",
            CoreError::TooLarge => "too_large",
        }
    }
}

impl fmt::Display for CoreError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            CoreError::HostKeyMismatch { expected, actual } => {
                write!(f, "{}: expected {expected} got {actual}", self.code())
            }
            CoreError::HostKeyObserved { actual } => write!(f, "{}: {actual}", self.code()),
            CoreError::AuthFailed
            | CoreError::AuthTimeout
            | CoreError::Timeout
            | CoreError::TooLarge => {
                write!(f, "{}", self.code())
            }
            CoreError::Connect(d)
            | CoreError::Channel(d)
            | CoreError::InvalidKey(d)
            | CoreError::Sftp(d) => write!(f, "{}: {d}", self.code()),
        }
    }
}

impl std::error::Error for CoreError {}

pub type CoreResult<T> = Result<T, CoreError>;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn display_starts_with_stable_code() {
        let e = CoreError::HostKeyMismatch {
            expected: "SHA256:a".into(),
            actual: "SHA256:b".into(),
        };
        assert_eq!(
            e.to_string(),
            "host_key_mismatch: expected SHA256:a got SHA256:b"
        );
        assert_eq!(CoreError::AuthFailed.to_string(), "auth_failed");
        assert_eq!(CoreError::AuthTimeout.to_string(), "auth_timeout");
    }
}
