{
  lib,
  stdenv,
  fetchFromGitHub,
  qtsvg,
  qttools,
  exiv2,
  wrapQtAppsHook,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pineapple-pictures";
  version = "0.8.2.1";

  src = fetchFromGitHub {
    owner = "BLumia";
    repo = "pineapple-pictures";
    rev = finalAttrs.version;
    hash = "sha256-24VDmB0eR8h0JGqpsdN0HkRRIHLw9DIT2sM4rCvPwhE=";
  };

  nativeBuildInputs = [
    cmake
    qttools
    wrapQtAppsHook
  ];

  buildInputs = [
    qtsvg
    exiv2
  ];

  cmakeFlags = [
    "-DPREFER_QT_5=OFF"
  ];

  meta = {
    description = "Homebrew lightweight image viewer";
    homepage = "https://github.com/BLumia/pineapple-pictures";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "ppic";
    maintainers = with lib.maintainers; [ rewine ];
  };
})
