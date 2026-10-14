## ephemerial PostGIS

{ pkgs, ... }:
let
  # add Ukrainian dictionary
  postgresql-uk-tsearch = pkgs.runCommand "postgresql-uk-tsearch" { } ''
    mkdir -p $out/share/postgresql/tsearch_data
    ln -s ${pkgs.hunspellDicts.uk_UA}/share/hunspell/uk_UA.aff \
          $out/share/postgresql/tsearch_data/uk_ua.affix
    ln -s ${pkgs.hunspellDicts.uk_UA}/share/hunspell/uk_UA.dic \
          $out/share/postgresql/tsearch_data/uk_ua.dict
  '';
in

{
  environment.variables = {
    DATABASE_URL = "postgresql://admin:qwerty123@0.0.0.0:5432/test";
  };

  environment.systemPackages = with pkgs; [
    hunspellDicts.uk_UA
  ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;

    settings = {
      listen_addresses = "*";
    };

    # allow network loopback (127.0.0.1) connections
    enableTCPIP = true;
    extensions = [
      pkgs.postgresql18Packages.postgis
      pkgs.postgresql18Packages.pgvector
      postgresql-uk-tsearch
    ];

    ensureDatabases = [ "test" ];

    authentication = pkgs.lib.mkOverride 10 ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             all                                     trust
      
      # IPv4 local connections:
      host    all             all             127.0.0.1/32            trust

      # Connection from QEMU host:
      host    all             all             10.0.2.0/24     scram-sha-256
    '';

    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE DATABASE test;
      CREATE USER admin WITH PASSWORD 'qwerty123';
      GRANT ALL PRIVILEGES ON DATABASE test TO admin;

      \c test
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
      CREATE EXTENSION IF NOT EXISTS postgis;
      CREATE EXTENSION IF NOT EXISTS vector;
      CREATE EXTENSION IF NOT EXISTS pg_trgm;
      GRANT ALL ON SCHEMA public TO admin;
    '';
  };
}
