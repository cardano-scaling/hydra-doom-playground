{ inputs, ... }: {
  perSystem = {config, system, pkgs, lib, ...}:
    let
      hydraDataDir = "state-hydra";
      # edit these to override defaults for serverUrl and doom wad file
      controlPlaneListenAddr = "0.0.0.0";
      controlPlaneHost = "localhost";
      controlPlanePort = "8000";
      controlPlaneUrl = "http://${controlPlaneHost}:${controlPlanePort}";
      hydraHost = "localhost";
      hydraPort = "4001";
      doomWad = pkgs.fetchurl {
        url = "https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad";
        sha256 = "sha256-HX1DvlAeZ9kn5BXguPPinDvzMHXoWXIYFvZSpSbKx3E=";
      };
      hydra-doom-static-single = let
        serverUrl = controlPlaneUrl;
        wadFile = doomWad;
        cabinetKey = null;
        region = "local";
        useMouse = "1";
        src = inputs.hydra-doom-single;
        nodeModules = pkgs.mkYarnPackage {
          name = "hydra-doom-node-modules";
          inherit src;
          packageJSON = src + "/package.json";
          yarnLock = src + "/yarn.lock";
          nodejs = pkgs.nodejs;
         };

        in
        pkgs.stdenv.mkDerivation (finalAttrs: {
          name = "hydra-doom-static";
          phases = [ "unpackPhase" "buildPhase" "installPhase" ];
          inherit src;
          passthru = { inherit serverUrl wadFile cabinetKey useMouse region; };
          buildInputs = [
            pkgs.nodejs
            pkgs.yarn
            nodeModules
          ];
          buildPhase = ''
            ln -s ${nodeModules}/libexec/hydra-doom/node_modules node_modules
            ln -sf ${finalAttrs.passthru.wadFile} assets/doom1.wad
            cat > .env << EOF
            SERVER_URL=${finalAttrs.passthru.serverUrl}
            ${lib.optionalString (finalAttrs.passthru.cabinetKey != null) "CABINET_KEY=${finalAttrs.passthru.cabinetKey}"}
            REGION=${finalAttrs.passthru.region}
            EOF
            yarn build
            sed -i "s/use_mouse.*/use_mouse                     ${finalAttrs.passthru.useMouse}/" dist/default.cfg
          '';
          installPhase = ''
            cp -a dist $out
          '';
        });
    in
    {
      packages = {
        inherit hydra-doom-static-single;
        hydra-doom-wrapper-single = pkgs.writeShellApplication {
          name = "hydra-doom-wrapper-single";
          runtimeInputs = [ config.packages.bech32 pkgs.jq pkgs.git pkgs.nodejs pkgs.python3 ];
          text = ''
            export STATIC="''${STATIC:-1}"
            if [ "''${STATIC}" -eq 0 ]; then
              echo "running npm..."
              npm install
              npm start
            else
              echo "running http webserver for local play at http://localhost:3000..."
              pushd ${config.packages.hydra-doom-static-single}
              python3 -m http.server 3000
            fi
          '';
        };
        hydra-control-plane-wrapper-single = pkgs.writeShellApplication {
          name = "hydra-control-plane-wrapper-single";
          text = ''
            mkdir -p single
            pushd single
            export RESERVED="''${RESERVED:-false}"
            export PRESERVE_ROCKET_TOML="''${PRESERVE_ROCKET_TOML:-0}"
            export ROCKET_PROFILE=local
            if [ "$PRESERVE_ROCKET_TOML" -eq 0 ]
            then
            cat > Rocket.toml << EOF
            [default]
            ttl_minutes = 5
            port = ${controlPlanePort}
            address = "${controlPlaneListenAddr}"

            [[local.nodes]]
            local_url = "ws://${hydraHost}"
            remote_url = "ws://${hydraHost}"
            port = ${hydraPort}
            max_players = 100
            admin_key_file = "../admin.sk"
            persisted = false
            reserved = ''${RESERVED}
            region = "local"
            stats-file = "local-stats"
            EOF
            fi
            ${lib.getExe' config.packages.hydra-control-plane-single "hydra_control_plane"}
          '';
        };
      };
    };
}
