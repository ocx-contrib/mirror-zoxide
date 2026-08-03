# NOTICE

This repository packages and redistributes upstream software published by the
[zoxide](https://github.com/ajeetdsouza/zoxide) project. The Apache-2.0 license
in [`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — each package's redistributed bytes
carry their own license, recorded below.

Each package's logo in this repository is an **original mark authored here**,
not an upstream one: zoxide publishes no logo of its own. No upstream trademark
is reproduced, and no endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `zoxide` | `ghcr.io/ocx-contrib/zoxide/zoxide` | `MIT` |

---

## `zoxide`

Upstream: <https://github.com/ajeetdsouza/zoxide>
Published to `ghcr.io/ocx-contrib/zoxide/zoxide`.

| Component | SPDX | Holder |
|---|---|---|
| zoxide (`zoxide`) | **MIT** | Copyright 2020 Ajeet D'Souza |

The MIT License grants redistribution of the software in source and binary form
without restriction, on the single condition that the copyright notice and the
permission notice accompany all copies or substantial portions of the software.
That condition is met by construction: upstream's `LICENSE` file ships **inside
every mirrored archive**, at the archive root beside the binary, and is
republished unmodified as part of the bundle content.

The published binaries statically link third-party Rust crates under permissive
licenses, enumerated in the `Cargo.lock` of the tagged upstream source for each
mirrored version.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
