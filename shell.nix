{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  packages = with pkgs; [
    bash
    cmake
    odin
    stdenv.cc
  ];
}
