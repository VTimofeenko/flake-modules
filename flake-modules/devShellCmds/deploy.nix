# Produces deployment commands
{
  deploymentConfig,
  deploy-rs,
  pkgs,
  lib,
  system,
  self,
  ...
}:
let
  inherit (deploymentConfig)
    enable
    useDeployRs
    localDeployment
    desktopNotifications
    ;

  inherit (import ./lib.nix { inherit pkgs lib; }) mkCommandCategory;

  notifySendCmd = lib.getExe' pkgs.libnotify "notify-send";
  mkCmd =
    machineName:
    (
      if useDeployRs then
        "${lib.getExe' deploy-rs.packages.${system}.default "deploy"} -s \${PRJ_ROOT}#${machineName} $@"
      else
        "nixos-rebuild --flake \${PRJ_ROOT}#${machineName} --target-host root@${machineName}.home.arpa switch"
    )
    + (lib.optionalString desktopNotifications " && ${notifySendCmd} '${machineName} deployed' -i object-select || ${notifySendCmd} '${machineName} deployment failed' -i window-close");
  machines =
    if useDeployRs then
      (self.deploy.nodes or (lib.warn "No deploy.nodes specified in the flake.nix, using empty set" { }))
    else
      self.nixosConfigurations;
in
map (mkCommandCategory "deploy") (
  if enable then
    (map (machineName: {
      help = "Deploy remote ${machineName}";
      name = "${machineName}"; # 'deploy-' prefix will be added automatically
      command = mkCmd machineName;
    }) (builtins.attrNames machines))
    ++ (
      if localDeployment then
        [
          {
            help = "Deploy the flake on this machine";
            name = "local";
            command =
              # bash
              ''
                set -euo pipefail

                if [[ $(grep -s ^NAME= /etc/os-release | sed 's/^.*=//') == "NixOS" ]]; then
                  sudo nixos-rebuild switch --flake ''${PRJ_ROOT} # PRJ_ROOT is set <=> we're in direnv. Prevents extra warnings
                else # Not a NixOS machine
                  home-manager switch --flake ''${PRJ_ROOT}
                fi

                ${if desktopNotifications then "${notifySendCmd} 'local deployment done' -i object-select" else ""}
              '';
          }
        ]
      else
        [ ]
    )
  else
    [ ]
)
