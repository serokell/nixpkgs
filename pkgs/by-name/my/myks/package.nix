{
  lib,
  buildGoModule,
  fetchFromGitHub,
  testers,
  installShellFiles,
  myks,
  stdenv,
}:

buildGoModule rec {
  pname = "myks";
  version = "4.2.4";

  src = fetchFromGitHub {
    owner = "mykso";
    repo = "myks";
    tag = "v${version}";
    hash = "sha256-RgVlr+POF5IUei/Rf5mHrjkw0wE5BjU3xwm1Ai1Pemw=";
  };

  vendorHash = "sha256-CE5sT7zXN4ZhIIODOUwqrD0GOvnSVvkMcgLbBmJocKo=";

  subPackages = ".";

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${version}"
    "-X=main.commit=nixpkg-${version}"
    "-X=main.date=1970-01-01"
  ];

  nativeBuildInputs = [ installShellFiles ];

  CGO_ENABLED = 0;

  passthru.tests.version = testers.testVersion { package = myks; };

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd myks \
      --bash <($out/bin/myks completion bash) \
      --zsh <($out/bin/myks completion zsh) \
      --fish <($out/bin/myks completion fish)
  '';

  meta = with lib; {
    changelog = "https://github.com/mykso/myks/blob/v${version}/CHANGELOG.md";
    description = "Configuration framework for Kubernetes applications";
    license = licenses.mit;
    homepage = "https://github.com/mykso/myks";
    maintainers = [
      maintainers.kbudde
      maintainers.zebradil
    ];
    mainProgram = "myks";
  };
}
