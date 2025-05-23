{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  typing-extensions,
  pytestCheckHook,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "emoji";
  version = "2.13.2";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "carpedm20";
    repo = "emoji";
    tag = "v${version}";
    hash = "sha256-1oFzuIA2HFoBw50HHYi8bGZTAAeC6fesSnLReuXUZcM=";
  };

  build-system = [ setuptools ];

  dependencies = [ typing-extensions ];

  nativeCheckInputs = [ pytestCheckHook ];

  disabledTests = [ "test_emojize_name_only" ];

  pythonImportsCheck = [ "emoji" ];

  meta = with lib; {
    description = "Emoji for Python";
    homepage = "https://github.com/carpedm20/emoji/";
    changelog = "https://github.com/carpedm20/emoji/blob/v${version}/CHANGES.md";
    license = licenses.bsd3;
    maintainers = with maintainers; [ joachifm ];
  };
}
