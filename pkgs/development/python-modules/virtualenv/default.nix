{ buildPythonPackage
, fetchPypi
, lib
, recursivePthLoader
}:

buildPythonPackage rec {
  pname = "virtualenv";
  version = "16.4.3";

  src = fetchPypi {
    inherit pname version;
    sha256 = "984d7e607b0a5d1329425dd8845bd971b957424b5ba664729fab51ab8c11bc39";
  };

  # Doubt this is needed - FRidh 2017-07-07
  pythonPath = [ recursivePthLoader ];

  patches = [ ./virtualenv-change-prefix.patch ];

  # Tarball doesn't contain tests
  doCheck = false;

  patches = lib.optionals (isPy27) [
    ./0001-Check-base_prefix-and-base_exec_prefix-for-Python-2.patch
  ];

  meta = {
    description = "A tool to create isolated Python environments";
    homepage = http://www.virtualenv.org;
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ goibhniu ];
  };
}