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
     nix-shell -p git --run "git clone https://github.com/nickhartjes/nixos-config.git ~/.nixos-config"
    ```
8. Change into the directory
   ```
   cd ~/.nixos-config/
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



```shell
[nh@thinkpad-t15:~/projects/nh/nixcfg/installation]$ ls -lsah
total 36K
4.0K drwxr-xr-x  2 nh users 4.0K 16 mei 09:59 .
4.0K drwxr-xr-x 10 nh users 4.0K 15 mei 21:26 ..
4.0K -rw-r--r--  1 nh users 1.2K 16 mei 09:50 configuration.nix
4.0K -rw-r--r--  1 nh users 1.6K 16 mei 09:31 flake.lock
4.0K -rw-r--r--  1 nh users 1.3K 16 mei 09:31 flake.nix
4.0K -rw-r--r--  1 nh users   13 16 mei 09:50 .gitignore
4.0K -rw-r--r--  1 nh users 1010 16 mei 09:25 hardware-configuration.nix
4.0K -rw-r--r--  1 nh users 1.6K 16 mei 10:29 Installation.md
4.0K lrwxrwxrwx  1 nh users   89 16 mei 09:59 result -> /nix/store/zrbmvaap7l3jb74px73ih3agzd7a5m66-nixos-25.05.20250513.adaa24f-x86_64-linux.iso
```

```shell
cp result/iso/*.iso ./nixos-custom-installation.iso
```

If you use the iso from t

Failed to install bootloader



```shell
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount ./hosts/vm/blackhawk/disko-config.nix
```

```shell
sudo nixos-install --flake .#blackhawk-vm
```


```shell
sudo nixos-rebuild boot --flake .#blackhawk-vm
```