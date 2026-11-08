//! Device SSH key operations exposed to Dart.
use flutter_rust_bridge::frb;

use crate::keys;

/// Returned to Dart once; the caller stores `private_openssh` in secure
/// storage immediately and drops its copy.
pub struct DeviceKeyMaterial {
    pub private_openssh: String,
    pub public_openssh: String,
    pub fingerprint: String,
}

impl From<keys::KeyMaterial> for DeviceKeyMaterial {
    fn from(m: keys::KeyMaterial) -> Self {
        Self {
            private_openssh: m.private_openssh.as_str().to_owned(),
            public_openssh: m.public_openssh,
            fingerprint: m.fingerprint,
        }
    }
}

#[frb(sync)]
pub fn generate_ed25519_key(comment: String) -> anyhow::Result<DeviceKeyMaterial> {
    Ok(keys::generate_ed25519(&comment)?.into())
}

#[frb(sync)]
pub fn import_private_key(private_openssh: String) -> anyhow::Result<DeviceKeyMaterial> {
    let private = zeroize::Zeroizing::new(private_openssh);
    Ok(keys::import_private(&private)?.into())
}

#[frb(sync)]
pub fn public_key_fingerprint(public_openssh: String) -> anyhow::Result<String> {
    Ok(keys::public_fingerprint(&public_openssh)?)
}

#[frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}
