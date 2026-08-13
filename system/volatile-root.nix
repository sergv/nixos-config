{
  impermanence
}:
{
  ...
}:
{
  imports = [ impermanence.nixosModules.impermanence ];

  environment.persistence."/permanent" = {
    hideMounts = true;

    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/lib"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };

  home-manager.users.sergey = {
    imports = [ ../home/volatile-home.nix ];
  };

}
