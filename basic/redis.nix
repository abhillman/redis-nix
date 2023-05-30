{ pkgs ? import <nixpkgs> {} }:

with pkgs;
let
  entrypoint = writeScript "entrypoint.sh" ''
    #!${stdenv.shell}
    set -e
    # allow the container to be started with `--user`
    if [ "$1" = "redis-server" -a "$(${coreutils}/bin/id -u)" = "0" ]; then
      chown -R redis .
      exec ${pkgs.gosu}/bin/gosu redis "$BASH_SOURCE" "$@"
    fi
    exec "$@"
  '';
in
dockerTools.buildImage {
  name = "redis";
  runAsRoot = ''
    #!${stdenv.shell}
    ${dockerTools.shadowSetup}
    groupadd -r redis
    useradd -r -g redis -d /data -M redis
    mkdir /data
    chown redis:redis /data
  '';

  copyToRoot = [ redis gosu ];

  config = {
    Cmd = [ "redis-server" ];
    Entrypoint = [ entrypoint ];
    ExposedPorts = {
      "6379/tcp" = {};
    };
    WorkingDir = "/data";
    Volumes = {
      "/data" = {};
    };
  };
}
