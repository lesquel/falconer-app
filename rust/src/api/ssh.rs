//! SSH sessions exposed to Dart as opaque handles.
use std::sync::Arc;

use flutter_rust_bridge::frb;
use russh::client::Handle;
use zeroize::Zeroizing;

use crate::frb_generated::StreamSink;
use crate::sftp;
use crate::ssh::client::{self, PinningHandler};
use crate::ssh::exec;
use crate::ssh::shell::Shell;

pub struct ExecResult {
    pub exit_code: Option<u32>,
    pub stdout: Vec<u8>,
    pub stderr: Vec<u8>,
}

/// Reads the server host key fingerprint without authenticating.
pub async fn probe_host_fingerprint(host: String, port: u16) -> anyhow::Result<String> {
    Ok(client::probe_host_key(&host, port).await?)
}

#[frb(opaque)]
pub struct SshClient {
    handle: Arc<Handle<PinningHandler>>,
}

impl SshClient {
    /// Fails with `host_key_mismatch` when the server key differs from
    /// `pinned_fingerprint`. Callers must not offer a way to continue.
    pub async fn connect(
        host: String,
        port: u16,
        user: String,
        pinned_fingerprint: String,
        private_openssh: String,
    ) -> anyhow::Result<SshClient> {
        let private = Zeroizing::new(private_openssh);
        let handle = client::connect(&host, port, &user, &pinned_fingerprint, &private).await?;
        Ok(SshClient {
            handle: Arc::new(handle),
        })
    }

    pub async fn exec(
        &self,
        command: String,
        stdin: Option<Vec<u8>>,
    ) -> anyhow::Result<ExecResult> {
        let out = exec::run(&self.handle, &command, stdin).await?;
        Ok(ExecResult {
            exit_code: out.exit_code,
            stdout: out.stdout,
            stderr: out.stderr,
        })
    }

    pub async fn open_shell(&self, cols: u32, rows: u32) -> anyhow::Result<ShellSession> {
        let shell = Shell::open(&self.handle, cols, rows).await?;
        Ok(ShellSession { shell })
    }

    pub async fn upload(&self, local_path: String, remote_name: String) -> anyhow::Result<String> {
        Ok(sftp::upload(&self.handle, &local_path, &remote_name).await?)
    }

    #[frb(sync)]
    pub fn is_closed(&self) -> bool {
        self.handle.is_closed()
    }

    pub async fn disconnect(&self) {
        let _ = self
            .handle
            .disconnect(russh::Disconnect::ByApplication, "", "en")
            .await;
    }
}

#[frb(opaque)]
pub struct ShellSession {
    shell: Shell,
}

impl ShellSession {
    /// Batched terminal output; the stream ends when the channel closes.
    pub async fn output(&self, sink: StreamSink<Vec<u8>>) -> anyhow::Result<()> {
        Ok(self.shell.start(move |b| sink.add(b).is_ok())?)
    }

    pub async fn write(&self, data: Vec<u8>) -> anyhow::Result<()> {
        Ok(self.shell.write(&data).await?)
    }

    pub async fn resize(&self, cols: u32, rows: u32) -> anyhow::Result<()> {
        Ok(self.shell.resize(cols, rows).await?)
    }

    pub async fn close(&self) {
        self.shell.close().await;
    }

    #[frb(sync)]
    pub fn is_open(&self) -> bool {
        self.shell.is_open()
    }
}
