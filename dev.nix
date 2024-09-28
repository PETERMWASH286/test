{ pkgs ? import <nixpkgs> {} }:
{
  # Add your other packages here
  packages = with pkgs; [
    python3
    python3Packages.flask
    python3Packages.flask-sqlalchemy
    # Add any other dependencies you may need
  ];
}
