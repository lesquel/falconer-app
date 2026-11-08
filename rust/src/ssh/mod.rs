//! SSH client: pinned host keys, PTY shell with batched output, exec channel.
pub mod batcher;
pub mod client;
pub mod exec;
pub mod hostkey;
pub mod shell;
