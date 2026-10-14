# Echoproof GitHub Action

Run [Echoproof](https://github.com/est57/echoproof) in CI: replay recorded traffic against the base build and the PR build, and fail the job when behavior changes in a way the PR did not intend.

## Usage

```yaml
- uses: est57/echoproof-action@v1
  with:
    snapshot: traffic.jsonl
    base: http://127.0.0.1:8001
    target: http://127.0.0.1:8002
```

The action installs the release binary for the runner (Linux or macOS, x64 or arm64), checks its SHA-256, runs `echoproof check`, and writes the Markdown report to the job summary.

Start both builds in earlier steps. For services that write data, pass a `reset` command and the endpoints allowed to write:

```yaml
- uses: est57/echoproof-action@v1
  with:
    snapshot: traffic.jsonl
    base: http://127.0.0.1:8001
    target: http://127.0.0.1:8002
    reset: ./scripts/reset-test-db.sh
    noise-runs: 1
    allow-writes: |
      POST /orders
      POST /shifts/*
```

### Judge changes against the intent

With an intent, Claude labels each group of changes as intended or a regression, so the change you meant passes and the one you did not still fails:

```yaml
- run: git diff origin/${{ github.base_ref }}...HEAD > change.diff
- uses: est57/echoproof-action@v1
  with:
    snapshot: traffic.jsonl
    base: http://127.0.0.1:8001
    target: http://127.0.0.1:8002
    intent: ${{ github.event.pull_request.title }}
    code-diff: change.diff
    anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
```

Without `intent` or `intent-file`, nothing is sent to any model.

## Inputs

| Input | Description |
|---|---|
| `snapshot` | Recorded traffic (JSONL). Required. |
| `target` | URL of the PR build. Required. |
| `base` | URL of the base build. Without it, the recorded responses are the baseline. |
| `reset` | Shell command that restores state before every replay pass. |
| `noise-runs` | Extra base replays used to learn noisy fields. |
| `allow-writes` | Endpoints whose write requests may be replayed, one per line. |
| `expect` | Endpoints expected to change, one per line. |
| `intent` / `intent-file` | What the change is meant to do. |
| `code-diff` | Code diff given to the judge. |
| `config` | Path to `echoproof.toml` (default `echoproof.toml`). |
| `anthropic-api-key` | Needed only with an intent. |
| `fail-on-regression` | Fail the step on a regression (default `true`). |
| `version` | Echoproof version, e.g. `0.1.0` (default `latest`). |

## Outputs

| Output | Description |
|---|---|
| `verdict` | `pass`, `regression` or `error`. |
| `report` | Path to the Markdown report. |

## License

MIT or Apache-2.0, at your option.
