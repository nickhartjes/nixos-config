# Installation of NixOS



## 

### Option 01: Using the bootable ISO

1. Download the latest NixOS ISO from the [NixOS download page](https://nixos.org/download/#nixos-iso).
2. Create a bootable USB drive using the ISO.
3. Boot from the USB drive.
4. Once in the live environment, open a terminal.
5. Create a repository to store your nixos configuration files.
   ```shell
   # We need to opt in into the experimental features
   export NIX_CONFIG="experimental-features = nix-command flakes"
   cd ~/Documents
    ```

   ```shell
   nix run git init nixos-config
   nix-shell -p git --run "git init nixos-config"
   cd nixos-config
   ```
6. Get the template for the configuration files.
   ```shell
   nix flake init -t github.com/nickhartjes/nixos-config
   ```

7. Clone your nixos-config repository
    ```shell 
     nix-shell -p git --run "git clone https://github.com/nickhartjes/nixos-config.git"
    ```
8. Change into the directory
   ```
   cd nixos-config
   ```
9. Edit the the files in the `nixos-config` directory to your liking. 
10. Run the following command to build and switch to your new configuration:
    ```shell
    sudo nixos-install --flake .#hostname
    ```
    For testing purposes, you can use the blackhawk-vm configuration.
    ```shell
    sudo nixos-install --flake .#blackhawk-vm
    ```
11. Wait for the installation to finish. This may take a while. After the installation is complete, you will be prompted to reboot your system.
   df -