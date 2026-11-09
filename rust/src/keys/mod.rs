//! Device SSH keys: Ed25519 generation, OpenSSH import/export, fingerprints.
use russh::keys::ssh_key::private::Ed25519Keypair;
use russh::keys::ssh_key::{HashAlg, LineEnding, PrivateKey, PublicKey};
use zeroize::{Zeroize, Zeroizing};

use crate::error::{CoreError, CoreResult};

/// Key material handed to Dart. `private_openssh` is the only secret; Dart
/// stores it in Keystore-backed secure storage and never logs it.
pub struct KeyMaterial {
    pub private_openssh: Zeroizing<String>,
    pub public_openssh: String,
    pub fingerprint: String,
}

/// `SHA256:<base64 std, no padding>`, identical to `ssh-keygen -lf`.
pub fn fingerprint_sha256(key: &PublicKey) -> String {
    key.fingerprint(HashAlg::Sha256).to_string()
}

pub fn generate_ed25519(comment: &str) -> CoreResult<KeyMaterial> {
    let mut seed = Zeroizing::new([0u8; 32]);
    getrandom::fill(seed.as_mut()).map_err(|_| CoreError::InvalidKey("rng unavailable".into()))?;
    let pair = Ed25519Keypair::from_seed(&seed);
    let mut key = PrivateKey::from(pair);
    key.set_comment(comment);
    material(&key)
}

/// Imports an OpenSSH ed25519 key, decrypting it with [passphrase] when it
/// is protected. The result is re-encoded without encryption: it is stored in
/// Keystore-backed storage behind user verification.
pub fn import_private(openssh: &str, passphrase: Option<&str>) -> CoreResult<KeyMaterial> {
    let key = decode_with(openssh, passphrase.filter(|p| !p.is_empty()))?;
    material(&key)
}

pub fn decode_private(openssh: &str) -> CoreResult<PrivateKey> {
    decode_with(openssh, None)
}

fn decode_with(openssh: &str, passphrase: Option<&str>) -> CoreResult<PrivateKey> {
    let key = russh::keys::decode_secret_key(openssh, passphrase)
        .map_err(|_| CoreError::InvalidKey("unreadable private key or wrong passphrase".into()))?;
    if key.algorithm() != russh::keys::Algorithm::Ed25519 {
        return Err(CoreError::InvalidKey(
            "only ssh-ed25519 keys are supported".into(),
        ));
    }
    Ok(key)
}

pub fn public_fingerprint(openssh_public: &str) -> CoreResult<String> {
    let key = PublicKey::from_openssh(openssh_public.trim())
        .map_err(|_| CoreError::InvalidKey("unreadable public key".into()))?;
    Ok(fingerprint_sha256(&key))
}

fn material(key: &PrivateKey) -> CoreResult<KeyMaterial> {
    let private_openssh = key
        .to_openssh(LineEnding::LF)
        .map_err(|_| CoreError::InvalidKey("encode failed".into()))?;
    let public = key.public_key();
    let public_openssh = public
        .to_openssh()
        .map_err(|_| CoreError::InvalidKey("encode failed".into()))?;
    let mut owned = private_openssh.to_string();
    let out = Zeroizing::new(owned.clone());
    owned.zeroize();
    Ok(KeyMaterial {
        private_openssh: out,
        public_openssh,
        fingerprint: fingerprint_sha256(public),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    // Generated with `ssh-keygen -t ed25519`; fingerprint from `ssh-keygen -lf`.
    const PUB: &str =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRXhu0nk0PwgIUzDjCs8hg2Q9iqygfWq8fnSMOWybjj fixture";
    const PUB_FP: &str = "SHA256:i2cBF5DBtTy5/U7Y27668/2F1HhY/qwC4eALG8QAiQM";

    #[test]
    fn fingerprint_matches_ssh_keygen_format() {
        assert_eq!(public_fingerprint(PUB).unwrap(), PUB_FP);
    }

    #[test]
    fn generated_key_is_ed25519_and_round_trips() {
        let m = generate_ed25519("openmosh@test").unwrap();
        assert!(m.public_openssh.starts_with("ssh-ed25519 AAAA"));
        assert!(m.public_openssh.ends_with(" openmosh@test"));
        assert!(m.private_openssh.contains("BEGIN OPENSSH PRIVATE KEY"));
        assert!(m.fingerprint.starts_with("SHA256:"));
        assert!(!m.fingerprint.ends_with('='));
        let again = import_private(&m.private_openssh, None).unwrap();
        assert_eq!(again.public_openssh, m.public_openssh);
        assert_eq!(again.fingerprint, m.fingerprint);
        assert_eq!(
            public_fingerprint(&m.public_openssh).unwrap(),
            m.fingerprint
        );
    }

    #[test]
    fn two_generated_keys_differ() {
        let a = generate_ed25519("a").unwrap();
        let b = generate_ed25519("a").unwrap();
        assert_ne!(a.fingerprint, b.fingerprint);
    }

    /// The OS random source for key encryption in tests.
    struct OsRandom;
    impl russh::keys::ssh_key::rand_core::TryRng for OsRandom {
        type Error = core::convert::Infallible;
        fn try_next_u32(&mut self) -> Result<u32, Self::Error> {
            let mut b = [0u8; 4];
            self.try_fill_bytes(&mut b)?;
            Ok(u32::from_le_bytes(b))
        }
        fn try_next_u64(&mut self) -> Result<u64, Self::Error> {
            let mut b = [0u8; 8];
            self.try_fill_bytes(&mut b)?;
            Ok(u64::from_le_bytes(b))
        }
        fn try_fill_bytes(&mut self, dst: &mut [u8]) -> Result<(), Self::Error> {
            getrandom::fill(dst).expect("OS random source");
            Ok(())
        }
    }
    impl russh::keys::ssh_key::rand_core::TryCryptoRng for OsRandom {}

    /// A passphrase-protected key made at test time (no private key is kept
    /// in the repository), and its fingerprint.
    fn encrypted_fixture() -> (String, String) {
        let plain = generate_ed25519("fixture").unwrap();
        let key = PrivateKey::from_openssh(plain.private_openssh.as_bytes()).unwrap();
        let enc = key.encrypt(&mut OsRandom, "correct horse").unwrap();
        let text = enc.to_openssh(LineEnding::LF).unwrap().to_string();
        (text, plain.fingerprint)
    }

    #[test]
    fn passphrase_protected_key_imports_with_its_passphrase() {
        let (enc, fp) = encrypted_fixture();
        assert!(enc.starts_with("-----BEGIN"));
        let m = import_private(&enc, Some("correct horse")).unwrap();
        assert_eq!(m.fingerprint, fp);
        // Stored decrypted: later connections need no passphrase.
        let again = import_private(&m.private_openssh, None).unwrap();
        assert_eq!(again.fingerprint, fp);
    }

    #[test]
    fn passphrase_protected_key_needs_the_right_passphrase() {
        let (enc, _) = encrypted_fixture();
        assert_eq!(
            import_private(&enc, None).err().map(|e| e.code()),
            Some("invalid_key")
        );
        assert_eq!(
            import_private(&enc, Some("wrong")).err().map(|e| e.code()),
            Some("invalid_key")
        );
    }

    #[test]
    fn an_empty_passphrase_means_none() {
        let m = generate_ed25519("x").unwrap();
        assert!(import_private(&m.private_openssh, Some("")).is_ok());
    }

    #[test]
    fn import_rejects_garbage() {
        assert_eq!(
            import_private("not a key", None).err().map(|e| e.code()),
            Some("invalid_key")
        );
        assert!(public_fingerprint("ssh-ed25519 !!!").is_err());
    }
}
