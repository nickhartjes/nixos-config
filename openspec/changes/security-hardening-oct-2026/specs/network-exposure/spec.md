## Purpose

Defines which services a host may expose beyond loopback. Container port publishing and SSH on VMs and install images must not open a path the host firewall doesn't control.

## ADDED Requirements

### Requirement: Published container ports are not reachable from the LAN
On every host with the rootful docker component, the host firewall SHALL drop new inbound connections to published container ports that arrive on a physical interface, whatever the port mapping says. Traffic from container bridges, loopback and the tailnet, as well as replies to outbound connections, SHALL pass.

#### Scenario: Compose port without IP
- **WHEN** a compose file publishes `"9222:9222"` on velomo-alpha and a LAN client connects to `10.0.60.132:9222`
- **THEN** the connection times out

#### Scenario: Explicit tailnet bind still works
- **WHEN** a service publishes `"100.x.y.z:3300:3000"` and a tailnet peer connects to it
- **THEN** the connection succeeds

#### Scenario: Outbound container traffic
- **WHEN** a container opens an outbound connection (for example the cloudflared tunnel or an image pull)
- **THEN** it succeeds, and the public sites behind the tunnel keep loading

### Requirement: Container bridges are not trusted interfaces
The host firewall SHALL NOT trust Docker bridge interfaces (`docker0`, `br-*`) as a whole. A host port that containers need SHALL be opened for that interface explicitly.

#### Scenario: Container probes host ports
- **WHEN** a container on a user-defined bridge connects to a host port that isn't opened for that bridge
- **THEN** the firewall drops the connection

### Requirement: VMs and install images use key-only SSH
vm-blackhawk, vm-desktop and both installation images SHALL disable SSH password and keyboard-interactive authentication. They SHALL NOT permit root password login and SHALL NOT ship a known user password.

#### Scenario: Password login attempt on a VM
- **WHEN** a client runs `ssh -o PubkeyAuthentication=no nh@vm-blackhawk`
- **THEN** the server offers no password method and the login fails

#### Scenario: Booted install image
- **WHEN** an install image built from `installation/` boots on a network
- **THEN** only the configured operator keys can log in over SSH, and `nixos`/`nixos` is rejected
