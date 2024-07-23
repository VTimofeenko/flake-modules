{
  # flake-parts-lib,
  # lib,
  src,
  withSystem,
  self,
  ...
}:
_: {
  config.perSystem =
    { system, ... }:
    {
      packages = withSystem system (
        { pkgs, ... }:
        {
          /*
            Simple wrapper around
            https://codeberg.org/ideasman42/emacs-elisp-autofmt
          */
          emacs-elisp-autofmt = pkgs.writeShellApplication {
            name = "emacs-elisp-autofmt";
            runtimeInputs = [ pkgs.python3 ];
            text = ''
              python3 ${src}/elisp-autofmt.py "$@"
            '';
          };
        }
      );
      checks = withSystem system (
        { pkgs, ... }:
        {
          test-elisp-formatter =
            pkgs.runCommandLocal "test-elisp-formatter"
              {
                src = ./.;
                nativeBuildInputs = [
                  self.packages.${pkgs.system}.emacs-elisp-autofmt
                  pkgs.coreutils-full
                ];
              }
              ''
                set -x
                ORIG_MD5=$(emacs-elisp-autofmt --fmt-style fixed --stdout $src/check/orig.el | md5sum | cut -d ' ' -f 1)
                TARGET_MD5=$(md5sum $src/check/target.el | cut -d ' ' -f 1)
                if [ "$ORIG_MD5" != "$TARGET_MD5" ]; then
                  echo "md5sum does not match"
                  exit 1
                fi

                mkdir $out
                exit 0
              '';
        }
      );
    };
}
