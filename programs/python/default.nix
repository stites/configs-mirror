{ pkgs, lib, ... }:
let
  install-python = true;
in
{
  imports = [
    ./jupyter.nix
    ./ipython.nix
  ];
  home.packages = lib.optionals install-python [
    (let
      dontCheck = pypkg: pypkg.overridePythonAttrs (old: {
        doCheck = false; checkPhase = "true";
      });

      # jupyter = import (builtins.fetchGit {
      #   url = https://github.com/tweag/jupyterWith;
      #   rev = "02b929122d49189a896c9fae044c12db21846f25";
      # }) {};

      # jupyterEnvironment =
      #   jupyter.jupyterlabWith { kernels = [
      #     (jupyter.kernels.iPythonWith {
      #       name = "python";
      #       packages = p: with p; [ numpy
      #         nose (dontCheck celery) mock flake8 pygments          # testing
      #         hypothesis pytest pytest-mypy             # testing
      #         numpy # compute storage
      #         beautifulsoup4 requests                         # web processing
      #         # pandas # numba (dontCheck pyarrow) h5py                       # compute storage
      #         ipython notebook ipywidgets jupyter             # notebooks
      #         matplotlib seaborn tensorflow-tensorboard       # visualization
      #         scikitlearn scipy                               # statistics and ML
      #         pillow (dontCheck imageio) # pycv (not in nixpkgs) # CV
      #         nltk gensim                                     # NLP
      #         # # pymc3            # <<< TOTALLY BROKEN           # PPLs
      #         # pytorch-world.pytorch # mypytorch mytorchvision probtorch pyro-ppl    # future
      #       ];
      #     })
      #     (jupyter.kernels.iHaskellWith {
      #       name = "haskell";
      #       packages = p: with p; [ hvega formatting ];
      #     })
      #   ]; };

      # python36 = pkgs.python36.override {
      #   packageOverrides = pself: psuper: {
      #     matplotlib  = dontCheck (psuper.matplotlib.override { enableQt = true; });
      #     scipy = dontCheck psuper.scipy;
      #     beautifulsoup4 = dontCheck psuper.beautifulsoup4;
      #   };
      #   self = python36;
      # };

      mypython36 = pkgs.python3.withPackages (ps: with ps; [
        # dev packages
        mccabe mypy nose pycodestyle pydocstyle
        jedi flake8 pygments pytest-mypy pyls-isort pyls-mypy pyflakes yapf black pylint
        typeguard

        beautifulsoup4 requests                         # web processing
        ipython notebook ipywidgets jupyter             # notebooks
        pandas numba pyarrow h5py numpy                 # compute storage
        matplotlib seaborn tensorflow-tensorboard       # visualization

        nose celery mock flake8 pygments     # testing
        hypothesis pytest pytest-mypy        # testing

      ] ++ map dontCheck [
        # scikitlearn scipy                               # statistics and ML
        # pillow imageio # pycv (not in nixpkgs) # CV
        # nltk gensim                                     # NLP
        # # pymc3            # <<< TOTALLY BROKEN           # PPLs
        # pytorch-world.pytorch # mypytorch mytorchvision probtorch pyro-ppl    # future

      ]);
      specificExes = pkgs.stdenv.mkDerivation {
        name = "my-python-executables";
        buildPhase = "";
        buildInputs = [ pkgs.makeWrapper ];
        # propagatedBuildInputs = [ jupyterEnvironment ];
        propagatedBuildInputs = [ mypython36 ];
        src = ./.;
        installPhase = let
          wrapAndKeep = bin: new: flags:
            (wrapPyBin bin new flags) + "\n" + (keepPyBin bin);

          wrapPyBin = bin: new: flags:
            "makeWrapper ${mypython36}/bin/${bin} $out/bin/${new} "
            + (if flags != "" then "--add-flags \"${flags}\"" else "");

          keepPyBin = bin: "cp ${mypython36}/bin/${bin} $out/bin/${bin}";
          in lib.strings.concatStringsSep "\n" [
            "mkdir -p $out/bin"
            "${wrapAndKeep  "python"          "py"      ""}"
            "${wrapAndKeep "ipython"          "ipy" "--profile=default"}"
            "${wrapAndKeep "jupyter"          "jp"  ""}"
            "${wrapAndKeep "jupyter-notebook" "nb"  ""}"
            "${wrapAndKeep "tensorboard"      "tb"  ""}"
            "${keepPyBin "flake8"}"
            "${keepPyBin "black"}"
            "${keepPyBin "pytest"}"
            "${keepPyBin "mypy"}"
            "${keepPyBin "pylint"}"
          ];
      };
    in specificExes)
  ];
}
