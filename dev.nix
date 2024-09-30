{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.python3
    pkgs.python3Packages.flask
    pkgs.python3Packages.flask-sqlalchemy  # Flask-SQLAlchemy
    pkgs.python3Packages.flask-migrate     # Added Flask-Migrate
    pkgs.python3Packages.flask-mysqldb
    pkgs.python3Packages.mysqlclient
    pkgs.python3Packages.flask-cors         # Flask-CORS
    pkgs.pkg-config  # Ensure pkg-config is included
    pkgs.mysql  # Include MySQL client libraries
    pkgs.mariadb  # Include MariaDB client libraries (if needed)
    pkgs.sudo  # Add sudo here
    # Add any other dependencies you may need
  ];
}
