# Agent screen fixtures

Plain-text screens (ANSI already stripped, as `falconer-hook herdr read` returns them)
used by `parse_agent_screen_test.dart`. One folder per agent id, as the hook names them.

No fixture is a live capture: running the agents until they show a permission prompt
needs a model call and an approval decision, which these tests must never take. Every
screen is **reconstructed** from the sources listed below. Re-capture them inside a
throwaway `omtest-*` Herdr session when the agent UIs change.

| Agent | Provenance |
|---|---|
| claude | Reconstructed. Prompt strings ("Do you want to proceed?", "Yes, and don't ask again for ... commands in", "No, and tell Claude what to do differently", `❯` pointer, "Esc to cancel", "? for shortcuts") checked against the installed Claude Code 2.1.322 binary. |
| codex | Reconstructed. Strings ("Would you like to run the following command?", "Yes, just this once", "Yes, and don't ask again for this command in this session", "No, and tell Codex what to do differently", "Ask Codex to do anything", "context left", "for shortcuts") checked against the installed codex-cli 0.154.0 binary. The `›` cursor and numbering are from memory of its TUI. |
| pi | Reconstructed from the installed pi 1.5.0 sources: `ExtensionSelectorComponent` (border, title, `→ ` selected prefix, "↑↓ navigate  enter select  esc cancel"), `ctx.ui.confirm` options `["Yes", "No"]`, editor drawn between two `─` rules. |
| kiro | Reconstructed. "Allow this action? Use 't' to trust (always allow) this tool for the session. [y/n/t]:" checked against the installed kiro-cli 2.28.0 binary. The `t` answer is not offered because `t` is not an allowed pane key. |
| opencode | Reconstructed from the installed opencode 1.18.21 bundle: "△ Permission required", options "Allow once" / "Allow always" / "Reject", left/right + enter navigation, escape = reject, "Ask anything..." placeholder. The highlighted option is only a background color, so the parser assumes the default (first) one. |
| gemini | Reconstructed from memory of Gemini CLI (not installed): boxed confirmation, `●` radio, "Allow execution of: '...'?", "Type your message or @path/to/file". |
| copilot | Reconstructed from memory of GitHub Copilot CLI (not installed). |
| cursor | Reconstructed from memory of Cursor agent CLI (not installed). |
| amp | Reconstructed (not installed); layout is an assumption. |
| aider | Reconstructed from aider's documented prompts: "(Y)es/(N)o/(D)on't ask again [Yes]:" and the `> ` input prompt. |
| generic | Synthetic, for the conservative detector used when the agent is unknown. |

Fixture names: `permission*` / `select` contain a real menu, `plain` only output,
`input` an input line with a draft, `ambiguous` numbered lists or questions in normal
output that must never become a menu.

## Who said what (`conversation.txt`)

Each `conversation.txt` holds a past user turn, an agent reply and a tool call, for the
`TextRole` detection. Reconstructed like the others; the prefixes come from:

| Agent | User prefix | Tool marker | Source |
|---|---|---|---|
| claude | `❯ ` (`> ` fallback) at column 0 | `● Name(args)` (`⏺` on macOS), `⎿` rows | Verified in the Claude Code 2.1.322 binary: the user message renders `pointer + " " + text` (pointer `❯` or `>`); bullet is `⏺` on macOS else `●`; `⎿` result rows. |
| codex | `› ` at column 0 | `• Ran`, `• Explored`, `• Edited` ... with `└` rows | Partly verified in the codex-cli 0.154.0 binary (`›`, `Explored`, `Exploring`, `Edited`, `Added`, `Deleted`, `Waited for background terminal`, `Updated Plan` present); the history-cell layout is from memory of its TUI. |
| pi | none: user messages differ only by background color, which `herdr read` drops | `$ command`, `read|edit|write|ls <path>` headers | Verified in the installed pi 1.5.0 sources (`UserMessageComponent`, `renderers/bash.js`, `formatToolCallWithArgs`). User turns therefore stay agent text. |
| kiro | `> ` echoed by the REPL | none detected | Same `> ` prompt as the `input` fixture; echo in scrollback is assumed. |
| aider | `> ` echoed by prompt_toolkit | none detected | Aider's documented `> ` prompt. |
| gemini | `> ` (not boxed) | boxed `✔  ToolName` rows | From memory (not installed). |
| opencode | lines behind the `┃` bar | none detected | Same bar as the reconstructed `plain` fixture; not re-verified in the minified bundle. |
| shell | `user@host:dir$ `, `[user@host dir]$ `, `user@host dir % `, `$ `, `❯ ` | output after a command | Synthetic. Bare prompts are dropped. |

Copilot, Cursor and Amp mark no roles (unverified layouts): everything stays agent text.
