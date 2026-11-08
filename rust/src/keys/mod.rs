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

    // `ssh-keygen -t ed25519 -N 'correct horse' -C fixture`, a throwaway key.
    const ENC: &str = "-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABCmrFjB/C
PW9O5jlJae2uI3AAAAIAAAAAEAAAAzAAAAC3NzaC1lZDI1NTE5AAAAIIO+7N5fVfjXDfx9
bB2wZjB7fDXImDYiPSnb8rudKerXAAAAkBLh+GzH/W6nn+UreV3tuaJdtj//i1U6Rtt0uJ
nouYWKfQBkKUAxSXf9zYs/zsw863HHBUZGZ86vp8ARiXNDv40qjkO2wumss74F4ahPAbKT
xBODKGhWUdCx8ecZA0ms4oSY+stYd3H2L+ZvxZF2U70L3HYzDjqssf+lgRW8XEz7AYcSiZ
vIoJUliEfvEblJDQ==
-----END OPENSSH PRIVATE KEY-----
";
    const ENC_FP: &str = "SHA256:e3XaXzU3klK3a3Rh54xGCpIDjiLQjlfDuionKtiXkAg";

    #[test]
    fn passphrase_protected_key_imports_with_its_passphrase() {
        let m = import_private(ENC, Some("correct horse")).unwrap();
        assert_eq!(m.fingerprint, ENC_FP);
        // Stored decrypted: later connections need no passphrase.
        let again = import_private(&m.private_openssh, None).unwrap();
        assert_eq!(again.fingerprint, ENC_FP);
    }

    #[test]
    fn passphrase_protected_key_needs_the_right_passphrase() {
        assert_eq!(
            import_private(ENC, None).err().map(|e| e.code()),
            Some("invalid_key")
        );
        assert_eq!(
            import_private(ENC, Some("wrong")).err().map(|e| e.code()),
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
