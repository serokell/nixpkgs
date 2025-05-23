{
  lib,
  python3Packages,
  fetchPypi,
  dbus,
}:
python3Packages.buildPythonApplication rec {
  pname = "spotify-cli-linux";
  version = "1.8.2";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-XJMkiQR1FoeIPfAuJT22kfYJdc/ABuxExELh0EEev8k=";
  };

  preBuild = ''
    substituteInPlace spotifycli/spotifycli.py \
      --replace dbus-send ${dbus}/bin/dbus-send
  '';

  disabled = !python3Packages.isPy3k;
  propagatedBuildInputs = with python3Packages; [
    lyricwikia
    dbus-python
  ];

  # upstream has no code tests, but uses its "tests" for linting and formatting checks
  doCheck = false;

  meta = with lib; {
    homepage = "https://pwittchen.github.io/spotify-cli-linux/";
    maintainers = [ maintainers.kmein ];
    description = "Command line interface to Spotify on Linux";
    mainProgram = "spotifycli";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
