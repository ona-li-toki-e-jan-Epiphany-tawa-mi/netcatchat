# This file is part of netcatchat.
#
# Copyright (c) 2024 ona-li-toki-e-jan-Epiphany-tawa-mi
#
# netcatchat is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# netcatchat is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# netcatchat. If not, see <https://www.gnu.org/licenses/>.

{
  description = "netcatchat development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;

      forAllSystems = f:
        lib.genAttrs lib.systems.flakeExposed
        (system: f { pkgs = import nixpkgs { inherit system; }; });

    in {
      devShells = forAllSystems ({ pkgs }: {
        default = with pkgs;
          mkShell {
            packages = [
              netcat-openbsd

              shellcheck
            ];
          };
      });
    };
}
