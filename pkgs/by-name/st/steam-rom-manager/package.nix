{
  lib,
  appimageTools,
  fetchurl,
}:

appimageTools.wrapType2 rec {
  name = "steam-rom-manager";
  version = "2.5.22";

  src = fetchurl {
    url = "https://github.com/SteamGridDB/steam-rom-manager/releases/download/v${version}/Steam-ROM-Manager-${version}.AppImage";
    sha256 = "sha256-XC4earHVsDioQRJIrAFl5a+UFHjS7U5zt2PqfDxEg9s=";
  };

  extraInstallCommands =
    let
      appimageContents = appimageTools.extract { inherit name src; };
    in
    ''
      install -m 444 -D ${appimageContents}/${name}.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/${name}.desktop \
        --replace 'Exec=AppRun' 'Exec=${name}'
      cp -r ${appimageContents}/usr/share/icons $out/share
    '';

  meta = with lib; {
    description = "App for managing ROMs in Steam";
    homepage = "https://github.com/SteamGridDB/steam-rom-manager";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ squarepear ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "steam-rom-manager";
  };
}
