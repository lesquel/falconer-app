//! Connection setup: TCP + SSH handshake with pinned host key, then
//! public-key authentication with the device Ed25519 key.
use std::sync::{Arc, Mutex};
use std::time::Duration;

use russh::client::{self, Handle};
use russh::keys::{PrivateKeyWithHashAlg, PublicKeyOrCertificate};

use super::hostkey::{decide, fingerprint_of, PinPolicy, Verdict, VerdictSlot};
use crate::error::{CoreError, CoreResult};
use crate::keys::decode_private;

pub const CONNECT_TIMEOUT: Duration = Duration::from_secs(10);

/// Why the session ended (a server disconnect or a transport error), kept
/// so the app can show it when a terminal drops.
pub type CloseReason = Arc<Mutex<Option<String>>>;

pub struct PinningHandler {
    policy: PinPolicy,
    slot: VerdictSlot,
    closed: CloseReason,
}

impl client::Handler for PinningHandler {
    type Error = russh::Error;

    async fn check_server_key(
        &mut self,
        server_public_key: &PublicKeyOrCertificate,
    ) -> Result<bool, Self::Error> {
        let verdict = decide(&self.policy, &fingerprint_of(server_public_key));
        let ok = verdict == Verdict::Accept;
        if let Ok(mut s) = self.slot.lock() {
            *s = Some(verdict);
        }
        Ok(ok)
    }

    async fn disconnected(
        &mut self,
        reason: client::DisconnectReason<Self::Error>,
    ) -> Result<(), Self::Error> {
        let (text, result) = match reason {
            client::DisconnectReason::ReceivedDisconnect(info) => (
                format!("server closed the connection ({:?})", info.reason_code),
                Ok(()),
            ),
            client::DisconnectReason::Error(e) => (e.to_string(), Err(e)),
        };
        if let Ok(mut c) = self.closed.lock() {
            *c = Some(sanitize(&text));
        }
        result
    }
}

fn config() -> Arc<client::Config> {
    Arc::new(client::Config {
        inactivity_timeout: None,
        keepalive_interval: Some(Duration::from_secs(15)),
        keepalive_max: 3,
        nodelay: true,
        ..Default::default()
    })
}

async fn handshake(
    host: &str,
    port: u16,
    policy: PinPolicy,
) -> CoreResult<(Handle<PinningHandler>, CloseReason)> {
    let slot: VerdictSlot = Arc::new(Mutex::new(None));
    let closed: CloseReason = Arc::new(Mutex::new(None));
    let handler = PinningHandler {
        policy,
        slot: slot.clone(),
        closed: closed.clone(),
    };
    let fut = client::connect(config(), (host, port), handler);
    let res = tokio::time::timeout(CONNECT_TIMEOUT, fut)
        .await
        .map_err(|_| CoreError::Timeout)?;
    let verdict = slot.lock().ok().and_then(|s| s.clone());
    match (res, verdict) {
        (Ok(h), Some(Verdict::Accept)) => Ok((h, closed)),
        (_, Some(Verdict::Mismatch { expected, actual })) => {
            Err(CoreError::HostKeyMismatch { expected, actual })
        }
        (_, Some(Verdict::Observed { actual })) => Err(CoreError::HostKeyObserved { actual }),
        (Err(e), _) => Err(CoreError::Connect(sanitize(&e.to_string()))),
        (Ok(_), None) => Err(CoreError::Connect("host key was not verified".into())),
    }
}

/// Connects without authenticating to read the server's host key
/// fingerprint for an explicit user confirmation (SSH pairing).
pub async fn probe_host_key(host: &str, port: u16) -> CoreResult<String> {
    match handshake(host, port, PinPolicy::ProbeOnly).await {
        Err(CoreError::HostKeyObserved { actual }) => Ok(actual),
        Err(e) => Err(e),
        Ok(_) => Err(CoreError::Connect("probe unexpectedly accepted".into())),
    }
}

pub async fn connect(
    host: &str,
    port: u16,
    user: &str,
    pinned_fingerprint: &str,
    private_openssh: &str,
) -> CoreResult<(Handle<PinningHandler>, CloseReason)> {
    if !pinned_fingerprint.starts_with("SHA256:") {
        return Err(CoreError::HostKeyMismatch {
            expected: pinned_fingerprint.to_string(),
            actual: String::new(),
        });
    }
    let key = decode_private(private_openssh)?;
    let (mut session, closed) =
        handshake(host, port, PinPolicy::Pinned(pinned_fingerprint.into())).await?;
    let auth = session
        .authenticate_publickey(user, PrivateKeyWithHashAlg::new(Arc::new(key), None))
        .await
        .map_err(|e| CoreError::Connect(sanitize(&e.to_string())))?;
    if !auth.success() {
        return Err(CoreError::AuthFailed);
    }
    Ok((session, closed))
}

/// Keeps error text short and single-line; russh errors contain no secrets
/// but may be long.
pub fn sanitize(s: &str) -> String {
    s.chars().filter(|c| !c.is_control()).take(160).collect()
}
