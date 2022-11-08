{ pkgs, lib }:

with pkgs;

(let

  # Common passthru for all Python interpreters.
  passthruFun =
    { implementation
    , libPrefix
    , executable
    , sourceVersion
    , pythonVersion
    , packageOverrides
    , sitePackages
    , hasDistutilsCxxPatch
    , pythonForBuild
    , self
    }: let
      pythonPackages = callPackage ../../../top-level/python-packages.nix {
        python = self;
        overrides = packageOverrides;
      };
    in rec {
        isPy27 = pythonVersion == "2.7";
        isPy33 = pythonVersion == "3.3"; # TODO: remove
        isPy34 = pythonVersion == "3.4"; # TODO: remove
        isPy35 = pythonVersion == "3.5";
        isPy36 = pythonVersion == "3.6";
        isPy37 = pythonVersion == "3.7";
        isPy38 = pythonVersion == "3.8";
        isPy39 = pythonVersion == "3.9";
        isPy2 = lib.strings.substring 0 1 pythonVersion == "2";
        isPy3 = lib.strings.substring 0 1 pythonVersion == "3";
        isPy3k = isPy3;
        isPyPy = lib.hasInfix "pypy" interpreter;

        buildEnv = callPackage ./wrapper.nix { python = self; inherit (pythonPackages) requiredPythonModules; };
        withPackages = import ./with-packages.nix { inherit buildEnv pythonPackages;};
        pkgs = pythonPackages;
        interpreter = "${self}/bin/${executable}";
        inherit executable implementation libPrefix pythonVersion sitePackages;
        inherit sourceVersion;
        pythonAtLeast = lib.versionAtLeast pythonVersion;
        pythonOlder = lib.versionOlder pythonVersion;
        inherit hasDistutilsCxxPatch pythonForBuild;

        tests = callPackage ./tests.nix {
          python = self;
        };
  };

in {

  python27 = callPackage ./cpython/2.7 {
    self = python27;
    sourceVersion = {
      major = "2";
      minor = "7";
      patch = "18";
      suffix = "";
    };
    sha256 = "0hzgxl94hnflis0d6m4szjx0b52gah7wpmcg5g00q7am6xwhwb5n";
    inherit (darwin) configd;
    inherit passthruFun;
  };

  python35 = callPackage ./cpython {
    self = python35;
    sourceVersion = {
      major = "3";
      minor = "5";
      patch = "9";
      suffix = "";
    };
    sha256 = "0jdh9pvx6m6lfz2liwvvhn7vks7qrysqgwn517fkpxb77b33fjn2";
    inherit (darwin) configd;
    inherit passthruFun;
  };

  python36 = callPackage ./cpython {
    self = python36;
    sourceVersion = {
      major = "3";
      minor = "6";
      patch = "13";
      suffix = "";
    };
    sha256 = "pHpDpTq7QihqLBGWU0P/VnEbnmTo0RvyxnAaT7jOGg8=";
    inherit (darwin) configd;
    inherit passthruFun;
  };

  python37 = callPackage ./cpython {
    self = python37;
    sourceVersion = {
      major = "3";
      minor = "7";
      patch = "10";
      suffix = "";
    };
    sha256 = "+NgudXLIbsnVXIYnquUEAST9IgOvQAw4PIIbmAMG7ms=";
    inherit (darwin) configd;
    inherit passthruFun;
  };

  python38 = callPackage ./cpython {
    self = python38;
    sourceVersion = {
      major = "3";
      minor = "8";
      patch = "8";
      suffix = "";
    };
    sha256 = "fGZCSf935EPW6g5M8OWH6ukYyjxI0IHRkV/iofG8xcw=";
    inherit (darwin) configd;
    inherit passthruFun;
  };

  python39 = callPackage ./cpython {
    self = python39;
    sourceVersion = {
      major = "3";
      minor = "9";
      patch = "2";
      suffix = "";
    };
    sha256 = "PCA0xU+BFEj1FmaNzgnSQAigcWw6eU3YY5tTiMveJH0=";
    inherit (darwin) configd;
    inherit passthruFun;
  };

  # Minimal versions of Python (built without optional dependencies)
  python3Minimal = (python38.override {
    self = python3Minimal;
    pythonForBuild = pkgs.buildPackages.python3Minimal;
    # strip down that python version as much as possible
    openssl = null;
    readline = null;
    ncurses = null;
    gdbm = null;
    sqlite = null;
    configd = null;
    stripConfig = true;
    stripIdlelib = true;
    stripTests = true;
    stripTkinter = true;
    rebuildBytecode = false;
    stripBytecode = true;
    includeSiteCustomize = false;
    enableOptimizations = false;
  }).overrideAttrs(old: {
    pname = "python3-minimal";
    meta = old.meta // {
      maintainers = [];
    };
  });

  pypy27 = callPackage ./pypy {
    self = pypy27;
    sourceVersion = {
      major = "7";
      minor = "3";
      patch = "1";
    };
    sha256 = "08ckkhd0ix6j9873a7gr507c72d4cmnv5lwvprlljdca9i8p2dzs";
    pythonVersion = "2.7";
    db = db.override { dbmSupport = true; };
    python = python27;
    inherit passthruFun;
  };

  pypy36 = callPackage ./pypy {
    self = pypy36;
    sourceVersion = {
      major = "7";
      minor = "3";
      patch = "1";
    };
    sha256 = "10zsk8jby8j6visk5mzikpb1cidvz27qq4pfpa26jv53klic6b0c";
    pythonVersion = "3.6";
    db = db.override { dbmSupport = true; };
    python = python27;
    inherit passthruFun;
  };

  pypy27_prebuilt = callPackage ./pypy/prebuilt.nix {
    # Not included at top-level
    self = pythonInterpreters.pypy27_prebuilt;
    sourceVersion = {
      major = "7";
      minor = "3";
      patch = "1";
    };
    sha256 = "18xc5kwidj5hjwbr0w8v1nfpg5l4lk01z8cn804zfyyz8xjqhx5y"; # linux64
    pythonVersion = "2.7";
    inherit passthruFun;
  };

  pypy36_prebuilt = callPackage ./pypy/prebuilt.nix {
    # Not included at top-level
    self = pythonInterpreters.pypy36_prebuilt;
    sourceVersion = {
      major = "7";
      minor = "3";
      patch = "1";
    };
    sha256 = "04nv0mkalaliphbjw7y0pmb372bxwjzwmcsqkf9kwsik99kg2z7n"; # linux64
    pythonVersion = "3.6";
    inherit passthruFun;
  };

})
