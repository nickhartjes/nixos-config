{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs {pkgs = final;};

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    n8n = import ./mods/n8n.nix {inherit prev;};
    bambu-studio = prev.appimageTools.wrapType2 rec {
      name = "BambuStudio";
      pname = "bambu-studio";
      version = "02.04.00.70";
      ubuntu_version = "24.04_PR-8834";

      src = prev.fetchurl {
        url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/Bambu_Studio_ubuntu-${ubuntu_version}.AppImage";
        sha256 = "sha256:26bc07dccb04df2e462b1e03a3766509201c46e27312a15844f6f5d7fdf1debd";
      };

      profile = ''
        export SSL_CERT_FILE="${prev.cacert}/etc/ssl/certs/ca-bundle.crt"
        export GIO_MODULE_DIR="${prev.glib-networking}/lib/gio/modules/"
      '';

      extraPkgs = pkgs:
        with pkgs; [
          cacert
          glib
          glib-networking
          gst_all_1.gst-plugins-bad
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good
          webkitgtk_4_1
        ];
    };
  };

  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };

  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
}
