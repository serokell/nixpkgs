{ stdenv, fetchurl, makeWrapper, jre, gawk }:

stdenv.mkDerivation rec {
  name = "youtrack-${version}";
  version = "2018.2.42284";

  jar = fetchurl {
    url = "https://download.jetbrains.com/charisma/${name}.jar";
    sha256 = "1ys2w5kqyjlba3kgb5w4qr8m55cp8rxipxl9gghbzhis3wqjf497";
  };

  buildInputs = [ makeWrapper ];

  unpackPhase = "true";

  installPhase = ''
    runHook preInstall
    makeWrapper ${jre}/bin/java $out/bin/youtrack --add-flags "\$YOUTRACK_JVM_OPTS -jar $jar" --prefix PATH : "${stdenv.lib.makeBinPath [ gawk ]}" --set JRE_HOME ${jre}
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = ''
      Issue Tracking and Project Management Tool for Developers
    '';
    maintainers = with maintainers; [ yorickvp ];
    # https://www.jetbrains.com/youtrack/buy/license.html
    license = licenses.unfree;
  };
}
