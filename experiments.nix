{ pkgs, lib, ... }:
{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      # Don't print a new line at the start of the prompt
      "add_newline" = false;

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
        disabled = true;
      };

      git_branch = {
        prefix = "";
        symbol = "🍂";
        truncation_length = "4";
      };
    };
  };
}
