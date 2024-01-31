# Some common functions for my devshell cmds
{ pkgs, lib, ... }:
{
  /* Builds a derivation and then turns its main executable into a string.

     Used for devshell commands
  */
  commandBuildHelper = attrset: builtins.readFile (lib.getExe (pkgs.writeShellApplication attrset));
  # Constructs a devShell command for a provided category. Prefixes the command and supplies category.
  mkCommandCategory =
    category:
    {
      help,
      name,
      command,
    }:
    {
      name = "${category}-${name}";
      inherit help command category;
    };
}
