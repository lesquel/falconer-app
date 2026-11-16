//! SFTP uploads into `~/.falconer/uploads/` (directory 0700, files 0600).
use russh::client::Handle;
use russh_sftp::client::SftpSession;
use russh_sftp::protocol::{FileAttributes, OpenFlags};
use tokio::io::{AsyncReadExt, AsyncWriteExt};

use crate::error::{CoreError, CoreResult};
use crate::ssh::client::{sanitize, PinningHandler};

pub const MAX_UPLOAD_BYTES: u64 = 50 * 1024 * 1024;
pub const UPLOAD_DIR: &str = ".falconer/uploads";

/// Defense in depth: the Dart side already sanitizes, but the core refuses
/// anything that could escape the uploads directory.
pub fn is_safe_name(name: &str) -> bool {
    !name.is_empty()
        && name.len() <= 128
        && !name.starts_with('.')
        && name
            .bytes()
            .all(|b| b.is_ascii_alphanumeric() || b == b'.' || b == b'_' || b == b'-')
}

fn attrs(mode: u32) -> FileAttributes {
    FileAttributes {
        size: None,
        uid: None,
        user: None,
        gid: None,
        group: None,
        permissions: Some(mode),
        atime: None,
        mtime: None,
    }
}

/// Uploads `local_path` as `remote_name`; returns the absolute remote path.
pub async fn upload(
    handle: &Handle<PinningHandler>,
    local_path: &str,
    remote_name: &str,
) -> CoreResult<String> {
    if !is_safe_name(remote_name) {
        return Err(CoreError::Sftp("unsafe file name".into()));
    }
    let mut local = tokio::fs::File::open(local_path)
        .await
        .map_err(|_| CoreError::Sftp("cannot read local file".into()))?;
    let size = local
        .metadata()
        .await
        .map_err(|_| CoreError::Sftp("cannot read local file".into()))?
        .len();
    if size > MAX_UPLOAD_BYTES {
        return Err(CoreError::TooLarge);
    }

    let s_err = |e: russh_sftp::client::error::Error| CoreError::Sftp(sanitize(&e.to_string()));
    let ch_err = |e: russh::Error| CoreError::Channel(sanitize(&e.to_string()));
    let channel = handle.channel_open_session().await.map_err(ch_err)?;
    channel
        .request_subsystem(true, "sftp")
        .await
        .map_err(ch_err)?;
    let sftp = SftpSession::new(channel.into_stream())
        .await
        .map_err(s_err)?;

    let home = sftp.canonicalize(".").await.map_err(s_err)?;
    let base = format!("{}/.falconer", home.trim_end_matches('/'));
    let dir = format!("{base}/uploads");
    for d in [&base, &dir] {
        if !sftp.try_exists(d.as_str()).await.map_err(s_err)? {
            sftp.create_dir(d.as_str()).await.map_err(s_err)?;
        }
        sftp.set_metadata(d.as_str(), attrs(0o700))
            .await
            .map_err(s_err)?;
    }

    let remote = format!("{dir}/{remote_name}");
    let mut file = sftp
        .open_with_flags_and_attributes(
            remote.as_str(),
            OpenFlags::CREATE | OpenFlags::EXCLUDE | OpenFlags::WRITE,
            attrs(0o600),
        )
        .await
        .map_err(s_err)?;
    // russh-sftp pipelines `File` writes: up to 16 requests (about 32 KB
    // each, in order) stay in flight and `shutdown` waits for every ack, so
    // a 64 KB read buffer keeps the window full without our own queue.
    let mut buf = vec![0u8; 64 * 1024];
    let mut sent: u64 = 0;
    loop {
        let n = local
            .read(&mut buf)
            .await
            .map_err(|_| CoreError::Sftp("cannot read local file".into()))?;
        if n == 0 {
            break;
        }
        sent += n as u64;
        if sent > MAX_UPLOAD_BYTES {
            let _ = file.shutdown().await;
            let _ = sftp.remove_file(remote.as_str()).await;
            return Err(CoreError::TooLarge);
        }
        file.write_all(&buf[..n])
            .await
            .map_err(|e| CoreError::Sftp(sanitize(&e.to_string())))?;
    }
    file.shutdown()
        .await
        .map_err(|e| CoreError::Sftp(sanitize(&e.to_string())))?;
    let _ = sftp.close().await;
    Ok(remote)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn safe_names() {
        assert!(is_safe_name("a1b2c3d4-shot_1.png"));
        for bad in [
            "",
            ".hidden",
            "../x",
            "a/b",
            "a b",
            "é.png",
            &"a".repeat(129),
        ] {
            assert!(!is_safe_name(bad), "{bad}");
        }
    }
}
