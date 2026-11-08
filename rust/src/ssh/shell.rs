//! Interactive PTY shell. Output is batched (see `batcher`) and delivered to a
//! sink callback; input and resize go through the write half.

use std::sync::Mutex;

use russh::client::{Handle, Msg};
use russh::{ChannelMsg, ChannelReadHalf, ChannelWriteHalf};
use tokio::task::JoinHandle;

use super::batcher::{OutputBatcher, FLUSH_INTERVAL};
use super::client::{sanitize, PinningHandler};
use crate::error::{CoreError, CoreResult};

pub const TERM: &str = "xterm-256color";

pub struct Shell {
    writer: ChannelWriteHalf<Msg>,
    read: Mutex<Option<ChannelReadHalf>>,
    reader: Mutex<Option<JoinHandle<()>>>,
}

impl Shell {
    /// Opens a PTY + shell. Output is not read until [`Shell::start`].
    pub async fn open(handle: &Handle<PinningHandler>, cols: u32, rows: u32) -> CoreResult<Self> {
        let ch_err = |e: russh::Error| CoreError::Channel(sanitize(&e.to_string()));
        let channel = handle.channel_open_session().await.map_err(ch_err)?;
        channel
            .request_pty(false, TERM, cols, rows, 0, 0, &[])
            .await
            .map_err(ch_err)?;
        channel.request_shell(false).await.map_err(ch_err)?;
        let (read, writer) = channel.split();
        Ok(Self {
            writer,
            read: Mutex::new(Some(read)),
            reader: Mutex::new(None),
        })
    }

    /// Starts delivering batched output to `sink`, which returns `false` once
    /// the consumer is gone. The sink is dropped when the channel closes,
    /// which ends the Dart stream. Can be called once.
    pub fn start<F>(&self, mut sink: F) -> CoreResult<()>
    where
        F: FnMut(Vec<u8>) -> bool + Send + 'static,
    {
        let mut read = self
            .read
            .lock()
            .ok()
            .and_then(|mut r| r.take())
            .ok_or_else(|| CoreError::Channel("output already started".into()))?;
        let task = tokio::spawn(async move {
            let mut batcher = OutputBatcher::default();
            let mut tick = tokio::time::interval(FLUSH_INTERVAL);
            tick.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Delay);
            loop {
                tokio::select! {
                    msg = read.wait() => match msg {
                        Some(ChannelMsg::Data { ref data })
                        | Some(ChannelMsg::ExtendedData { ref data, .. }) => {
                            if let Some(batch) = batcher.push(data) {
                                if !sink(batch) { return; }
                            }
                        }
                        Some(ChannelMsg::Close) | Some(ChannelMsg::Eof) | None => break,
                        Some(_) => {}
                    },
                    _ = tick.tick() => {
                        if let Some(batch) = batcher.flush() {
                            if !sink(batch) { return; }
                        }
                    }
                }
            }
            if let Some(batch) = batcher.flush() {
                let _ = sink(batch);
            }
        });
        if let Ok(mut r) = self.reader.lock() {
            *r = Some(task);
        }
        Ok(())
    }

    pub async fn write(&self, data: &[u8]) -> CoreResult<()> {
        self.writer
            .data(data)
            .await
            .map_err(|e| CoreError::Channel(sanitize(&e.to_string())))
    }

    pub async fn resize(&self, cols: u32, rows: u32) -> CoreResult<()> {
        self.writer
            .window_change(cols, rows, 0, 0)
            .await
            .map_err(|e| CoreError::Channel(sanitize(&e.to_string())))
    }

    pub async fn close(&self) {
        let _ = self.writer.close().await;
        if let Ok(mut r) = self.reader.lock() {
            if let Some(t) = r.take() {
                t.abort();
            }
        }
    }

    pub fn is_open(&self) -> bool {
        self.reader
            .lock()
            .map(|r| r.as_ref().map(|t| !t.is_finished()).unwrap_or(true))
            .unwrap_or(false)
    }
}
