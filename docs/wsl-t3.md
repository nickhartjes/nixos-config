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
nix flake update nixpkgs t3code-flake
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

## Deploy vanaf de Framework

Deze host draait OpenSSH op de Tailscale-interface, met de Framework SSH-keys.
Remote sudo gebruikt dezelfde tijdelijke confirm-on-use agent als `just deploy`
voor de andere hosts. Tailscale SSH staat uit; authenticatie loopt via OpenSSH.

Eenmalig in WSL, nadat deze wijzigingen beschikbaar zijn in de lokale clone:

```sh
cd /etc/nixos-config
git pull --ff-only
sudo nixos-rebuild switch --flake .#wsl-t3
sudo tailscale up --accept-dns=false
```

Volg de login-link en voeg WSL toe aan dezelfde tailnet als de Framework. Draai
Tailscale **binnen WSL**; alleen Tailscale op Windows geeft deze host geen eigen
Tailscale-adres. De tailnet-policy moet verkeer van de Framework naar WSL op
TCP-poort 22 toestaan. `--accept-dns=false` laat de door WSL beheerde DNS intact.

Daarna op de Framework, vanuit deze repo:

```sh
ssh nh@wsl-t3
just deploy-wsl
```

Als MagicDNS de naam niet oplost, gebruik het adres uit `tailscale ip -4` in WSL:

```sh
just deploy-wsl 100.x.y.z
```

De Framework bouwt de lokale flake, kopieert de Nix-store-resultaten via SSH en
activeert de configuratie in WSL. Een Git-push of `git pull` op WSL is daarvoor
niet nodig. De repo-clone in WSL wordt hiermee niet bijgewerkt. Bevestig de
SSH-key-vragen van de tijdelijke agent op de Framework. Een update van T3 kan
lopende agenttaken onderbreken. Windows en de WSL-distro moeten actief zijn.

## Docker voor projecten

Docker Engine en Docker Compose worden op deze host door NixOS beheerd.
Gebruiker `nh` is lid van de groep `docker`, zodat T3-agents containers kunnen
bouwen en draaien. Deze groep geeft effectief roottoegang binnen WSL.

Controleer met `docker info` en `docker compose version`. Na het voor het eerst
toevoegen van de groep moeten bestaande sessies opnieuw starten om de nieuwe
groepsrechten te krijgen; dat geldt ook voor de systemd-gebruikersmanager waarin
T3 draait. Bind ontwikkelpoorten bij voorkeur expliciet aan localhost, bijvoorbeeld
`127.0.0.1:3000:3000` in Compose.
