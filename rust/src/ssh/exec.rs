//! Exec channel used for `openmosh-hook … --json` calls.
use std::time::Duration;

use russh::client::Handle;
use russh::ChannelMsg;

use super::client::{sanitize, PinningHandler};
use crate::error::{CoreError, CoreResult};

pub const MAX_OUTPUT: usize = 4 * 1024 * 1024;
pub const EXEC_TIMEOUT: Duration = Duration::from_secs(30);

pub struct ExecOutput {
    pub exit_code: Option<u32>,
    pub stdout: Vec<u8>,
    pub stderr: Vec<u8>,
}

pub async fn run(
    handle: &Handle<PinningHandler>,
    command: &str,
    stdin: Option<Vec<u8>>,
) -> CoreResult<ExecOutput> {
    tokio::time::timeout(EXEC_TIMEOUT, run_inner(handle, command, stdin))
        .await
        .map_err(|_| CoreError::Timeout)?
}

async fn run_inner(
    handle: &Handle<PinningHandler>,
    command: &str,
    stdin: Option<Vec<u8>>,
) -> CoreResult<ExecOutput> {
    let ch_err = |e: russh::Error| CoreError::Channel(sanitize(&e.to_string()));
    let mut channel = handle.channel_open_session().await.map_err(ch_err)?;
    channel.exec(true, command).await.map_err(ch_err)?;
    if let Some(input) = stdin {
        channel.data(&input[..]).await.map_err(ch_err)?;
    }
    channel.eof().await.map_err(ch_err)?;

    let mut out = ExecOutput {
        exit_code: None,
        stdout: Vec::new(),
        stderr: Vec::new(),
    };
    while let Some(msg) = channel.wait().await {
        match msg {
            ChannelMsg::Data { ref data } => append(&mut out.stdout, data)?,
            ChannelMsg::ExtendedData { ref data, ext: 1 } => append(&mut out.stderr, data)?,
            ChannelMsg::ExitStatus { exit_status } => out.exit_code = Some(exit_status),
            ChannelMsg::Close => break,
            _ => {}
        }
    }
    Ok(out)
}

fn append(buf: &mut Vec<u8>, data: &[u8]) -> CoreResult<()> {
    if buf.len() + data.len() > MAX_OUTPUT {
        return Err(CoreError::TooLarge);
    }
    buf.extend_from_slice(data);
    Ok(())
}
