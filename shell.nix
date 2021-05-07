with import <nixpkgs> {};

stdenv.mkDerivation {
  name = "minikube_contour_opa";
  buildInputs = [
    zsh-completions
    curl
    kubectx
    minikube
  ];

  shellHook = ''
    exec zsh
  '';
}
