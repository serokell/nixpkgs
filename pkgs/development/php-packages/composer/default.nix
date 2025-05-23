{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchpatch,
  callPackage,
  php,
  unzip,
  _7zz,
  xz,
  gitMinimal,
  curl,
  cacert,
  makeBinaryWrapper,
  versionCheckHook,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "composer";
  version = "2.8.5";

  # Hash used by ../../../build-support/php/pkgs/composer-phar.nix to
  # use together with the version from this package to keep the
  # bootstrap phar file up-to-date together with the end user composer
  # package.
  passthru.pharHash = "sha256-nO8YIS4iI1GutHa4HeeypTg/d1M2R0Rnv1x8z+hKsMw=";

  composer = callPackage ../../../build-support/php/pkgs/composer-phar.nix {
    inherit (finalAttrs) version;
    inherit (finalAttrs.passthru) pharHash;
  };

  src = fetchFromGitHub {
    owner = "composer";
    repo = "composer";
    tag = finalAttrs.version;
    hash = "sha256-/E/fXh+jefPwzsADpmGyrJ+xqW5CSPNok0DVLD1KZDY=";
  };

  nativeBuildInputs = [ makeBinaryWrapper ];

  buildInputs = [ php ];

  vendor = stdenvNoCC.mkDerivation {
    pname = "${finalAttrs.pname}-vendor";

    inherit (finalAttrs) src version;

    nativeBuildInputs = [
      cacert
      finalAttrs.composer
    ];

    dontPatchShebangs = true;
    doCheck = true;

    buildPhase = ''
      runHook preBuild

      composer install --no-dev --no-interaction --no-progress --optimize-autoloader

      runHook postBuild
    '';

    checkPhase = ''
      runHook preCheck

      composer validate

      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall

      cp -ar . $out/

      runHook postInstall
    '';

    env = {
      COMPOSER_CACHE_DIR = "/dev/null";
      COMPOSER_DISABLE_NETWORK = "0";
      COMPOSER_HTACCESS_PROTECT = "0";
      COMPOSER_MIRROR_PATH_REPOS = "1";
      COMPOSER_ROOT_VERSION = finalAttrs.version;
    };

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-UcMB0leKqD8cXeExXpjDgPvF8pfhGXnCR0EN4FVWouw=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -ar ${finalAttrs.vendor}/* $out/
    chmod +w $out/bin

    wrapProgram $out/bin/composer \
      --prefix PATH : ${
        lib.makeBinPath [
          _7zz
          curl
          gitMinimal
          unzip
          xz
        ]
      }

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  meta = {
    changelog = "https://github.com/composer/composer/releases/tag/${finalAttrs.version}";
    description = "Dependency Manager for PHP";
    homepage = "https://getcomposer.org/";
    license = lib.licenses.mit;
    mainProgram = "composer";
    maintainers = lib.teams.php.members;
  };
})
