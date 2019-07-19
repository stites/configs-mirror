{
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      italic-text = "never";

      # Show line numbers, Git modifications and file header (but no grid)
      style = "numbers,changes,header,grid";

      # Add mouse scrolling support in less (does not work with older
      # versions of "less").
      pager = "less -FR";

      # Use C++ syntax (instead of C) for .h header files
      "map-syntax" = "h:cpp";

      # Use "gitignore" highlighting for ".ignore" files
      # "map-syntax" = ".ignore:.gitignore";
    };
  };
}