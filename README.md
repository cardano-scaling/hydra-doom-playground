# Hydra Doom Playground

Experiment of running Doom using a [Cardano Hydra head](https://github.com/cardano-scaling/hydra).

This provides:

* process-compose application that runs entire stack locally
* USB iso image with all services running at startup
* colmena deployments for IO Engineering managed official deployments

## Direnv integration

Use `direnv allow` to provide a shell with all necessary tools for deployment

## Process Compose

``` shell
nix run
```
## USB ISO Image

The kiosk-boot provides a simple way to distribute the game to others.

``` shell
nix build .#nixosConfigurations.kiosk-boot.config.system.build.isoImage
```

## Deployment

Deployments are done using `colmena` and `just` commands.

Apply will decrypt the cabinet key temporarily during deployment and remove
the unencrypted key at completion.

``` shell
just apply <HOSTNAME>
```
