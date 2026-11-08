//! Groups terminal output so bytes cross the FFI bridge in batches of at
//! least `MIN_BATCH` bytes or `FLUSH_INTERVAL` after the first pending byte,
//! whichever comes first.
use std::time::Duration;

pub const MIN_BATCH: usize = 8 * 1024;
pub const FLUSH_INTERVAL: Duration = Duration::from_millis(16);

#[derive(Default)]
pub struct OutputBatcher {
    buf: Vec<u8>,
}

impl OutputBatcher {
    /// Appends bytes; returns a full batch once the size threshold is hit.
    pub fn push(&mut self, data: &[u8]) -> Option<Vec<u8>> {
        self.buf.extend_from_slice(data);
        if self.buf.len() >= MIN_BATCH {
            Some(std::mem::take(&mut self.buf))
        } else {
            None
        }
    }

    pub fn is_empty(&self) -> bool {
        self.buf.is_empty()
    }

    /// Called when the flush deadline passes or at end of stream.
    pub fn flush(&mut self) -> Option<Vec<u8>> {
        if self.buf.is_empty() {
            None
        } else {
            Some(std::mem::take(&mut self.buf))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn small_writes_wait_for_the_timer() {
        let mut b = OutputBatcher::default();
        assert_eq!(b.push(b"abc"), None);
        assert_eq!(b.push(b"def"), None);
        assert_eq!(b.flush(), Some(b"abcdef".to_vec()));
        assert_eq!(b.flush(), None);
    }

    #[test]
    fn reaching_the_size_threshold_emits_immediately() {
        let mut b = OutputBatcher::default();
        assert_eq!(b.push(&vec![1u8; MIN_BATCH - 1]), None);
        let out = b.push(&[2u8, 3u8]).expect("batch");
        assert_eq!(out.len(), MIN_BATCH + 1);
        assert_eq!(b.flush(), None);
    }
}
