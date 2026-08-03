# mirror-zoxide

OCX mirror for [zoxide](https://github.com/ajeetdsouza/zoxide), a smarter `cd`
command. One repository, one spec directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [zoxide](https://github.com/ajeetdsouza/zoxide) | [`zoxide/mirror.yml`](zoxide/mirror.yml) | `ghcr.io/ocx-contrib/zoxide/zoxide` | [`ocx.sh/zoxide/zoxide`](https://index.ocx.sh/zoxide/zoxide) | `MIT` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

`ajeetdsouza` is a personal handle rather than a vendor, so the tool names
itself: the package is `zoxide/zoxide`.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
zoxide/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. Restate a block in full or
not at all. `zoxide/mirror.yml` does not restate it at all, which removes the
trap structurally.

## Platforms

`zoxide` publishes six platform entries: both Linux arches, both macOS arches
and both Windows arches. Upstream ships **only** `*-unknown-linux-musl` assets
for Linux — no `-gnu` build exists for any arch — but a musl target *triple* is
not a musl *requirement*. Both declared Linux binaries were byte-measured at
**both ends** of the mirrored range, 0.9.8 and 0.10.0, and all four are fully
**static**: no `PT_INTERP`, no `DT_NEEDED`, musl linked *in* rather than linked
*against*. `os.features` states what an artifact requires *of the host*, so
both Linux keys are **bare**: tagging them `+libc.musl` would be a false
requirement that hid the package from every glibc host it in fact runs on. The
`alpine:3.20` container leg on both arches in `mirror-base.yml` is what turns
that claim into evidence; the measurement transcript is recorded above the
`assets:` block in `zoxide/mirror.yml`.

Upstream also publishes `i686` and 32-bit `arm`/`armv7` Linux builds, a
`riscv64gc` build (new in 0.10.0), Android targets and `.deb` sidecars. None of
those maps to an OCX platform key, so none is mirrored — the anchored `^…$`
asset regexes are what keep them out. Resolution was verified **both ways on
every in-range release** (0.9.8, 0.9.9, 0.10.0): each of the six patterns
matches exactly one asset, every time. A pattern matching zero would be
silently skipped rather than reported, so this check is not optional.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `zoxide/mirror.yml` | hand | yes — see below |
| `zoxide/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `zoxide/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec zoxide/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## The binaries claim

`zoxide/metadata.json` declares `binaries: ["zoxide"]` by hand, and
`zoxide/mirror.yml` sets `bin_scan: "off"` — forced, not preferred. The scan
only inspects an interface-visible `${installPath}/<dir>` PATH entry, and
zoxide's archives are **flat**: `zoxide(.exe)`, `CHANGELOG.md`, `LICENSE`,
`README.md`, `man/` and `completions/` all sit at the archive root with no
subdirectory to point one at. With nothing to inspect the scan would pass green
whatever the archive contained, so `auto` and `verify` both fail spec load at
exit 65 rather than offer a hollow check. The hand-written list is what the
error message itself directs, and it is short and stable — `zoxide` is the only
mode-0755 entry; the rest is 0644 data.

## The smoke test

zoxide's headline behaviour is **shell integration** — `eval "$(zoxide init
bash)"` installs the interactive `z` function — and that is not testable
hermetically: it needs an interactive shell of a specific flavour and a
populated history. `zoxide/tests/smoke.star` therefore asserts the shell-free
contract underneath it: the frecency database round-trip. It creates a
directory in the test scratch sandbox, `zoxide add`s it, and asserts that
`zoxide query <fragment>` resolves that fragment back to the full directory
name — with a keyword that is a strict *substring* of the name asserted on, so
a tool that merely echoed its argument could not pass. A negative control
asserts that a keyword never added exits 1.

`_ZO_DATA_DIR` is overlaid onto the run env to redirect the database into the
scratch sandbox, and the test asserts the database file actually landed there.
That assertion is the only thing proving the run is hermetic: without it, an
ignored `_ZO_DATA_DIR` would send both `add` and `query` to the host's real
database and the round-trip would still pass — while polluting it.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md). The
logo is an original mark authored here — zoxide publishes none.
