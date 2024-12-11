{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.python3
    pkgs.python3Packages.flask
    pkgs.python3Packages.flask-sqlalchemy
    pkgs.python3Packages.flask-migrate
    pkgs.python3Packages.flask-mysqldb
    pkgs.python3Packages.mysqlclient
    pkgs.python3Packages.flask-cors
    pkgs.pkg-config
    pkgs.mysql
    pkgs.mariadb
    pkgs.sudo
    pkgs.openssh  # Add openssh to include scp
  ];
}
