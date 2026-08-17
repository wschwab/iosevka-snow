# Iosevka Snow

Pinned built bytes of **Iosevka Snow**, the terminal and interface face of
[Snow Storm Station](https://github.com/wschwab/snow-station).

Iosevka Snow is a custom Iosevka build: `term` spacing, `sans` serifs, regular
and bold with italic and oblique, family name `Iosevka Snow`.

## Why this repository exists

Snow Storm Station's specification requires the font to be installed from fixed,
hash-pinned bytes rather than rebuilt during a system switch. Building Iosevka
from source takes many CPU-minutes, and a routine `nixpkgs` bump would otherwise
drag that rebuild into an activation.

Building it here once and publishing the TTFs as a checksummed release asset
gives the station a stable, verifiable artifact:

- the bytes never change unless a release is cut deliberately;
- consumers pin a hash, so a substituted artifact fails the build;
- the 55 MB of TTFs live in release storage, not in any repository's history.

`default.nix` is the recipe those bytes came from, kept here so the artifact is
reproducible from source rather than being an opaque blob.

## Consuming a release

```nix
iosevkaSnow = pkgs.fetchzip {
  url = "https://github.com/wschwab/iosevka-snow/releases/download/v34.4.0/iosevka-snow-34.4.0-ttf.tar.gz";
  hash = "sha256-...";
  stripRoot = false;
};
```

The unpacked tree is `share/fonts/truetype/*.ttf`, matching the layout of the
source-built derivation, so consumers need no path changes when switching
between them.

Note that a private repository's release assets require authentication, which a
Nix build sandbox does not have. Either this repository is public, or consumers
must pin the tag over authenticated SSH instead of fetching the asset.

## Cutting a release

`scripts/make-release.sh` builds the fonts from `default.nix` and packs them into
a deterministic tarball: entries sorted, timestamps zeroed, ownership zeroed, and
gzip's own timestamp suppressed. Re-running it on the same inputs produces a
byte-identical archive, so the published hash is reproducible rather than
incidental.

```sh
scripts/make-release.sh 34.4.0            # writes dist/ and prints hashes
gh release create v34.4.0 dist/*.tar.gz   # publish
```

## License

Iosevka is © 2015-2026 Renzhi Li (Belleve Invis) and licensed under the SIL Open
Font License 1.1, reproduced in `LICENSE-Iosevka-OFL-1.1.md`. Upstream declares
no Reserved Font Name, so this renamed custom build may be redistributed under
the same license, which accompanies both this repository and every release
asset.

`default.nix` and the packaging scripts derive from the `iosevka` derivation in
nixpkgs (MIT).
