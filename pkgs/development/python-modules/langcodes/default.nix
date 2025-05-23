{
  lib,
  buildPythonPackage,
  marisa-trie,
  pythonOlder,
  fetchPypi,
  pytestCheckHook,
  language-data,
  setuptools,
  setuptools-scm,
}:

buildPythonPackage rec {
  pname = "langcodes";
  version = "3.4.1";
  format = "pyproject";

  disabled = pythonOlder "3.6";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-okh5/tI4ATrDryQkudESTji0o4sgRP0pfI/zjlkS5xg=";
  };

  nativeBuildInputs = [
    setuptools
    setuptools-scm
  ];

  propagatedBuildInputs = [
    language-data
    marisa-trie
    setuptools # pkg_resources import in language_data/util.py
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  disabledTests = [
    # AssertionError: assert 'Unknown language [aqk]' == 'Aninka'
    "test_updated_iana"
  ];

  pythonImportsCheck = [ "langcodes" ];

  meta = with lib; {
    description = "Python toolkit for working with and comparing the standardized codes for languages";
    homepage = "https://github.com/georgkrause/langcodes";
    license = licenses.mit;
  };
}
