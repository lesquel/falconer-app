//! Interactive PTY shell. Output is batched (see `batcher`) and delivered to a
//! sink callback; input and resize go through the write half.

use std::future::Future;
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
    pub fn start<F>(&self, sink: F) -> CoreResult<()>
    where
        F: FnMut(Vec<u8>) -> bool + Send + 'static,
    {
        let read = self
            .read
            .lock()
            .ok()
            .and_then(|mut r| r.take())
            .ok_or_else(|| CoreError::Channel("output already started".into()))?;
        let task = tokio::spawn(pump(read, sink));
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

/// The read side of a shell channel, so the output loop can be driven by a
/// fake channel in tests.
pub(crate) trait OutputSource: Send + 'static {
    fn next(&mut self) -> impl Future<Output = Option<ChannelMsg>> + Send;
}

impl OutputSource for ChannelReadHalf {
    fn next(&mut self) -> impl Future<Output = Option<ChannelMsg>> + Send {
        self.wait()
    }
}

/// Reads `src` until the channel closes, delivering batched output to
/// `sink`. The flush deadline is armed only when bytes land in an empty
/// buffer, so an idle shell sleeps on the channel with no timer.
pub(crate) async fn pump<S, F>(mut src: S, mut sink: F)
where
    S: OutputSource,
    F: FnMut(Vec<u8>) -> bool + Send + 'static,
{
    let mut batcher = OutputBatcher::default();
    let flush = tokio::time::sleep(FLUSH_INTERVAL);
    tokio::pin!(flush);
    let mut armed = false;
    loop {
        tokio::select! {
            msg = src.next() => match msg {
                Some(ChannelMsg::Data { ref data })
                | Some(ChannelMsg::ExtendedData { ref data, .. }) => {
                    let was_empty = batcher.is_empty();
                    if let Some(batch) = batcher.push(data) {
                        armed = false;
                        if !sink(batch) { return; }
                    } else if was_empty {
                        flush.as_mut().reset(tokio::time::Instant::now() + FLUSH_INTERVAL);
                        armed = true;
                    }
                }
                Some(ChannelMsg::Close) | Some(ChannelMsg::Eof) | None => break,
                Some(_) => {}
            },
            () = &mut flush, if armed => {
                armed = false;
                if let Some(batch) = batcher.flush() {
                    if !sink(batch) { return; }
                }
            }
        }
    }
    if let Some(batch) = batcher.flush() {
        let _ = sink(batch);
    }
}

#[cfg(test)]
mod tests {
    use std::sync::atomic::{AtomicUsize, Ordering};
    use std::sync::Arc;
    use std::time::Duration;

    use bytes::Bytes;
    use tokio::sync::mpsc;
    use tokio::time::Instant;

    use super::super::batcher::MIN_BATCH;
    use super::*;

    struct FakeChannel {
        rx: mpsc::UnboundedReceiver<ChannelMsg>,
        polls: Arc<AtomicUsize>,
    }

    impl OutputSource for FakeChannel {
        fn next(&mut self) -> impl Future<Output = Option<ChannelMsg>> + Send {
            self.polls.fetch_add(1, Ordering::SeqCst);
            self.rx.recv()
        }
    }

    type Batches = Arc<std::sync::Mutex<Vec<(Instant, Vec<u8>)>>>;

    fn spawn_pump() -> (mpsc::UnboundedSender<ChannelMsg>, Arc<AtomicUsize>, Batches) {
        let (tx, rx) = mpsc::unbounded_channel();
        let polls = Arc::new(AtomicUsize::new(0));
        let out: Batches = Arc::default();
        let sink_out = out.clone();
        tokio::spawn(pump(
            FakeChannel {
                rx,
                polls: polls.clone(),
            },
            move |b| {
                sink_out.lock().unwrap().push((Instant::now(), b));
                true
            },
        ));
        (tx, polls, out)
    }

    fn data(b: &[u8]) -> ChannelMsg {
        ChannelMsg::Data {
            data: Bytes::copy_from_slice(b),
        }
    }

    #[tokio::test(start_paused = true)]
    async fn an_idle_shell_does_not_wake_up() {
        let (_tx, polls, out) = spawn_pump();
        tokio::time::sleep(Duration::from_secs(1)).await;
        assert!(out.lock().unwrap().is_empty());
        assert_eq!(
            polls.load(Ordering::SeqCst),
            1,
            "one read, no timer wakeups"
        );
    }

    #[tokio::test(start_paused = true)]
    async fn a_single_byte_is_flushed_within_the_interval_then_idles() {
        let (tx, polls, out) = spawn_pump();
        tokio::time::sleep(Duration::from_millis(100)).await;
        let sent = Instant::now();
        tx.send(data(b"x")).unwrap();
        tokio::time::sleep(Duration::from_millis(50)).await;
        {
            let got = out.lock().unwrap();
            assert_eq!(got.len(), 1);
            assert_eq!(got[0].1, b"x");
            assert!(
                got[0].0 - sent <= FLUSH_INTERVAL,
                "flushed after {:?}",
                got[0].0 - sent
            );
        }
        let before = polls.load(Ordering::SeqCst);
        tokio::time::sleep(Duration::from_secs(1)).await;
        assert_eq!(
            polls.load(Ordering::SeqCst),
            before,
            "no wakeups after the flush"
        );
        assert_eq!(out.lock().unwrap().len(), 1);
    }

    #[tokio::test(start_paused = true)]
    async fn a_full_batch_is_emitted_at_once() {
        let (tx, _polls, out) = spawn_pump();
        let sent = Instant::now();
        tx.send(data(&vec![7u8; MIN_BATCH])).unwrap();
        tokio::task::yield_now().await;
        tokio::task::yield_now().await;
        let got = out.lock().unwrap();
        assert_eq!(got.len(), 1);
        assert_eq!(got[0].1.len(), MIN_BATCH);
        assert_eq!(got[0].0, sent, "no wait for the timer");
    }

    #[tokio::test(start_paused = true)]
    async fn pending_bytes_are_flushed_when_the_channel_closes() {
        let (tx, _polls, out) = spawn_pump();
        tx.send(data(b"bye")).unwrap();
        tx.send(ChannelMsg::Eof).unwrap();
        tokio::task::yield_now().await;
        tokio::task::yield_now().await;
        assert_eq!(out.lock().unwrap()[0].1, b"bye");
    }
}
