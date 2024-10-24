{ inputs, ... }: {
  perSystem = {config, system, pkgs, lib, ...}:
    let
      hydraDataDir = "state-hydra";
    in
    {
      packages = {
        hydra-cluster-wrapper = pkgs.writeShellApplication {
          name = "hydra-cluster-wrapper";
          runtimeInputs = [ config.packages.cardano-node config.packages.cardano-cli ];
          text = ''
            rm -rf "${hydraDataDir}"
            ${lib.getExe' config.packages.hydra-cluster "hydra-cluster"} --devnet --publish-hydra-scripts --state-directory ${hydraDataDir}
          '';
        };
        hydra-offline-wrapper = pkgs.writeShellApplication {
          name = "hydra-offline-wrapper";
          runtimeInputs = [ config.packages.cardano-node config.packages.cardano-cli pkgs.jq pkgs.curl ];
          text = ''
            rm -rf "${hydraDataDir}"
            mkdir -p "${hydraDataDir}"
            cardano-cli address key-gen --normal-key --verification-key-file admin.vk --signing-key-file admin.sk
            pushd ${hydraDataDir}
            ${lib.getExe' config.packages.hydra-node "hydra-node"} gen-hydra-key --output-file hydra
            cp ${../../initial-utxo.json} utxo.json
            cp ${../../pparams.json} protocol-parameters.json
            chmod 0644 utxo.json protocol-parameters.json
            sed -i "s/YOURADDRESSHERE/$(cardano-cli address build --verification-key-file ../admin.vk --testnet-magic 1)/g" utxo.json
            ${lib.getExe' config.packages.hydra-node "hydra-node"} offline \
              --hydra-signing-key hydra.sk \
              --ledger-protocol-parameters protocol-parameters.json \
              --host 0.0.0.0 \
              --api-host 0.0.0.0 \
              --initial-utxo utxo.json
            popd
          '';
        };
      };
    };
}
