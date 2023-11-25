{ lib, stdenv, stdenvNoCC, fetchurl, fetchzip, makeBinaryWrapper, makeWrapper, jdk17, jdk17_headless,  p7zip, gawk, statePath ? "/var/lib/youtrack" }:
let
  meta = {
    description = "Issue tracking and project management tool for developers";
    maintainers = lib.teams.serokell.members ++ [ lib.maintainers.leona ];
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    # https://www.jetbrains.com/youtrack/buy/license.html
    license = lib.licenses.unfree;
  };
in {
  # We use the old YouTrack packaing still for 2022.3, because changing would
  # change the data structure.
  youtrack_2022_3 = stdenv.mkDerivation (finalAttrs: {
    pname = "youtrack";
    version = "2022.3.65371";

    jar = fetchurl {
      url = "https://download.jetbrains.com/charisma/youtrack-${finalAttrs.version}.jar";
      sha256 = "sha256-NQKWmKEq5ljUXd64zY27Nj8TU+uLdA37chbFVdmwjNs=";
    };

    nativeBuildInputs = [ makeWrapper ];

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      makeWrapper ${jdk17}/bin/java $out/bin/youtrack \
        --add-flags "\$YOUTRACK_JVM_OPTS -jar $jar" \
        --prefix PATH : "${lib.makeBinPath [ gawk ]}" \
        --set JRE_HOME ${jdk17}
      runHook postInstall
    '';

    inherit meta;
  });

  youtrack = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "youtrack";
    version = "2023.3.22912";

    src = fetchzip {
      url = "https://download.jetbrains.com/charisma/youtrack-${finalAttrs.version}.zip";
      hash = "sha256-LympulV5ezZlCPTvFTahZ7+Q/mI6/2TlGcaHiWBak9w=";
    };

    nativeBuildInputs = [ makeBinaryWrapper ];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r * $out
      makeWrapper $out/bin/youtrack.sh $out/bin/youtrack \
        --prefix PATH : "${lib.makeBinPath [ gawk ]}" \
        --set JRE_HOME ${jdk17_headless}
      rm -rf $out/internal/java
      mv $out/conf $out/conf.orig
      ln -s ${statePath}/backups $out/backups
      ln -s ${statePath}/conf $out/conf
      ln -s ${statePath}/data $out/data
      ln -s ${statePath}/logs $out/logs
      ln -s ${statePath}/temp $out/temp
      runHook postInstall
    '';
    inherit meta;
  });
}
