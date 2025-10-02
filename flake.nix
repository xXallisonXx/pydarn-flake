{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        
        # Pydarn fetches hardware (hdw) files from a separate repo.
        # 
        packages.hdw = pkgs.fetchFromGitHub {
          owner = "SuperDARN";
          repo = "hdw";

          # they don't seem to make regular releases, so taking latest commit at time of writing
          # this may need to be updated.
          # alternatively, have the patch point at a local dir and keep downloading latest, but this is more reproducible (does not depend on external latest github contents which can change between time of writing a paper and someone trying to reproduce your results)
          rev = "41225eccd5b683b2f5a4ffe21a50249de9e46d02";
          hash = "sha256-3/uRY9tZmssWrltz02hftpqgOc7cCmwgsObP6d0DsqA=";
        };

        # Pydarn from PyPi
        packages.pydarn = pkgs.python3Packages.buildPythonPackage rec {
          pname = "pydarn";
          version = "4.1.1";

          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "sha256-ueSSUCZGjeQOtogR9Sd+o8x9tCxp06KRBAUtd2ZZjDA=";
          };

          # 
          postPatch = ''
            substituteInPlace pydarn/utils/superdarn_radars.py \
              --replace-warn 'hdw_path = "{}/hdw/".format(os.path.dirname(pydarn.utils.__file__))' \
                             'hdw_path = "${self'.packages.hdw}"' \
              --replace-warn "hdw_path = os.path.dirname(__file__)+'/hdw/'" \
                             'hdw_path = "${self'.packages.hdw}"'
          '';

          format = "pyproject";

          nativeBuildInputs = with pkgs.python3Packages; [
            setuptools wheel
          ];

          # From https://github.com/SuperDARN/pydarn/commit/ce32ba2e4da51f4d76230ea36fec899c0abb9b84 
          # Pydarn enforces scipy versions <1.15 because of a bug in map potential contour plots. 
          pythonRelaxDeps = [
            "scipy"
          ];

          propagatedBuildInputs = with pkgs.python3Packages; [
            numpy
            scipy
            matplotlib
            pyyaml
            self'.packages.aacgmv2
            self'.packages.pydarnio
            cartopy
          ];
        };

        # pydarnio from PyPi
        packages.pydarnio = pkgs.python3Packages.buildPythonPackage rec {
          pname = "pydarnio";
          version = "1.3";  # use latest PyPI version

          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "sha256-yObo5HqL+qlxFUscfX1GeY128ms3rw9soe4QRMhowJ4=";
          };

          format = "pyproject";

          nativeBuildInputs = with pkgs.python3Packages; [ setuptools wheel ];

          propagatedBuildInputs = with pkgs.python3Packages; [
            numpy
            pathlib2
            pyyaml
            h5py
            pip
          ];
        };

        # AACGMV2 from PyPi
        packages.aacgmv2 = pkgs.python3Packages.buildPythonPackage rec {
          pname = "aacgmv2";
          version = "2.7.0";

          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "sha256-O9rRrraq/Ra5nafRgcTcOqcpRjY8reKnYZkc0T05bmI=";
          };

          format = "pyproject";

          nativeBuildInputs = with pkgs.python3Packages; [
            setuptools
            wheel
          ];

          postPatch = ''
            substituteInPlace pyproject.toml \
              --replace "oldest-supported-numpy" "numpy"
          '';

          propagatedBuildInputs = with pkgs.python3Packages; [
            numpy
          ];
        };

        packages.py = pkgs.python3.withPackages (pp: with pp; [
          self'.packages.pydarn jupyter
        ]);

        packages.jupyter = pkgs.jupyter.withPackages (pp: with pp; [
          self'.packages.pydarn
        ]);
      };
    };
}
