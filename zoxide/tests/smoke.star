# zoxide/tests/smoke.star — stable across upstream zoxide releases.
# Asserts the contract (exit code, version shape, a real database round-trip),
# never help/version prose. See ocx.mirror testing-practices.md.
#
# zoxide is a `cd` replacement whose headline behaviour is SHELL INTEGRATION
# (`eval "$(zoxide init bash)"` installs a `z` function). That is not testable
# hermetically — it needs an interactive shell of a specific flavour and a
# populated user history — so it is deliberately NOT what this asserts. The
# stable, shell-free contract underneath it is the frecency database: `add`
# records a directory, `query` resolves a keyword back to a full path. That is
# what runs here.
#
# `_ZO_DATA_DIR` redirects the database into the test scratch sandbox, so the
# run never reads or writes a real user database — on a developer laptop or a
# CI runner alike. `ocx.run(env=…)` is an OVERLAY on the composed bundle env
# (env_clear + base + overlay), so PATH and the rest survive.

ZOXIDE = "zoxide.exe" if ocx.target_platform.os == ocx.os.Windows else "zoxide"

# Every zoxide invocation below shares one scratch-local database.
ZO_ENV = {"_ZO_DATA_DIR": ocx.scratch_root}

# The directory the database round-trip is built on. The QUERY KEYWORD is a
# strict SUBSTRING of this name, and the assertion is on the FULL name — so a
# hypothetical zoxide that merely echoed its argument back would fail, and only
# a real database lookup can pass.
DIR_NAME = "ocx-smoke-zoxide-db"
QUERY_KEYWORD = "smoke-zoxide"

# ── Tier 1 + 2: liveness on the composed PATH + version SHAPE ───────────────
# The digits are the contract; the vendor banner around them is not.
r_version = ocx.run(ZOXIDE, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ── Tier 3: functional database round-trip on hermetic input ────────────────
# `add .` with a relative cwd avoids composing an absolute path in Starlark,
# which would have to pick a path separator and get Windows wrong. zoxide
# canonicalises "." against the child's cwd itself.
ocx.mkdir(DIR_NAME)
r_add = ocx.run(ZOXIDE, "add", ".", cwd=DIR_NAME, env=ZO_ENV)
expect.ok(r_add)

# The database landed in the scratch sandbox, not in a real user data dir.
# This is the ONLY assertion that proves the run is hermetic: if _ZO_DATA_DIR
# were ignored, `add` and `query` would both fall through to the host's real
# database and the round-trip below would still pass — while polluting it.
expect.true(ocx.exists("db.zo"))

# The round-trip itself. `query <keyword>` (NOT `--list`) is used on purpose:
# it exits 1 with "no match found" on an empty result, whereas `query --list`
# exits 0 with empty stdout — a filter whose empty answer is a success is not
# something to assert an exit code against.
r_query = ocx.run(ZOXIDE, "query", QUERY_KEYWORD, env=ZO_ENV)
expect.ok(r_query)
expect.contains(r_query.stdout, DIR_NAME)

# Negative control — states what would go red. A keyword never added must NOT
# resolve, which is what distinguishes a working database from one that returns
# whatever it is handed. Measured on 0.9.8 and 0.10.0: exit 1, "no match found".
r_miss = ocx.run(ZOXIDE, "query", "ocx-token-never-added", env=ZO_ENV)
expect.eq(r_miss.exit_code, 1)
