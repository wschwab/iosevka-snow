{ buildNpmPackage, iosevka, go-toml, ttfautohint-nox }:

# Iosevka “Snow” — a pinned custom build of Iosevka with a clean package name.
#
# The stock nixpkgs `iosevka` derivation names its package "Iosevka${family}",
# which double-prefixes when the family is "Iosevka Snow".  This derivation
# reuses Iosevka's pinned source and npm dependencies but names the package
# and build plan "Iosevka-Snow" consistently, while the font family inside the
# TTFs remains "Iosevka Snow".
#
# License: Iosevka is SIL OFL 1.1; the meta is inherited from nixpkgs.

buildNpmPackage {
  pname = "Iosevka-Snow";
  version = iosevka.version;
  inherit (iosevka) src npmDeps;

  nativeBuildInputs = [
    go-toml
    ttfautohint-nox
  ];

  strictDeps = true;

  # Same private build plan as the stock package, but keyed by the clean
  # package name so `--targets ttf::"Iosevka-Snow"` resolves.
  buildPlan = builtins.toJSON {
    buildPlans."Iosevka-Snow" = {
      family = "Iosevka Snow";
      spacing = "term";
      serifs = "sans";
      noCvSs = false;
      exportGlyphNames = false;
      weights = {
        regular = { shape = 400; menu = 400; css = 400; };
        bold = { shape = 700; menu = 700; css = 700; };
      };
      widths = {
        normal = { shape = 600; menu = 3; css = "normal"; };
      };
      sets = [ "all" ];
    };
  };

  configurePhase = ''
    runHook preConfigure
    printf "%s" "$buildPlan" | jsontoml -use-json-number > private-build-plans.toml
    runHook postConfigure
  '';

  buildPhase = ''
    export HOME=$TMPDIR
    runHook preBuild
    npm run build --no-update-notifier --targets ttf::"$pname" -- --jCmd=$NIX_BUILD_CORES --verbosity=9 | cat
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    fontdir="$out/share/fonts/truetype"
    install -d "$fontdir"
    install "dist/$pname/TTF"/* "$fontdir"
    runHook postInstall
  '';

  enableParallelBuilding = true;
  requiredSystemFeatures = [ "big-parallel" ];

  meta = iosevka.meta;
}
