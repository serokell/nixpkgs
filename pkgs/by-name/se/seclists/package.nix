{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "seclists";
  version = "2024.3";

  src = fetchFromGitHub {
    owner = "danielmiessler";
    repo = "SecLists";
    rev = "2024.3";
    hash = "sha256-Ffd4jpV8F6rtMQVqsu+8X/QU5rwbKXv0zkOCmUuhP8I=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/wordlists/seclists
    find . -maxdepth 1 -type d -regextype posix-extended -regex '^./[A-Z].*' -exec cp -R {} $out/share/wordlists/seclists \;
    find $out/share/wordlists/seclists -name "*.md" -delete

    runHook postInstall
  '';

  meta = with lib; {
    description = "Collection of multiple types of lists used during security assessments, collected in one place";
    homepage = "https://github.com/danielmiessler/seclists";
    license = licenses.mit;
    maintainers = with maintainers; [
      tochiaha
      pamplemousse
    ];
  };
}
