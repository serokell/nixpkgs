{
  lib,
  aiohttp,
  buildPythonPackage,
  fetchFromGitHub,
  poetry-core,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "zamg";
  version = "0.3.6";
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "killer0071234";
    repo = "python-zamg";
    tag = "v${version}";
    hash = "sha256-j864+3c0GDDftdLqLDD0hizT54c0IgTjT77jOneXlq0=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace " --cov" ""
  '';

  nativeBuildInputs = [ poetry-core ];

  propagatedBuildInputs = [ aiohttp ];

  # Module has no tests
  doCheck = false;

  pythonImportsCheck = [ "zamg" ];

  meta = with lib; {
    description = "Library to read weather data from ZAMG Austria";
    homepage = "https://github.com/killer0071234/python-zamg";
    changelog = "https://github.com/killer0071234/python-zamg/releases/tag/v${version}";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ fab ];
  };
}
