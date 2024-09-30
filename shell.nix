{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.python3
    pkgs.python3Packages.flask
    pkgs.python3Packages.flask-mysqldb
    pkgs.python3Packages.mysqlclient
    pkgs.pkg-config
    pkgs.mysql
    pkgs.mariadb
    pkgs.sudo  # Add sudo here
  ];
}

