# TODO: use process-compose-services flake utilizing nixos modules

{ inputs, ... }: {
  perSystem = {config, system, pkgs, lib, ...}: {
    process-compose."default" =
      {
        # httpServer.enable = true;
        settings = {
          #environment = {
          #};

          processes = {
            # shared across single and multiplayer
            # TODO: confirm can share same hydra instance
            hydra-offline = {
              command = config.packages.hydra-offline-wrapper;
              readiness_probe = {
                http_get = {
                  host = "127.0.0.1";
                  scheme = "http";
                  port = 4001;
                  path = "/protocol-parameters";
                };
              };
            };
            # multiplayer processes
            hydra-doom = {
              command = config.packages.hydra-doom-wrapper;
              availability = {
                restart = "on_failure";
                backoff_seconds = 2;
              };
            };
            hydra-control-plane = {
              command = config.packages.hydra-control-plane-wrapper;
              readiness_probe = {
                http_get = {
                  host = "127.0.0.1";
                  scheme = "http";
                  port = 8001;
                  path = "/global";
                };
              };
              depends_on."hydra-offline".condition = "process_healthy";
              availability = {
                restart = "on_failure";
                backoff_seconds = 2;
              };
            };
            # single player processes
            hydra-doom-single = {
              command = config.packages.hydra-doom-wrapper-single;
              availability = {
                restart = "on_failure";
                backoff_seconds = 2;
              };
            };
            hydra-control-plane-single = {
              command = config.packages.hydra-control-plane-wrapper-single;
              readiness_probe = {
                http_get = {
                  host = "127.0.0.1";
                  scheme = "http";
                  port = 8000;
                  path = "/global";
                };
              };
              depends_on."hydra-offline".condition = "process_healthy";
              availability = {
                restart = "on_failure";
                backoff_seconds = 2;
              };
            };
          };
        };
      };
    };
}
