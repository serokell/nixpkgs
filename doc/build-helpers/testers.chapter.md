# Testers {#chap-testers}

This chapter describes several testing builders which are available in the `testers` namespace.

## `hasPkgConfigModules` {#tester-hasPkgConfigModules}

<!-- Old anchor name so links still work -->
[]{#tester-hasPkgConfigModule}
Checks whether a package exposes a given list of `pkg-config` modules.
If the `moduleNames` argument is omitted, `hasPkgConfigModules` will use `meta.pkgConfigModules`.

:::{.example #ex-haspkgconfigmodules-defaultvalues}

# Check that `pkg-config` modules are exposed using default values

```nix
{
  passthru.tests.pkg-config = testers.hasPkgConfigModules {
    package = finalAttrs.finalPackage;
  };

  meta.pkgConfigModules = [ "libfoo" ];
}
```

:::

:::{.example #ex-haspkgconfigmodules-explicitmodules}

# Check that `pkg-config` modules are exposed using explicit module names

```nix
{
  passthru.tests.pkg-config = testers.hasPkgConfigModules {
    package = finalAttrs.finalPackage;
    moduleNames = [ "libfoo" ];
  };
}
```

:::

## `lycheeLinkCheck` {#tester-lycheeLinkCheck}

Check a packaged static site's links with the [`lychee` package](https://search.nixos.org/packages?show=lychee&type=packages&query=lychee).

You may use Nix to reproducibly build static websites, such as for software documentation.
Some packages will install documentation in their `out` or `doc` outputs, or maybe you have dedicated package where you've made your static site reproducible by running a generator, such as [Hugo](https://gohugo.io/) or [mdBook](https://rust-lang.github.io/mdBook/), in a derivation.

If you have a static site that can be built with Nix, you can use `lycheeLinkCheck` to check that the hyperlinks in your site are correct, and do so as part of your Nix workflow and CI.

:::{.example #ex-lycheelinkcheck}

# Check hyperlinks in the `nix` documentation

```nix
testers.lycheeLinkCheck {
  site = nix.doc + "/share/doc/nix/manual";
}
```

:::

### Return value {#tester-lycheeLinkCheck-return}

This tester produces a package that does not produce useful outputs, but only succeeds if the hyperlinks in your site are correct. The build log will list the broken links.

It has two modes:

- Build the returned derivation; its build process will check that internal hyperlinks are correct. This runs in the sandbox, so it will not check external hyperlinks, but it is quick and reliable.

- Invoke the `.online` attribute with [`nix run`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-run) ([experimental](https://nixos.org/manual/nix/stable/contributing/experimental-features#xp-feature-nix-command)). This runs outside the sandbox, and checks that both internal and external hyperlinks are correct.
  Example:

  ```shell
  nix run nixpkgs#lychee.tests.ok.online
  ```

### Inputs {#tester-lycheeLinkCheck-inputs}

`site` (path or derivation) {#tester-lycheeLinkCheck-param-site}

: The path to the files to check.

`remap` (attribe set, optional) {#tester-lycheeLinkCheck-param-remap}

: An attribute set where the attribute names are regular expressions.
  The values should be strings, derivations, or path values.

  In the returned check's default configuration, external URLs are only checked when you run the `.online` attribute.

  By adding remappings, you can check offline that URLs to external resources are correct, by providing a stand-in from the file system.

  Before checking the existence of a URL, the regular expressions are matched and replaced by their corresponding values.

  Example:

  ```nix
  {
    "https://nix\\.dev/manual/nix/[a-z0-9.-]*" = "${nix.doc}/share/doc/nix/manual";
    "https://nixos\\.org/manual/nix/(un)?stable" =
      "${emptyDirectory}/placeholder-to-disallow-old-nix-docs-urls";
  }
  ```

  Store paths in the attribute values are automatically prefixed with `file://`, because lychee requires this for paths in the file system.
  If this is a problem, or if you need to control the order in which replacements are performed, use `extraConfig.remap` instead.

`extraConfig` (attribute set) {#tester-lycheeLinkCheck-param-extraConfig}

: Extra configuration to pass to `lychee` in its [configuration file](https://github.com/lycheeverse/lychee/blob/master/lychee.example.toml).
  It is automatically [translated](https://nixos.org/manual/nixos/stable/index.html#sec-settings-nix-representable) to TOML.

  Example: `{ "include_verbatim" = true; }`

`lychee` (derivation, optional) {#tester-lycheeLinkCheck-param-lychee}

: The `lychee` package to use.

## `shellcheck` {#tester-shellcheck}

Runs files through `shellcheck`, a static analysis tool for shell scripts.

:::{.example #ex-shellcheck}
# Run `testers.shellcheck`

A single script

```nix
testers.shellcheck {
  name = "shellcheck";
  src = ./script.sh;
}
```

Multiple files

```nix
let
  inherit (lib) fileset;
in
testers.shellcheck {
  name = "shellcheck";
  src = fileset.toSource {
    root = ./.;
    fileset = fileset.unions [
      ./lib.sh
      ./nixbsd-activate
    ];
  };
}
```

:::

### Inputs {#tester-shellcheck-inputs}

[`src` (path or string)]{#tester-shellcheck-param-src}

: The path to the shell script(s) to check.
  This can be a single file or a directory containing shell files.
  All files in `src` will be checked, so you may want to provide `fileset`-based source instead of a whole directory.

### Return value {#tester-shellcheck-return}

A derivation that runs `shellcheck` on the given script(s).
The build will fail if `shellcheck` finds any issues.

## `testVersion` {#tester-testVersion}

Checks that the output from running a command contains the specified version string in it as a whole word.

NOTE: This is a check you add to `passthru.tests` which is mainly run by OfBorg, but not in Hydra. If you want a version check failure to block the build altogether, then [`versionCheckHook`](#versioncheckhook) is the tool you're looking for (and recommended for quick builds). The motivation for adding either of these checks would be:

- Catch dynamic linking errors and such and missing environment variables that should be added by wrapping.
- Probable protection against accidentally building the wrong version, for example when using an "old" hash in a fixed-output derivation.

By default, the command to be run will be inferred from the given `package` attribute:
it will check `meta.mainProgram` first, and fall back to `pname` or `name`.
The default argument to the command is `--version`, and the version to be checked will be inferred from the given `package` attribute as well.

:::{.example #ex-testversion-hello}

# Check a program version using all the default values

This example will run the command `hello --version`, and then check that the version of the `hello` package is in the output of the command.

```nix
{
  passthru.tests.version = testers.testVersion { package = hello; };
}
```

:::

:::{.example #ex-testversion-different-commandversion}

# Check the program version using a specified command and expected version string

This example will run the command `leetcode -V`, and then check that `leetcode 0.4.2` is in the output of the command as a whole word (separated by whitespaces).
This means that an output like "leetcode 0.4.21" would fail the tests, and an output like "You're running leetcode 0.4.2" would pass the tests.

A common usage of the `version` attribute is to specify `version = "v${version}"`.

```nix
{
  version = "0.4.2";

  passthru.tests.version = testers.testVersion {
    package = leetcode-cli;
    command = "leetcode -V";
    version = "leetcode ${version}";
  };
}
```

:::

## `testBuildFailure` {#tester-testBuildFailure}

Make sure that a build does not succeed. This is useful for testing testers.

This returns a derivation with an override on the builder, with the following effects:

 - Fail the build when the original builder succeeds
 - Move `$out` to `$out/result`, if it exists (assuming `out` is the default output)
 - Save the build log to `$out/testBuildFailure.log` (same)

While `testBuildFailure` is designed to keep changes to the original builder's environment to a minimum, some small changes are inevitable:

 - The file `$TMPDIR/testBuildFailure.log` is present. It should not be deleted.
 - `stdout` and `stderr` are a pipe instead of a tty. This could be improved.
 - One or two extra processes are present in the sandbox during the original builder's execution.
 - The derivation and output hashes are different, but not unusual.
 - The derivation includes a dependency on `buildPackages.bash` and `expect-failure.sh`, which is built to include a transitive dependency on `buildPackages.coreutils` and possibly more.
   These are not added to `PATH` or any other environment variable, so they should be hard to observe.

:::{.example #ex-testBuildFailure-showingenvironmentchanges}

# Check that a build fails, and verify the changes made during build

```nix
runCommand "example"
  {
    failed = testers.testBuildFailure (
      runCommand "fail" { } ''
        echo ok-ish >$out
        echo failing though
        exit 3
      ''
    );
  }
  ''
    grep -F 'ok-ish' $failed/result
    grep -F 'failing though' $failed/testBuildFailure.log
    [[ 3 = $(cat $failed/testBuildFailure.exit) ]]
    touch $out
  ''
```

:::

## `testEqualContents` {#tester-testEqualContents}

Check that two paths have the same contents.

:::{.example #ex-testEqualContents-toyexample}

# Check that two paths have the same contents

```nix
testers.testEqualContents {
  assertion = "sed -e performs replacement";
  expected = writeText "expected" ''
    foo baz baz
  '';
  actual =
    runCommand "actual"
      {
        # not really necessary for a package that's in stdenv
        nativeBuildInputs = [ gnused ];
        base = writeText "base" ''
          foo bar baz
        '';
      }
      ''
        sed -e 's/bar/baz/g' $base >$out
      '';
}
```

:::

## `testEqualDerivation` {#tester-testEqualDerivation}

Checks that two packages produce the exact same build instructions.

This can be used to make sure that a certain difference of configuration, such as the presence of an overlay does not cause a cache miss.

When the derivations are equal, the return value is an empty file.
Otherwise, the build log explains the difference via `nix-diff`.

:::{.example #ex-testEqualDerivation-hello}

# Check that two packages produce the same derivation

```nix
testers.testEqualDerivation "The hello package must stay the same when enabling checks." hello (
  hello.overrideAttrs (o: {
    doCheck = true;
  })
)
```

:::

## `invalidateFetcherByDrvHash` {#tester-invalidateFetcherByDrvHash}

Use the derivation hash to invalidate the output via name, for testing.

Type: `(a@{ name, ... } -> Derivation) -> a -> Derivation`

Normally, fixed output derivations can and should be cached by their output hash only, but for testing we want to re-fetch everytime the fetcher changes.

Changes to the fetcher become apparent in the drvPath, which is a hash of how to fetch, rather than a fixed store path.
By inserting this hash into the name, we can make sure to re-run the fetcher every time the fetcher changes.

This relies on the assumption that Nix isn't clever enough to reuse its database of local store contents to optimize fetching.

You might notice that the "salted" name derives from the normal invocation, not the final derivation.
`invalidateFetcherByDrvHash` has to invoke the fetcher function twice:
once to get a derivation hash, and again to produce the final fixed output derivation.

:::{.example #ex-invalidateFetcherByDrvHash-nix}

# Prevent nix from reusing the output of a fetcher

```nix
{
  tests.fetchgit = testers.invalidateFetcherByDrvHash fetchgit {
    name = "nix-source";
    url = "https://github.com/NixOS/nix";
    rev = "9d9dbe6ed05854e03811c361a3380e09183f4f4a";
    hash = "sha256-7DszvbCNTjpzGRmpIVAWXk20P0/XTrWZ79KSOGLrUWY=";
  };
}
```

:::

## `runCommand` {#tester-runCommand}

`runCommand :: { name, script, stdenv ? stdenvNoCC, hash ? "...", ... } -> Derivation`

This is a wrapper around `pkgs.runCommandWith`, which
- produces a fixed-output derivation, enabling the command(s) to access the network ;
- salts the derivation's name based on its inputs, ensuring the command is re-run whenever the inputs changes.

It accepts the following attributes:
- the derivation's `name` ;
- the `script` to be executed ;
- `stdenv`, the environment to use, defaulting to `stdenvNoCC` ;
- the derivation's output `hash`, defaulting to the empty file's.
  The derivation's `outputHashMode` is set by default to recursive, so the `script` can output a directory as well.

All other attributes are passed through to [`mkDerivation`](#sec-using-stdenv),
including `nativeBuildInputs` to specify dependencies available to the `script`.

:::{.example #ex-tester-runCommand-nix}

# Run a command with network access

```nix
testers.runCommand {
  name = "access-the-internet";
  script = ''
    curl -o /dev/null https://example.com
    touch $out
  '';
  nativeBuildInputs = with pkgs; [
    cacert
    curl
  ];
}
```

:::

## `runNixOSTest` {#tester-runNixOSTest}

A helper function that behaves exactly like the NixOS `runTest`, except it also assigns this Nixpkgs package set as the `pkgs` of the test and makes the `nixpkgs.*` options read-only.

If your test is part of the Nixpkgs repository, or if you need a more general entrypoint, see ["Calling a test" in the NixOS manual](https://nixos.org/manual/nixos/stable/index.html#sec-calling-nixos-tests).

:::{.example #ex-runNixOSTest-hello}

# Run a NixOS test using `runNixOSTest`

```nix
pkgs.testers.runNixOSTest (
  { lib, ... }:
  {
    name = "hello";
    nodes.machine =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.hello ];
      };
    testScript = ''
      machine.succeed("hello")
    '';
  }
)
```

:::

## `nixosTest` {#tester-nixosTest}

Run a NixOS VM network test using this evaluation of Nixpkgs.

NOTE: This function is primarily for external use. NixOS itself uses `make-test-python.nix` directly. Packages defined in Nixpkgs [reuse NixOS tests via `nixosTests`, plural](#ssec-nixos-tests-linking).

It is mostly equivalent to the function `import ./make-test-python.nix` from the [NixOS manual](https://nixos.org/nixos/manual/index.html#sec-nixos-tests), except that the current application of Nixpkgs (`pkgs`) will be used, instead of letting NixOS invoke Nixpkgs anew.

If a test machine needs to set NixOS options under `nixpkgs`, it must set only the `nixpkgs.pkgs` option.

### Parameter {#tester-nixosTest-parameter}

A [NixOS VM test network](https://nixos.org/nixos/manual/index.html#sec-nixos-tests), or path to it. Example:

```nix
{
  name = "my-test";
  nodes = {
    machine1 =
      {
        lib,
        pkgs,
        nodes,
        ...
      }:
      {
        environment.systemPackages = [ pkgs.hello ];
        services.foo.enable = true;
      };
    # machine2 = ...;
  };
  testScript = ''
    start_all()
    machine1.wait_for_unit("foo.service")
    machine1.succeed("hello | foo-send")
  '';
}
```

### Result {#tester-nixosTest-result}

A derivation that runs the VM test.

Notable attributes:

 * `nodes`: the evaluated NixOS configurations. Useful for debugging and exploring the configuration.

 * `driverInteractive`: a script that launches an interactive Python session in the context of the `testScript`.
