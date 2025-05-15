{
  containers.httpd = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";
    forwardPorts = [
      {
        containerPort = 80;
        hostPort = 80;
      }
    ];
    config = {...}: {
      services.httpd = {
        enable = true;
        adminAddr = "foo@example.org";
      };
      networking.firewall.allowedTCPPorts = [80];
      system.stateVersion = "24.05";
    };
    bindMounts = {
      "/root/data" = {
        hostPath = "/home/m3tam3re/data/";
        isReadOnly = false;
      };
    };
  };
  containers.httpd2 = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.12";
    forwardPorts = [
      {
        containerPort = 80;
        hostPort = 8080;
      }
    ];
    config = {...}: {
      services.httpd = {
        enable = true;
        adminAddr = "foo@example.org";
      };
      networking.firewall.allowedTCPPorts = [80];
      system.stateVersion = "24.05";
    };
    bindMounts = {
      "/root/data" = {
        hostPath = "/home/m3tam3re/data/";
        isReadOnly = false;
      };
    };
  };
}
