//! OpenMosh native core: SSH terminal, hook exec channel, SFTP uploads and
//! device SSH key handling. Exposed to Dart through `api` only.
#![deny(unsafe_op_in_unsafe_fn)]

pub mod api;
pub mod error;
mod frb_generated;
pub mod keys;
pub mod sftp;
pub mod ssh;
