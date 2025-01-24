let
  pkgs = import <nixpkgs> {};
in
pkgs.mkShell {
  packages = [
    pkgs.nasm
    pkgs.nasmfmt
    pkgs.gdb
  ];
}
