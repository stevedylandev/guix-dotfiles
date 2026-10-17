;; Guix Home configuration
(use-modules (gnu home)
             (gnu home services)
             (gnu home services shells)
             (gnu home services gnupg)
             (gnu home services xdg)
             (gnu home services sound)
             (gnu packages)
             (gnu packages guile)
             (gnu services)
             (gnu system shadow)
             (guix gexp)
             (guix packages))

(define %zsh-packages
  (specifications->packages
   (list "zsh"
         "zsh-autosuggestions"
         "zsh-syntax-highlighting"
         "starship" "zoxide" "fzf" "fd" "bat" "eza" "jless"
         "fastfetch" "xclip"
         "tmux" "xdg-utils"
         "gnupg" "pinentry" "password-store")))

(define guile-lsp-server/latest
  (let ((base (specification->package "guile-lsp-server")))
    (package
     (inherit base)
     (native-inputs (modify-inputs (package-native-inputs base)
                                   (replace "guile" guile-3.0-latest)))
     (propagated-inputs (modify-inputs (package-propagated-inputs base)
                                       (replace "guile" guile-3.0-latest))))))

(define %lsp-packages
  (cons guile-lsp-server/latest
        (specifications->packages
         (list "rust-analyzer"
               "gopls"
               "lua-language-server"
               "python-lsp-server"))))

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
               ("fastfetch/config.jsonc", (local-file "fastfetch/config.jsonc"))
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
                ,(local-file "fonts/BerkeleyMonoNerdFontMono-Regular.ttf"))
               ("color-schemes/Darkmatter.colors" ,(local-file "kde/Darkmatter.colors"))
               ("plasma/desktoptheme/darkmatter/metadata.json"
                ,(local-file "kde/desktoptheme/darkmatter/metadata.json"))
               ("plasma/desktoptheme/darkmatter/plasmarc"
                ,(local-file "kde/desktoptheme/darkmatter/plasmarc"))
               ("plasma/desktoptheme/darkmatter/colors"
                ,(local-file "kde/Darkmatter.colors" "darkmatter-plasma-colors"))
               ("plasma/look-and-feel/dev.stevedylan.darkmatter"
                ,(local-file "kde/look-and-feel/dev.stevedylan.darkmatter" #:recursive? #t))
               ("konsole/Darkmatter.colorscheme" ,(local-file "kde/konsole/Darkmatter.colorscheme"))
               ("konsole/Darkmatter.profile" ,(local-file "kde/konsole/Darkmatter.profile")))))

   %base-home-services)))
