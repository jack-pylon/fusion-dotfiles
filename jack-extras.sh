#!/usr/bin/env bash
# The fusion-claude-jack extras. Runs on every fusion box start, but only on
# boxes that have ~/.config/jack-extras/enabled. Each step is independent.
[ -f "$HOME/.config/jack-extras/enabled" ] || exit 0

# Fable 5 as Claude Code's default model. The template rewrites this file on
# every start just before this runs, so set the key again each time.
settings="$HOME/.claude/settings.json"
if [ -f "$settings" ] && command -v jq >/dev/null 2>&1; then
  tmp="$(jq '.model = "claude-fable-5"' "$settings")" && printf '%s\n' "$tmp" > "$settings"
fi

# LINEAR_API_KEY in every new interactive shell, minted from your Coder Linear
# login each time (coder-mcp-token also works inside the Claude session).
mkdir -p "$HOME/.bashrc.d"
grep -qsF '.bashrc.d' "$HOME/.bashrc" \
  || printf '%s\n' 'for f in ~/.bashrc.d/*; do [ -r "$f" ] && . "$f"; done' >> "$HOME/.bashrc"
cat > "$HOME/.bashrc.d/linear" <<'LINEAR'
if LINEAR_API_KEY="$("$HOME/.local/bin/coder-mcp-token" linear 2>/dev/null)" && [ -n "$LINEAR_API_KEY" ]; then
  export LINEAR_API_KEY
else
  unset LINEAR_API_KEY
fi
LINEAR

# A persistent tmux session "main" in ~/fusion. CODER_DISPATCH=1 keeps its
# shells out of the Claude session; env -u keeps the box's agent token out of
# every pane.
if command -v tmux >/dev/null 2>&1 && ! tmux has-session -t main 2>/dev/null; then
  env -u CODER_AGENT_TOKEN -u CODER_AGENT_URL \
    tmux new-session -d -s main -e CODER_DISPATCH=1 -c "$HOME/fusion"
fi
exit 0
