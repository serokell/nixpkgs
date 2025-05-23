{
  lib,
  openssl,
  git,
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  testers,
}:
buildDotnetModule (finalAttrs: {
  pname = "recyclarr";
  version = "7.2.4";

  src = fetchFromGitHub {
    owner = "recyclarr";
    repo = "recyclarr";
    rev = "v${finalAttrs.version}";
    hash = "sha256-FFaGyMOXivorXVqCcYskEibnHnzhJ/AlxR46AtWFkI4=";
  };

  projectFile = "Recyclarr.sln";
  nugetDeps = ./deps.json;

  prePatch = ''
    substituteInPlace src/Recyclarr.Cli/Program.cs \
      --replace-fail '$"v{GitVersionInformation.SemVer} ({GitVersionInformation.FullBuildMetaData})"' '"${finalAttrs.version}-nixpkgs"'

    substituteInPlace src/Recyclarr.Cli/Console/Setup/ProgramInformationDisplayTask.cs \
      --replace-fail 'GitVersionInformation.InformationalVersion' '"${finalAttrs.version}-nixpkgs"'
  '';
  patches = [ ./001-Git-Version.patch ];

  enableParallelBuilding = false;

  doCheck = false;

  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.runtime_8_0;
  dotnet-test-sdk = dotnetCorePackages.sdk_8_0;

  executables = [ "recyclarr" ];
  makeWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        git
        openssl
      ]
    }"
  ];

  passthru = {
    updateScript = ./update.sh;
    tests.version = testers.testVersion { package = finalAttrs.finalPackage; };
  };

  meta = {
    description = "Automatically sync TRaSH guides to your Sonarr and Radarr instances";
    homepage = "https://recyclarr.dev/";
    changelog = "https://github.com/recyclarr/recyclarr/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      josephst
      aldoborrero
    ];
    mainProgram = "recyclarr";
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
  };
})
