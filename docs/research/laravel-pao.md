# `laravel/pao` — impact on CI

Research for [#9](https://github.com/marcth-labs/proving-ground/issues/9). Date: 2026-10-24.
Version examined: **v1.1.5** (latest release, 2026-09-07) plus branch `1.x` @ `fbd91ab`.

**Method caveat:** no PHP or Composer was available when this was written, so **nothing below the
addendum was executed**. Every "VERIFIED" claim in the body is read from primary source (the
package's own code and test suite, PHPUnit's source, Collision's source, Infection's source), not
from a live run.

> **[Addendum: verified by execution](#addendum-verified-by-execution-2026-10-26)** at the end.
> The smoke test this note asked for was run against the real stack while making commit zero
> ([#8](https://github.com/marcth-labs/proving-ground/issues/8)). The body's conclusions hold, and
> execution turned up two traps a source read had missed.

---

## Bottom line for CI

- **Keep it.** In a normal CI job `laravel/pao` is a *complete no-op*. It activates only when it
  detects an **AI agent** via specific env vars — it does **not** look at `CI`, and a plain GitHub
  Actions runner has none of the agent vars, so `src/Autoload.php` returns before touching anything.
  No effect on exit codes, JUnit XML, or coverage files. (VERIFIED)
- **But set `PAO_DISABLE=1` at the workflow/job `env:` level anyway.** One line, zero risk, and it
  closes the real hole: some CI *is* agent-shaped. `COPILOT_AGENT_SESSION_ID` + `GITHUB_ACTIONS`
  both present → detected as Copilot; `CODEX_CI` is in the detection list by name; and any job that
  runs Claude Code / Cursor / Codex in CI exports `CLAUDECODE` et al. In those jobs PAO *does* fire
  and the test log changes shape. (VERIFIED)
- **Mandatory if Infection is added: `PAO_DISABLE=1` on that step.** Infection decides whether each
  mutant escaped by regex-matching PHPUnit's **stdout** (`/OK\s\(/` etc.). PAO suppresses that text,
  so `testsPass()` is always false → **every mutant is scored KILLED → MSI silently reports ~100 %**.
  A wrong green number, not a crash. (VERIFIED — see §5)
- **Prefer file-based artefacts over stdout scraping regardless.** `--log-junit <file>`,
  `--log-teamcity <file>`, `--coverage-clover`, `--coverage-cobertura` and `--coverage-php` are all
  immune to PAO. `--coverage-text` to stdout and GitHub Actions problem matchers keyed on PHPUnit's
  prose output are not. (VERIFIED)
- **`php artisan test --coverage --min=N` is safe either way** — Collision enforces the threshold in
  the *parent* process by reading the `--coverage-php` file, never by parsing the child's stdout.
  (VERIFIED)

---

## 1. What the package is

| | |
|---|---|
| Package | `laravel/pao` — "Agent-optimized output for PHP testing tools" |
| Repo | <https://github.com/laravel/pao> (default branch `1.x`, 728 stars, MIT, author Taylor Otwell) |
| Latest | `v1.1.5`, 2026-09-07 |
| Requires | `php ^8.3`, `laravel/agent-detector ^2.0.2` |
| Conflicts | `laravel/framework <12`, `nunomaduro/collision <8.9.3`, `phpunit <12.5.23 \|\| >=13.0.0 <13.1.7 \|\| >=14`, `pest <4.6.3 \|\| >=6` |

**In the Laravel 13 skeleton it is `require-dev`.** VERIFIED from
`https://raw.githubusercontent.com/laravel/laravel/13.x/composer.json`:

```json
"require-dev": {
    "fakerphp/faker": "^1.23",
    "laravel/pail": "^1.2.5",
    "laravel/pao": "^1.0.6",
    "laravel/pint": "^1.27",
    "mockery/mockery": "^1.6",
    "nunomaduro/collision": "^8.6",
    "phpunit/phpunit": "^12.5.12"
}
```

It hooks in through **two** independent mechanisms (VERIFIED, `composer.json`):

1. `autoload.files` → `src/Autoload.php`, which therefore runs in **every** PHP process that loads
   the Composer autoloader, including ones you did not think of.
2. Laravel package auto-discovery → `Laravel\Pao\Laravel\ServiceProvider`, which rebinds Artisan's
   `OutputStyle` to strip ANSI/box-drawing from *all* Artisan command output.

`src/Autoload.php` picks a driver from `basename($argv[0])` — `paratest`, `pest`, `phpstan`,
`phpstan.phar`, `phpunit`, `rector`. Any other binary → no driver → no interception.

### The activation gate (the single most important fact)

`src/Autoload.php`, in order:

```php
if (filter_var($_SERVER['PAO_DISABLE'] ?? false, FILTER_VALIDATE_BOOLEAN)) { return; }

$agent = AgentDetector::detect();

if (! $agent->isAgent && ! filter_var($_SERVER['PAO_FORCE'] ?? false, FILTER_VALIDATE_BOOLEAN)) { return; }

if (array_intersect($argv, ['--version', '-V', '--help', '-h', 'worker'])) { return; }
```

`AgentDetector::detect()` (VERIFIED, `laravel/agent-detector` `src/AgentDetector.php`) checks, in
order: the `AI_AGENT` var; a fixed list of ~35 agent env vars (`CLAUDECODE`, `CLAUDE_CODE`,
`CURSOR_AGENT`, `GEMINI_CLI`, `CODEX_SANDBOX`, `CODEX_CI`, `CODEX_THREAD_ID`, `COPILOT_MODEL`,
`COPILOT_CLI`, `OPENCODE`, `AMP_CURRENT_THREAD_ID`, `REPL_ID`, `WINDSURF_CASCADE_TERMINAL`, …); three
compound rules (Zed, Kiro, and **`COPILOT_AGENT_SESSION_ID` + `GITHUB_ACTIONS` → Copilot**, plus
Jules via `HOME=/home/jules`); and finally `file_exists('/opt/.devin')`.

**There is no `CI` check anywhere.** CI is neither an enable nor a disable signal.

---

## 2. How it changes `php artisan test` / PHPUnit output

`php artisan test` is Collision's command (`nunomaduro/collision`
`src/Adapters/Laravel/Commands/TestCommand.php`), which spawns
`[PHP_BINARY, 'vendor/phpunit/phpunit/phpunit']` as a child process — `basename` is `phpunit`, so
PAO's PHPUnit driver matches in the child. (VERIFIED)

### Output replacement

`src/Drivers/Phpunit/Starter.php` (VERIFIED):

- appends `--no-output` to `$_SERVER['argv']` before PHPUnit parses it;
- registers PHPUnit event subscribers to capture the `TestResult` object directly (it reads
  PHPUnit's result facade — it does **not** scrape text);
- a shutdown function writes **one line of compact JSON** to `STDOUT`:

```json
{"tool":"phpunit","result":"passed","tests":1002,"passed":1002,"assertions":1002,"duration_ms":321}
```

On failure the JSON carries `failed`, `failures[]` (test, file, line, message, trace — vendor frames
stripped, capped at 5), `errors`, `skipped`, `deprecations`, `warnings`, `risky`, etc.

`src/Autoload.php` also does `unset($_SERVER['COLLISION_PRINTER'])` and sets
`$_SERVER['PEST_PARALLEL_NO_OUTPUT'] = '1'`, disabling Collision's pretty printer in the child.

**Drivers differ in how aggressive they are** — worth knowing:

- **PHPUnit driver**: relies *only* on `--no-output`. It calls `registerNullFilter()`, but a grep of
  the whole `src/` tree shows the `agent_output_null` filter is registered and **never appended** to
  any stream. So stdout itself is not intercepted. (VERIFIED)
- **Pest / Paratest / PHPStan drivers**: additionally call `silenceStdout()`, which appends a
  `CaptureFilter` to `STDOUT` that swallows *everything* written there and re-emits it inside the
  JSON `raw` array. Far more invasive. (VERIFIED)

### Exit codes

**Unchanged.** Nothing in `src/` sets an exit code, calls `exit()`, or touches
`$process->setExitCode`. The shutdown function only does `fwrite(STDOUT, json_encode(...))`.
(VERIFIED by reading all 21 source files.) PAO's own tests assert this both ways —
`tests/Drivers/EdgeCasesTest.php:35` expects `0`, `tests/Drivers/PestTest.php:82` expects non-zero.

> **Open caveat:** PR [#63](https://github.com/laravel/pao/pull/63) — "Fixes empty output and exit
> code 255 when a test run dies with a fatal error" — is **closed and NOT merged**, and no release
> after it mentions the fix. So under Pest with `display_errors=0`, a fatal error mid-run may still
> produce empty output and exit 255 instead of 1/2. VERIFIED that the PR is unmerged; INFERRED that
> the underlying bug is still present.

### `--coverage --min=N`

**Still enforced correctly.** VERIFIED from Collision `TestCommand.php`:

```php
// commonArguments(): coverage goes to a FILE, not stdout
if ($this->option('coverage')) {
    $arguments[] = '--coverage-php';
    $arguments[] = Coverage::getPath();
}
// ...
if ($exitCode === 0 && $this->option('coverage')) {
    $coverage = Coverage::report($this->output, $hideFullCoverage);
    $exitCode = (int) ($coverage < $this->option('min'));
}
```

`Coverage::report()` does `require $reportPath` on the `--coverage-php` dump. So the threshold is
computed in the **parent** Artisan process from a **file**, and PAO's stdout suppression in the
child is irrelevant to it.

Cross-checked against PHPUnit's `src/Runner/CodeCoverage.php`: `hasCoveragePhp()`,
`hasCoverageClover()` and `hasCoverageCobertura()` generate their reports with **no `noOutput`
gate**. The *only* coverage output gated by `noOutput` is `--coverage-text` when its target is
`php://stdout`:

```php
if ($configuration->coverageText() === 'php://stdout') {
    if (!$configuration->noOutput() && !$configuration->debug()) { $printer->print(...); }
}
```

The per-file coverage table itself is printed by the parent, through `PaoOutputStyle`, so it still
appears — just with ANSI colours and box-drawing stripped and runs of spaces collapsed.

---

## 3. Disabling it / CI auto-detection

| Lever | Effect | Status |
|---|---|---|
| `PAO_DISABLE` (truthy) | **Full kill switch.** First check in *both* `Autoload.php` and the Laravel `ServiceProvider`. Package becomes inert. | VERIFIED in source; covered by `tests/Laravel/ServiceProviderTest.php:28`. **Undocumented** — not in the README. |
| `PAO_FORCE` (truthy) | Activate without agent detection. | VERIFIED; documented in README. |
| `composer remove laravel/pao` | Clean — nothing else in the skeleton depends on it. | VERIFIED |
| `--no-pao` CLI flag | **Does not exist.** | VERIFIED |
| Config file | **None.** README: "Zero config". | VERIFIED |
| `PAO_SKIP_TOOLS` | **Does not exist.** A third-party FAQ site claims it does; `grep -rn "PAO_"` over the full cloned repo returns only `PAO_DISABLE` and `PAO_FORCE`. Treat the claim as false. | VERIFIED |

Truthiness is `filter_var(..., FILTER_VALIDATE_BOOLEAN)`, so `1`, `true`, `on`, `yes` all work.

Both vars are read from **`$_SERVER`**, not `getenv()`. Under the CLI SAPI `$_SERVER` is populated
from the process environment, so an ordinary exported env var or a GitHub Actions `env:` block
reaches it. PAO's own test suite relies on exactly this path — it passes these vars through
Symfony `Process(env: ...)` to a child and asserts the behaviour changes
(`tests/Drivers/PestTest.php:160-168`). Symfony Process merges the given env with the inherited one,
so a job-level `env:` also reaches the `phpunit` child that Collision spawns.

PAO additionally self-skips when `$argv` contains `--version`, `-V`, `--help`, `-h`, or `worker`
(the last protects Paratest/Pest parallel workers).

### Does it detect CI?

**No.** There is no `CI`, `GITHUB_ACTIONS`-alone, `GITLAB_CI`, `BUILDKITE` … check. Consequences:

- **Plain CI job** (checkout → composer install → `php artisan test`): no agent var present →
  `isAgent` false → PAO returns immediately. Output is byte-for-byte stock PHPUnit. PAO's own test
  asserts this: *"works correctly when no agent is detected and does not affect output"*, expecting
  the output to contain `OK` and **not** contain `"result"` (`tests/Drivers/EdgeCasesTest.php:44`).
- **Agent-shaped CI job**: PAO fires. Specifically `COPILOT_AGENT_SESSION_ID` + `GITHUB_ACTIONS`,
  or `CODEX_CI`, or a workflow step that runs Claude Code (`CLAUDECODE`). This is the
  reproducibility trap — the same workflow produces differently-shaped logs depending on who
  triggered it.

---

## 4. Interference with mechanical consumers of PHPUnit output

| Consumer | Verdict | Evidence |
|---|---|---|
| `--log-junit <file>` | **Works.** | Double-verified. (a) PHPUnit `src/TextUI/Application.php:722` builds `JunitXmlLogger` from `hasLogfileJunit()` with no `noOutput` gate. (b) PAO's own test `tests/Drivers/EdgeCasesTest.php:30` — *"preserves user junit file when user also passes log-junit"* — runs `phpunit --log-junit <f>` **with PAO active** and asserts exit code 0, file exists, and parses as valid XML. |
| `--log-teamcity <file>` | **Works.** | `Application.php:758` → `new TeamCityLogger(DefaultPrinter::from($file), …)`, no `noOutput` gate. VERIFIED |
| `--teamcity` (service messages on stdout) | **Survives under the PHPUnit driver**, but mixed with PAO's JSON line. **Swallowed under Pest/Paratest.** | `Output/Facade.php::init()` does `if ($configuration->outputIsTeamCity()) { new TeamCityLogger(DefaultPrinter::standardOutput(), …); }`, and `createPrinter()` sets `$printerNeeded = true` for TeamCity — both bypass `noOutput`. VERIFIED for the mechanism; whether a given TeamCity parser tolerates the extra JSON line is INFERRED (most are line-oriented and skip non-message lines). Under Pest/Paratest the `CaptureFilter` on `STDOUT` eats it — VERIFIED. |
| Clover / Cobertura / `--coverage-php` | **Work.** | `src/Runner/CodeCoverage.php` — no `noOutput` gate on any of the three. VERIFIED |
| `--coverage-text` to stdout | **Suppressed.** | Explicitly gated by `!$configuration->noOutput()`. VERIFIED |
| GitHub Actions problem matchers / annotations | **Broken while PAO is active.** | Matchers regex the workflow's stdout log. With `--no-output` the human-readable PHPUnit failure text never appears, so a matcher keyed to it matches nothing. INFERRED — follows directly from `--no-output`, but no specific matcher was tested. Moot in a normal CI run, where PAO is inert. |
| Anything grepping `OK (N tests)` / `FAILURES!` | **Broken while PAO is active.** | Same cause. VERIFIED |

PAO's `OutputCleaner` (applied to the parent Artisan output path) also collapses `[ \t]+` → one
space, strips control characters and box-drawing glyphs, and rewrites `...` → `..`. Harmless for
compact JSON, but it will mangle any whitespace-significant text that flows through Artisan's
output.

---

## 5. Infection (mutation testing)

Infection invokes `$this->testFrameworkExecutable` — normally `vendor/bin/phpunit`, `basename`
`phpunit` — so **PAO's PHPUnit driver does engage in Infection's child processes** whenever an agent
env var is present. (VERIFIED, `Infection\TestFramework\PhpUnit\Adapter\PhpUnitAdapter`)

**Initial test run: fine.** `getInitialTestRunCommandLine()` adds `--coverage-xml=<dir>` and
`--log-junit=<file>` — both file-based and unaffected by `--no-output`. Success is judged by
`if (!$initialTestSuiteProcess->isSuccessful())`, i.e. the **exit code**, which PAO preserves.
(VERIFIED)

> Minor: `getMemoryUsed($output)` parses stdout for PHPUnit's memory line and will return `-1`, so
> Infection's `MemoryLimiter` can't auto-derive a limit. INFERRED, low impact.

**Mutant runs: broken, and silently.** VERIFIED from
`src/Mutant/TestFrameworkMutantExecutionResultFactory.php`:

```php
if ($process->getExitCode() === 0 && $this->testFrameworkAdapter->testsPass($output)) {
    return DetectionStatus::ESCAPED;
}
// ...
return DetectionStatus::KILLED_BY_TESTS;
```

and `PhpUnitAdapter::testsPass(string $output)` is pure text-scraping:

```php
if (preg_match('/failures!/i', $output) === 1) { return false; }
if (preg_match('/errors!/i',   $output) === 1) { return false; }
$isOk             = preg_match('/OK\s\(/', $output) === 1;
$isOkWithInfo     = preg_match('/OK\s?,/', $output) === 1;
$isWarning        = preg_match('/warnings!/i', $output) === 1;
$isNoTestsExecuted= preg_match('/No tests executed!/i', $output) === 1;
return $isOk || $isOkWithInfo || $isWarning || $isNoTestsExecuted;
```

With PAO active, PHPUnit runs under `--no-output`, so **none of those strings is ever emitted** — the
only stdout is PAO's JSON line. `testsPass()` therefore returns `false` for every mutant, the
`ESCAPED` branch is never taken, and every mutant falls through to `KILLED_BY_TESTS`.

**Result: MSI reports ~100 % no matter how bad the test suite is.** This is the worst failure mode
in this document — a confidently wrong green metric rather than a visible error.

Mitigation: `PAO_DISABLE=1` on the Infection step, or don't install the package. Note again that
this only bites when an agent env var is present; a plain CI job is unaffected because PAO never
activates.

---

## Could not establish

- **No empirical verification.** No PHP/Composer in this environment; all findings are source reads.
  Worth a single smoke test on a real Laravel 13 app once one exists: run
  `CLAUDECODE=1 php artisan test --coverage --min=50 --log-junit=/tmp/j.xml` and confirm exit code,
  JUnit file and `--min` enforcement behave as described.
- Whether any specific GitHub Actions PHPUnit problem matcher degrades gracefully or errors.
- Whether the PR #63 fatal-error/exit-255 behaviour is still reproducible on v1.1.5 (the PR is
  unmerged; no later release claims the fix).

## Sources

All primary unless noted.

- [laravel/pao on GitHub](https://github.com/laravel/pao) — `1.x` @ `fbd91ab`: `src/Autoload.php`,
  `src/Execution.php`, `src/Drivers/**`, `src/Laravel/**`, `src/OutputCleaner.php`,
  `src/UserFilters/**`, `README.md`, `tests/Drivers/EdgeCasesTest.php`, `tests/Pest.php`
- [laravel/pao on Packagist](https://packagist.org/packages/laravel/pao) — version/metadata
- [laravel/laravel 13.x `composer.json`](https://raw.githubusercontent.com/laravel/laravel/13.x/composer.json)
- [laravel/agent-detector](https://github.com/laravel/agent-detector) — `src/AgentDetector.php`, `src/KnownAgent.php`
- [sebastianbergmann/phpunit](https://github.com/sebastianbergmann/phpunit) — `src/TextUI/Application.php`, `src/TextUI/Output/Facade.php`, `src/Runner/CodeCoverage.php`
- [nunomaduro/collision](https://github.com/nunomaduro/collision) — `v8.x` `src/Adapters/Laravel/Commands/TestCommand.php`, `src/Coverage.php`
- [infection/infection](https://github.com/infection/infection) — `master` `src/TestFramework/PhpUnit/Adapter/PhpUnitAdapter.php`, `src/Mutant/TestFrameworkMutantExecutionResultFactory.php`, `src/Engine.php`
- [laravel/pao PR #63](https://github.com/laravel/pao/pull/63) — closed, unmerged
- [Introducing Laravel PAO (Laravel blog)](https://laravel.com/blog/introducing-laravel-pao-cleaner-output-for-ai-agents) — secondary, announcement only
- Laravel docs 13.x: **no** `pao` page exists (checked the docs repo file list and code search)

---

## Addendum: verified by execution, 2026-10-26

Run against this repository's `dev` container at commit zero — PHP 8.5.12, Laravel 13.38.0,
PHPUnit 12.5.40, `laravel/pao` v1.1.5, `laravel/agent-detector` installed — with a single
throwaway passing unit test, discarded afterwards. The container carries no agent environment
variable of its own, which is what makes the matrix below meaningful.

### The matrix

| `PAO_DISABLE` | Agent variable | stdout | Contains `OK (` |
|---|---|---|---|
| unset | none | stock PHPUnit, `OK (1 test, 1 assertion)` | yes |
| unset | `CLAUDECODE=1` | one JSON line | **no** |
| unset | `CLAUDECODE=` (empty) | one JSON line | **no** |
| `0` | `CLAUDECODE=1` | one JSON line | **no** |
| `1` | `CLAUDECODE=1` | stock PHPUnit, `OK (1 test, 1 assertion)` | yes |

Both claims the note was written to settle are confirmed. With no agent variable present PAO is a
complete no-op and output is stock; `PAO_DISABLE=1` suppresses it even with an agent variable set,
despite being undocumented in the package README. And the mechanism behind the Infection hazard in
§5 is confirmed directly: when PAO is active the string `OK (` never appears on stdout, which is
the exact string `PhpUnitAdapter::testsPass()` scrapes for.

The note's suggested command was run verbatim —
`CLAUDECODE=1 php artisan test --coverage --min=50 --log-junit=/tmp/j.xml` — and behaved as §2
predicted: exit code **1**, a complete JUnit file on disk, and Collision's `--min` enforcement
reporting the real coverage figure. File-based artefacts are untouched by PAO; only stdout changes
shape.

### Two traps a source read missed

**An agent variable set to the empty string still triggers detection.** `AgentDetector` tests each
known variable with `getenv($var) === false`, which is presence, not truthiness. So
`CLAUDECODE=` activates PAO exactly as `CLAUDECODE=1` does, and the obvious way to neutralise an
inherited agent variable — setting it empty — does the opposite of what it looks like.

**`PAO_DISABLE` is boolean-parsed, so `PAO_DISABLE=0` does not disable it.** `Autoload.php` reads
`filter_var($_SERVER['PAO_DISABLE'] ?? false, FILTER_VALIDATE_BOOLEAN)`, so only `1`, `true`, `yes`
and `on` disable the package; `0`, `false` and the empty string leave it active. Note also that it
is read from `$_SERVER` rather than through `getenv()`, so it depends on PHP's `variables_order`
containing `S` — the CLI default, and true here, but a configuration away from silently failing
open.

Both traps have the same shape as the hazard the note was written about: the safe-looking value
leaves the dangerous behaviour on.

### Where this landed

`PAO_DISABLE=1` is set in three places rather than one, because each covers a different entry
point: the `app` service's `environment:` in `compose.yaml`, the `EXEC` variable in the `Makefile`
so every target that shells into the container carries it, and an imperative rule in
[`AGENTS.md`](../../AGENTS.md) for anything run by hand.

### Still not established

- Infection itself has not been run — it arrives in iteration 3. What is verified is the input to
  its failure mode (no `OK (` on stdout when PAO is active), not the resulting MSI figure. The
  claim that every mutant then scores as killed remains a source read of Infection's own code.
- The PR #63 fatal-error/exit-255 behaviour was not reproduced; no test here provoked it.
- Whether a GitHub Actions PHPUnit problem matcher degrades gracefully under PAO.
