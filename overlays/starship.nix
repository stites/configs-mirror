self: super:
let
  starship-25-pr = super.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "f21be15a84d81eabc6d06e1cea093cb8894aced1";
    sha256 = "0dffy3y6x6an6y2s99rp5a53x6jw3paxx2w1fcfgkj94fnbl3cx1";
  };
in
{
  starship = (import starship-25-pr {}).starship;
}
