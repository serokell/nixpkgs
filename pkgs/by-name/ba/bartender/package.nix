{
  lib,
  stdenvNoCC,
  fetchurl,
  _7zz,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "bartender";
  version = "5.2.3";

  src = fetchurl {
    name = "Bartender ${lib.versions.major finalAttrs.version}.dmg";
    url = "https://www.macbartender.com/B2/updates/${
      builtins.replaceStrings [ "." ] [ "-" ] finalAttrs.version
    }/Bartender%20${lib.versions.major finalAttrs.version}.dmg";
    hash = "sha256-G1XL6o5Rk/U5SsT/Q5vWaVSg0qerfzVizjFmudWAI3E=";
  };

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  nativeBuildInputs = [ _7zz ];

  sourceRoot = "Bartender ${lib.versions.major finalAttrs.version}.app";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications/${finalAttrs.sourceRoot}"
    cp -R . "$out/Applications/${finalAttrs.sourceRoot}"

    runHook postInstall
  '';

  meta = {
    description = "Take control of your menu bar";
    longDescription = ''
      Bartender is an award-winning app for macOS that superpowers your menu bar, giving you total control over your menu bar items, what's displayed, and when, with menu bar items only showing when you need them.
      Bartender improves your workflow with quick reveal, search, custom hotkeys and triggers, and lots more.
    '';
    homepage = "https://www.macbartender.com";
    changelog = "https://www.macbartender.com/Bartender${lib.versions.major finalAttrs.version}/release_notes/";
    license = [ lib.licenses.unfree ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = with lib.maintainers; [
      stepbrobd
      DimitarNestorov
    ];
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  };
})
