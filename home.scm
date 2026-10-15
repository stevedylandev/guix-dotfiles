;; Guix Home configuration
(use-modules (gnu home)
             (gnu home services)
             (gnu home services shells)
             (gnu home services gnupg)
             (gnu home services xdg)
             (gnu packages)
             (gnu services)
             (gnu system shadow)
             (guix gexp))

(define %zsh-packages
  (specifications->packages
   (list "zsh"
         "zsh-autosuggestions"
         "zsh-syntax-highlighting"
         "starship" "zoxide" "fzf" "fd" "bat" "eza" "jless"
         "fastfetch" "xclip"
         "tmux" "xdg-utils"
         "gnupg" "pinentry" "password-store")))

(define %lsp-packages
  (specifications->packages
   (list "guile-lsp-server"
         "rust-analyzer"
         "gopls"
         "lua-language-server"
         "python-lsp-server")))

(define %lang-packages
  (specifications->packages
   (list "python")))

(define %theme-packages
  (specifications->packages (list "adwaita-icon-theme")))

(home-environment
 (packages (append %zsh-packages %lsp-packages %lang-packages %theme-packages))

 (services
  (append
   (list
    (service home-zsh-service-type
             (home-zsh-configuration
              (zshrc (list (local-file "zsh/zshrc")))))

    ;; pinentry uses GTK under X and falls back to curses otherwise
    (service home-gpg-agent-service-type
             (home-gpg-agent-configuration
              (pinentry-program
               (file-append (specification->package "pinentry")
                            "/bin/pinentry"))))

    (service home-files-service-type
             `((".guile" ,%default-dotguile)
               (".Xdefaults" ,%default-xdefaults)
               (".emacs.d/early-init.el" ,(local-file "emacs/early-init.el"))
               (".emacs.d/init.el" ,(local-file "emacs/init.el"))
               (".emacs.d/lisp" ,(local-file "emacs/lisp" #:recursive? #t))
               (".emacs.d/themes" ,(local-file "emacs/themes" #:recursive? #t))))

    (service home-xdg-configuration-files-service-type
             `(("starship.toml" ,(local-file "starship/starship.toml"))
               ("kitty/kitty.conf" ,(local-file "kitty/kitty.conf"))
               ("sway/config" ,(local-file "sway/config"))
               ("qtile/config.py" ,(local-file "qtile/config.py"))
               ("rofi/config.rasi" ,(local-file "rofi/config.rasi"))
               ("rofi/darkmatter.rasi" ,(local-file "rofi/darkmatter.rasi"))
               ("tmux/tmux.conf" ,(local-file "tmux/tmux.conf"))
               ("gdb/gdbinit" ,%default-gdbinit)
               ("nano/nanorc" ,%default-nanorc)))

    (simple-service 'cursor-theme home-environment-variables-service-type
                    '(("XCURSOR_THEME" . "Adwaita")
                      ("XCURSOR_SIZE" . "24")
                      ("XCURSOR_PATH" . "$HOME/.guix-home/profile/share/icons")))

    (simple-service 'cursor-default home-files-service-type
                    `((".icons/default"
                       ,(file-append (specification->package "adwaita-icon-theme")
                                     "/share/icons/Adwaita"))))

    (service home-xdg-data-files-service-type
             `(("fonts/BerkeleyMonoNerdFontMono-Regular.ttf"
                ,(local-file "fonts/BerkeleyMonoNerdFontMono-Regular.ttf")))))

   %base-home-services)))
