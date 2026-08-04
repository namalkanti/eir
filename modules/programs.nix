{ pkgs, ... }:

let
  # powerlevel10k structured for oh-my-zsh's custom themes directory
  p10kCustom = pkgs.runCommand "p10k-ohmyzsh-custom" {} ''
    mkdir -p $out/themes
    ln -s ${pkgs.zsh-powerlevel10k}/share/zsh/themes/powerlevel10k $out/themes/powerlevel10k
  '';
in

{
  # zsh + oh-my-zsh
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "powerlevel10k/powerlevel10k";
      custom = "${p10kCustom}";
      plugins = [
        "docker"
        "colored-man-pages"
        "colorize"
        "command-not-found"
        "git"
        "history-substring-search"
        "python"
        "sudo"
        "z"
      ];
    };
  };

  # tmux with pre-installed plugins
  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      open
    ];
    extraConfig = ''
      set -g status-style "bg=#24273A,fg=#c6d0f5"
      set -g status-left "#[fg=#24273A,bg=#8caaee,bold] #S #[default] "
      set -g status-right "#[fg=#ca9ee6,bg=#303446] #{s|^$HOME|~|:pane_current_path} "
      set -g window-status-current-format "#[fg=#24273A,bg=#8caaee,bold] #I:#W "
      set -g window-status-format "#[fg=#c6d0f5,bg=#24273A] #I:#W "
    '';
  };

  # Neovim configuration via system module
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    configure = {
      packages.eir.start = with pkgs.vimPlugins; [
        rose-pine
        lightline-vim
        fzf-vim
        nvim-rg
        vim-fugitive
        vim-unimpaired
        vim-surround
        vim-commentary
        vim-eunuch
        vim-sexp-mappings-for-regular-people
        tabular
        rust-vim
        typescript-vim
        vim-clojure-static
        nvim-lspconfig
      ];
    };
  };
}
