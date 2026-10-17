## ephemerial S3 garage
{ pkgs, ... }:
let
  s3key_access = "GK112233445566778899aabbcc";
  s3key_secret = "aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899";
  s3endpoint = "127.0.0.1:3900";

  init_garage = pkgs.writeShellScriptBin "init_garage" ''
    print_green() {
      echo -e "\n\e[32m$1\e[0m"
    }

    print_green "=== ephemerial garage ==="
    # garage status outputs a unique 16-character hexadecimal Node ID.
    status=$(sudo garage status | grep -oE '^[0-9a-f]{16}')
    # layout assign flag binds that ID as an active single-node storage node
    sudo garage layout assign -z local -c 1G $status
    sudo garage layout apply --version 1

    sudo garage bucket create input
    sudo garage bucket create output

    sudo garage key import ${s3key_access} ${s3key_secret} --yes
    sudo garage bucket allow input --key ${s3key_access} --read --write
    sudo garage bucket allow output --key ${s3key_access} --read --write
  '';
in

{
  environment.variables = {
    S3_ACCESS_KEY = s3key_access;
    S3_SECRET_KEY = s3key_secret;
    S3_ENDPOINT = "http://${s3endpoint}";
  };

  environment.systemPackages = with pkgs; [
    init_garage
  ];

  services.garage = {
    enable = true;
    package = pkgs.garage;

    settings = {
      replication_mode = "none";
      metadata_dir = "/var/lib/garage/meta";
      data_dir = "/var/lib/garage/data";

      rpc_bind_addr = "127.0.0.1:3901";
      rpc_secret = "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff";

      s3_api = {
        # Bind to all interfaces inside the microVM container
        api_bind_addr = s3endpoint;
        root_domain = ".s3.garage.localhost";
        s3_region = "us-east-1";
      };
    };
  };
}
