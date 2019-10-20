{ pkgs, lib, ... }:
{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      # Don't print a new line at the start of the prompt
      add_newline = false;

      # Replace the "❯" symbol in the prompt with "➜"
      character = {  # The name of the module we are configuring is "character"
        symbol = "❯";     # The "symbol" segment is being set to "➜"
      };

      python = {
        prefix = "";
        suffix = "";
        style = "bold green";
      };

      cmd_duration = {
        min_time = 1;
        disabled = true;
      };

      line_break = {
        disabled = false; # until the git-status is fixed
      };

      git_branch = {
        prefix = "";
        symbol = "";
        truncation_length = 10;
      };
    };
  };
}


# [git_status]
# conflicted = "x"
# ahead = "^"
# behind = "v"
# diverged = "%"
# untracked = "u"
# stashed = "s"
# modified = "m"
# staged = "*"
# renamed = "r"
# deleted = "_"
# # prefix = "["  # Prefix to display immediately before git status.
# # suffix = "]"  # Suffix to display immediately after git status.
# style = "bold red" # The style for the module.
