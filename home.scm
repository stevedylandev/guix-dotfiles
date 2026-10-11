;; Guix Home configuration for stevedylandev.
;; Apply with: guix home reconfigure ~/guix-dotfiles/home.scm
(use-modules (gnu home)
             (gnu home services)
             (gnu home services shells)
             (gnu packages)
             (gnu services)
             (gnu system shadow)
             (guix gexp))

(define %zsh-packages
  (specifications->packages
   (list "zsh"
         "zsh-autosuggestions"
         "zsh-syntax-highlighting"
         ;; tools the zshrc aliases/functions/init rely on
         "starship" "zoxide" "fzf" "fd" "bat" "eza" "jless"
         "neovim" "fastfetch" "xclip")))

(home-environment
  (packages %zsh-packages)

  (services
   (append
    (list
     (service home-zsh-service-type
              (home-zsh-configuration
               (zshrc (list (local-file "zsh/zshrc")))))

     (service home-files-service-type
              `((".guile" ,%default-dotguile)
                (".Xdefaults" ,%default-xdefaults)))

     (service home-xdg-configuration-files-service-type
              `(("starship.toml" ,(local-file "starship/starship.toml"))
                ("gdb/gdbinit" ,%default-gdbinit)
                ("nano/nanorc" ,%default-nanorc))))

    %base-home-services)))
