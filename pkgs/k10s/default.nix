# k10s — clickable Kubernetes TUI (https://github.com/p10node/k10s), not in
# nixpkgs. Built from source. Its self-updater (`/update`, `k10s update`)
# refuses to write into the read-only store, so bump here instead: change
# version, set both hashes to lib.fakeHash, rebuild, copy the real ones in.
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (finalAttrs: {
  pname = "k10s";
  version = "0.1.10";

  src = fetchFromGitHub {
    owner = "p10node";
    repo = "k10s";
    tag = "v${finalAttrs.version}";
    hash = "sha256-6CMWP5igkXwniVLG8LxLUTUmKDU5OUEuTad3ckL4RiM=";
  };

  vendorHash = "sha256-P2lMDg6barvuaVJy32mP9YGiNoWpdwAex9KIGMwNxN4=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/p10node/k10s/internal/version.Version=v${finalAttrs.version}"
  ];

  # Upstream tests touch the network / a terminal.
  doCheck = false;

  meta = {
    description = "Kubernetes TUI you can click";
    homepage = "https://github.com/p10node/k10s";
    license = lib.licenses.asl20;
    mainProgram = "k10s";
    platforms = lib.platforms.unix;
  };
})
