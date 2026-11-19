# T3 Code op NixOS-WSL

Deze host is voor een x86_64 Windows-machine met WSL 2. Nix beheert T3 Code,
Codex, Claude Code, Git, GitHub CLI en een systemd-gebruikersservice. Er is geen
Linux-desktop nodig. De server luistert op localhost:3773; remote toegang loopt
via T3 Connect. Je account, provider-logins en projecten blijven lokale data.

## Installeren

Installeer NixOS-WSL volgens https://nix-community.github.io/NixOS-WSL/install.html.
Download `nixos.wsl` van de officiële release. In PowerShell (recente WSL):

```powershell
wsl --install --from-file .\nixos.wsl
wsl -d NixOS
```

Zet de repo inclusief deze wijzigingen in de Linux-filesystem van WSL (niet
onder `/mnt/c`). Deze wijzigingen moeten eerst beschikbaar zijn in de clone;
ze staan niet automatisch op GitHub. In NixOS-WSL:

```sh
nix-shell -p git
sudo mkdir -p /etc/nixos-config
sudo chown "$USER" /etc/nixos-config
git clone https://github.com/nickhartjes/nixos-config.git /etc/nixos-config
cd /etc/nixos-config
sudo nixos-rebuild switch --flake .#wsl-t3
sudo passwd nh
sudo chown -R nh:users /etc/nixos-config
exit
```

De hoofdflake bevat ook private inputs (`traders`, `ja-instituut`): als Nix die
moet ophalen, is toegang tot die GitHub-repositories nodig, ook al gebruikt deze
host hun modules niet. Gebruik daarvoor de bestaande SSH-toegang; zet geen
sleutels in de repo.

Herstart de distro vanuit PowerShell om de standaardgebruiker toe te passen:

```powershell
wsl --terminate NixOS
wsl -d NixOS -u nh
```

## Verbinden

Controleer in WSL:

```sh
systemctl --user status t3code
journalctl --user -u t3code -n 50
```

Voer `t3 pair` uit in WSL en open de getoonde lokale pairing-link in de
Windows-browser. WSL's localhost-forwarding moet ingeschakeld zijn. Open in T3
**Settings → Sharing & access**, log in en schakel **T3 Connect** in. Meld je op
je andere T3-interface aan met hetzelfde account en kies deze omgeving. Daarvoor
hoef je geen Windows firewall-poort of router-portforward te configureren.

Provider-authenticatie doe je in deze omgeving via T3's providerinstellingen of
de geïnstalleerde provider-CLI. Logins zijn eenmalig en staan niet in Nix.

Gebruik geen `t3 up`, `t3 service install` of `t3 update` voor deze host: Nix/Home
Manager beheert de service en versie. Gebruik voor servicebeheer:

```sh
systemctl --user restart t3code
```

Bewaar projecten onder `/home/nh`. De standaard T3-data staat onder `~/.t3`;
maak daar samen met je projecten backups van.

## Updates en beschikbaarheid

```sh
cd /etc/nixos-config
nix flake update nixpkgs
sudo nixos-rebuild switch --flake .#wsl-t3
```

De service start zodra de WSL-distro draait en blijft dankzij `linger` actief
zonder ingelogde shell. Dit start WSL niet automatisch bij Windows-boot en houdt
een slapende Windows-machine niet bereikbaar. Start de distro met `wsl -d NixOS`;
voor onbeheerd gebruik moet Windows wakker blijven en WSL blijven draaien.

Deze configuratie is lokaal geëvalueerd; de Windows/WSL-installatie en T3
Connect-koppeling moeten op de doelmachine worden gecontroleerd.

Bronnen: https://github.com/pingdotgg/t3code/blob/main/docs/user/remote-access.md
 en https://github.com/pingdotgg/t3code/blob/main/docs/user/install.md.
