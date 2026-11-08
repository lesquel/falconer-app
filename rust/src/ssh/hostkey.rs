//! Host key pinning. A connection only proceeds when the server's SHA256
//! fingerprint equals the pin. There is no override path.
use std::sync::{Arc, Mutex};

use russh::keys::ssh_key::HashAlg;
use russh::keys::PublicKeyOrCertificate;
use subtle::ConstantTimeEq;

use crate::keys::fingerprint_sha256;

/// What the verifier should do with the presented key.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PinPolicy {
    /// Accept only this exact `SHA256:` fingerprint.
    Pinned(String),
    /// Record the fingerprint and abort the handshake (first-contact probe).
    ProbeOnly,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Verdict {
    Accept,
    Mismatch { expected: String, actual: String },
    Observed { actual: String },
}

pub fn decide(policy: &PinPolicy, actual: &str) -> Verdict {
    match policy {
        PinPolicy::Pinned(expected) => {
            let same = expected.len() == actual.len()
                && bool::from(expected.as_bytes().ct_eq(actual.as_bytes()));
            if same {
                Verdict::Accept
            } else {
                Verdict::Mismatch {
                    expected: expected.clone(),
                    actual: actual.to_string(),
                }
            }
        }
        PinPolicy::ProbeOnly => Verdict::Observed {
            actual: actual.to_string(),
        },
    }
}

pub fn fingerprint_of(key: &PublicKeyOrCertificate) -> String {
    match key {
        PublicKeyOrCertificate::PublicKey { key, .. } => fingerprint_sha256(key),
        PublicKeyOrCertificate::Certificate(cert) => {
            cert.public_key().fingerprint(HashAlg::Sha256).to_string()
        }
    }
}

/// Shared slot where the handler leaves its verdict for the caller.
pub type VerdictSlot = Arc<Mutex<Option<Verdict>>>;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn exact_pin_is_accepted() {
        let p = PinPolicy::Pinned("SHA256:abc".into());
        assert_eq!(decide(&p, "SHA256:abc"), Verdict::Accept);
    }

    #[test]
    fn any_difference_is_a_mismatch() {
        let p = PinPolicy::Pinned("SHA256:abc".into());
        for actual in ["SHA256:abd", "SHA256:ab", "sha256:abc", ""] {
            assert!(
                matches!(decide(&p, actual), Verdict::Mismatch { .. }),
                "{actual}"
            );
        }
    }

    #[test]
    fn probe_never_accepts() {
        assert_eq!(
            decide(&PinPolicy::ProbeOnly, "SHA256:x"),
            Verdict::Observed {
                actual: "SHA256:x".into()
            }
        );
    }
}
