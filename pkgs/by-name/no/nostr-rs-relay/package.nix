{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  openssl,
  pkg-config,
  libiconv,
  darwin,
  protobuf,
}:

rustPlatform.buildRustPackage rec {
  pname = "nostr-rs-relay";
  version = "0.8.13-unstable-2024-08-14";
  src = fetchFromGitHub {
    owner = "scsibug";
    repo = "nostr-rs-relay";
    rev = "5a2189062560709b641bb13bedaca2cd478b4403";
    hash = "sha256-ZUndTcLGdAODgSsIqajlNdaEYbYWame0vFRBVmRFzKw=";
  };

  cargoHash = "sha256-+agmlg6tAnEJ5o586fUY7V4fdNScDPKCbaZqt7R3gqg=";

  buildInputs =
    [ openssl.dev ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      libiconv
      darwin.apple_sdk.frameworks.Security
      darwin.apple_sdk.frameworks.SystemConfiguration
    ];

  nativeBuildInputs = [
    pkg-config # for openssl
    protobuf
  ];

  meta = with lib; {
    description = "Nostr relay written in Rust";
    homepage = "https://sr.ht/~gheartsfield/nostr-rs-relay/";
    changelog = "https://github.com/scsibug/nostr-rs-relay/releases/tag/${version}";
    maintainers = with maintainers; [ jurraca ];
    license = licenses.mit;
  };
}
