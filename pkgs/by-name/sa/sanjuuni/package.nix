{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  ffmpeg,
  poco,
  ocl-icd,
  opencl-clhpp,
}:

stdenv.mkDerivation rec {
  pname = "sanjuuni";
  version = "0.5";

  src = fetchFromGitHub {
    owner = "MCJack123";
    repo = "sanjuuni";
    rev = version;
    hash = "sha256-wJRPD4OWOTPiyDr9dYseRA7BI942HPfHONVJGTc/+wU=";
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    ffmpeg
    poco
    ocl-icd
    opencl-clhpp
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 sanjuuni $out/bin/sanjuuni

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/MCJack123/sanjuuni";
    description = "Command-line tool that converts images and videos into a format that can be displayed in ComputerCraft";
    changelog = "https://github.com/MCJack123/sanjuuni/releases/tag/${version}";
    maintainers = [ maintainers.tomodachi94 ];
    license = licenses.gpl2Plus;
    broken = stdenv.isDarwin;
    mainProgram = "sanjuuni";
  };
}
