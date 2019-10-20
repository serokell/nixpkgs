{ lib
, python
, buildPythonPackage
, bootstrapped-pip
, fetchFromGitHub
, mock
, scripttest
, virtualenv
, pretend
, pytest
, setuptools
, wheel
}:

buildPythonPackage rec {
  pname = "pip";
  version = "19.3.1";
  format = "other";

  src = fetchFromGitHub {
    owner = "pypa";
    repo = pname;
    rev = version;
    sha256 = "079gz0v37ah1l4i5iwyfb0d3mni422yv5ynnxa0wcqpnvkc7sfnw";
    name = "${pname}-${version}-source";
  };

  # Remove when solved https://github.com/NixOS/nixpkgs/issues/81441
  # Also update pkgs/development/interpreters/python/hooks/pip-install-hook.sh accordingly
  patches = [ ./reproducible.patch ];

  nativeBuildInputs = [ bootstrapped-pip ];

  # pip detects that we already have bootstrapped_pip "installed", so we need
  # to force it a little.
  pipInstallFlags = [ "--ignore-installed" ];

  checkInputs = [ mock scripttest virtualenv pretend pytest ];
  # Pip wants pytest, but tests are not distributed
  doCheck = false;

  meta = {
    description = "The PyPA recommended tool for installing Python packages";
    license = with lib.licenses; [ mit ];
    homepage = https://pip.pypa.io/;
    priority = 10;
  };
}
