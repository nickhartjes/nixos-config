{prev}:
prev.n8n.overrideAttrs (oldAttrs: rec {
  pname = oldAttrs.pname;
  version = "1.63.0";

  src = prev.fetchFromGitHub {
    owner = "n8n-io";
    repo = "n8n";
    rev = "n8n@${version}";
    hash = "sha256-zJHveCbBPJs8qbgCsU+dgucoXpAKa7PVLH4tfdcJZlE=";
  };

  pnpmDeps = prev.pnpm.fetchDeps {
    inherit pname version src;
    hash = "sha256-FsBA/QENfreCJnYCw8MnX5W2D+WJ3DUuTIakH78TYU8=";
  };
})
