{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  setuptools,

  # dependencies
  click,
  cloudpickle,
  fsspec,
  importlib-metadata,
  packaging,
  partd,
  pyyaml,
  toolz,

  # optional-dependencies
  numpy,
  pyarrow,
  lz4,
  pandas,
  distributed,
  bokeh,
  jinja2,

  # tests
  arrow-cpp,
  dask-expr,
  hypothesis,
  pytest-asyncio,
  pytest-rerunfailures,
  pytest-xdist,
  pytestCheckHook,
}:

let
  self = buildPythonPackage rec {
    pname = "dask";
    version = "2024.10.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "dask";
      repo = "dask";
      tag = version;
      hash = "sha256-UB/LqgDRXnjJ/RjEke9eBDyVAy+Dtak7wYJB63xmDd4=";
    };

    build-system = [ setuptools ];

    dependencies = [
      click
      cloudpickle
      fsspec
      packaging
      partd
      pyyaml
      importlib-metadata
      toolz
    ];

    optional-dependencies = lib.fix (self: {
      array = [ numpy ];
      complete =
        [
          pyarrow
          lz4
        ]
        ++ self.array
        ++ self.dataframe
        ++ self.distributed
        ++ self.diagnostics;
      dataframe = [
        # dask-expr -> circular dependency with dask-expr
        numpy
        pandas
      ];
      distributed = [ distributed ];
      diagnostics = [
        bokeh
        jinja2
      ];
    });

    nativeCheckInputs =
      [
        dask-expr
        pytestCheckHook
        pytest-rerunfailures
        pytest-xdist
        # from panda[test]
        hypothesis
        pytest-asyncio
      ]
      ++ self.optional-dependencies.array
      ++ self.optional-dependencies.dataframe
      ++ lib.optionals (!arrow-cpp.meta.broken) [
        # support is sparse on aarch64
        pyarrow
      ];

    dontUseSetuptoolsCheck = true;

    postPatch = ''
      # versioneer hack to set version of GitHub package
      echo "def get_versions(): return {'dirty': False, 'error': None, 'full-revisionid': None, 'version': '${version}'}" > dask/_version.py

      substituteInPlace setup.py \
        --replace-fail "import versioneer" "" \
        --replace-fail "version=versioneer.get_version()," "version='${version}'," \
        --replace-fail "cmdclass=versioneer.get_cmdclass()," ""

      substituteInPlace pyproject.toml \
        --replace-fail ', "versioneer[toml]==0.29"' "" \
        --replace-fail " --durations=10" "" \
        --replace-fail " --cov-config=pyproject.toml" "" \
        --replace-fail "\"-v" "\" "
    '';

    pytestFlagsArray = [
      # Rerun failed tests up to three times
      "--reruns 3"
      # Don't run tests that require network access
      "-m 'not network'"
    ];

    disabledTests =
      lib.optionals stdenv.hostPlatform.isDarwin [
        # Test requires features of python3Packages.psutil that are
        # blocked in sandboxed-builds
        "test_auto_blocksize_csv"
        # AttributeError: 'str' object has no attribute 'decode'
        "test_read_dir_nometa"
      ]
      ++ lib.optionals (stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64) [
        # concurrent.futures.process.BrokenProcessPool: A process in the process pool terminated abpruptly...
        "test_foldby_tree_reduction"
        "test_to_bag"
      ]
      ++ [
        # https://github.com/dask/dask/issues/10347#issuecomment-1589683941
        "test_concat_categorical"
        # AttributeError: 'ArrowStringArray' object has no attribute 'tobytes'. Did you mean: 'nbytes'?
        "test_dot"
        "test_dot_nan"
        "test_merge_column_with_nulls"
        # FileNotFoundError: [Errno 2] No such file or directory: '/build/tmp301jryv_/createme/0.part'
        "test_to_csv_nodir"
        "test_to_json_results"
        # FutureWarning: Those tests should be working fine when pandas will have been upgraded to 2.1.1
        "test_apply"
        "test_apply_infer_columns"
      ];

    __darwinAllowLocalNetworking = true;

    pythonImportsCheck = [
      "dask"
      "dask.bag"
      "dask.bytes"
      "dask.diagnostics"
    ];

    doCheck = false;

    # Enable tests via passthru to avoid cyclic dependency with dask-expr.
    passthru.tests = {
      check = self.overridePythonAttrs (old: {
        doCheck = true;
        pythonImportsCheck = [
          # Requires the `dask.optional-dependencies.array` that are only in `nativeCheckInputs`
          "dask.array"
          # Requires the `dask.optional-dependencies.dataframe` that are only in `nativeCheckInputs`
          "dask.dataframe"
          "dask.dataframe.io"
          "dask.dataframe.tseries"
        ] ++ old.pythonImportsCheck;
      });
    };

    meta = {
      description = "Minimal task scheduling abstraction";
      mainProgram = "dask";
      homepage = "https://dask.org/";
      changelog = "https://docs.dask.org/en/latest/changelog.html";
      license = lib.licenses.bsd3;
      maintainers = with lib.maintainers; [ GaetanLepage ];
    };
  };
in
self
