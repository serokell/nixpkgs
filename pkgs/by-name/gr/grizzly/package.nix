{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:

buildGoModule rec {
  pname = "grizzly";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "grafana";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-zk6qcFWoRYyjy3mVSJdqwEj279QjWVF8fFYojOoD5jc=";
  };

  vendorHash = "sha256-lioFmaFzqaxN1wnYJaoHA54to1xGZjaLGaqAFIfTaTs=";

  subPackages = [ "cmd/grr" ];

  meta = with lib; {
    description = "Utility for managing Jsonnet dashboards against the Grafana API";
    homepage = "https://grafana.github.io/grizzly/";
    license = licenses.asl20;
    maintainers = with lib.maintainers; [ nrhtr ];
    platforms = platforms.unix;
    mainProgram = "grr";
  };
}
