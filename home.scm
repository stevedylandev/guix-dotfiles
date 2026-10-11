;; Guix Home configuration for stevedylandev.
;; Apply with: guix home reconfigure ~/guix-dotfiles/home.scm
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
         ;; tools the zshrc aliases/functions/init rely on
         "starship" "zoxide" "fzf" "fd" "bat" "eza" "jless"
         "fastfetch" "xclip"
         ;; encryption and password management
         "gnupg" "pinentry" "password-store")))

(home-environment
  (packages %zsh-packages)

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
                ;; Emacs config files are linked into ~/.emacs.d so that
                ;; elpa/ and other runtime state stay writable there.
                (".emacs.d/early-init.el" ,(local-file "emacs/early-init.el"))
                (".emacs.d/init.el" ,(local-file "emacs/init.el"))
                (".emacs.d/org.css" ,(local-file "emacs/org.css"))
                (".emacs.d/lisp" ,(local-file "emacs/lisp" #:recursive? #t))
                (".emacs.d/themes" ,(local-file "emacs/themes" #:recursive? #t))))

     (service home-xdg-configuration-files-service-type
              `(("starship.toml" ,(local-file "starship/starship.toml"))
                ("gdb/gdbinit" ,%default-gdbinit)
                ("nano/nanorc" ,%default-nanorc)))

     ;; ~/.local/share/fonts is on fontconfig's default search path
     (service home-xdg-data-files-service-type
              `(("fonts/BerkeleyMonoNerdFontMono-Regular.ttf"
                 ,(local-file "fonts/BerkeleyMonoNerdFontMono-Regular.ttf")))))

    %base-home-services)))
