(use-modules (gnu) (gnu system nss) (guix gexp) (rosenthal services networking))
(use-service-modules desktop xorg networking ssh docker dbus shepherd)
(use-package-modules bootloaders wm window-management text-editors fonts
                     terminals version-control ncurses gnuzilla xdisorg admin
                     xorg compton lxde ssh golang docker containers rsync emacs base
                     shells)

(operating-system
  (host-name "benson")
  (timezone "America/New_York")
  (locale "en_US.utf8")

  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets '("/boot/efi"))))

  (file-systems (append
                 (list (file-system
                         (device "/dev/nvme0n1p3")
                         (mount-point "/")
                         (type "ext4"))
                       (file-system
                         (device "/dev/nvme0n1p1")
                         (mount-point "/boot/efi")
                         (type "vfat")))
                 %base-file-systems))

  (swap-devices (list (swap-space
                        (target (uuid "10676fa5-e5a0-43b8-8316-e254ea56629e")))))

  (users (cons (user-account
                (name "stevedylandev")
                (group "users")
                (shell (file-append zsh "/bin/zsh"))
                ;; "docker" lets you run docker without sudo
                (supplementary-groups '("wheel" "netdev" "audio" "video" "docker")))
               %base-user-accounts))

  (packages (append (list
                     ;; window managers
                     qtile rofi
                     ;; xorg stuff
                     xorg-server xinit xwallpaper xset xrandr
                     ;; text editor
                     vis emacs
                     ;; browser
                     icecat
                     ;; terminal emulator
                     alacritty
                     ;; utils
                     git btop ncurses openssh rsync fastfetch
                     ;; dev
                     go
                     docker-cli
                     (specification->package "cloudflared")) ; from Rosenthal channel
                    %base-packages))

  (services (append (list (service xorg-server-service-type)
                          (service slim-service-type)
                          (service dhcpcd-service-type)
                          ;; Docker and what its daemon depends on
                          (service dbus-root-service-type)
                          (service elogind-service-type)
                          (service containerd-service-type)
                          (service docker-service-type)
(extra-special-file "/lib64/ld-linux-x86-64.so.2"
                    (file-append glibc "/lib/ld-linux-x86-64.so.2"))
			(service tailscale-service-type)
(simple-service 'cloudflared shepherd-root-service-type
  (list (shepherd-service
          (provision '(cloudflared))
          (requirement '(networking))
          (documentation "Run the Cloudflare tunnel.")
          (start #~(make-forkexec-constructor
                    (list #$(file-append (specification->package "cloudflared")
                                         "/bin/cloudflared")
                          "tunnel" "--no-autoupdate" "run"
                          "--token-file" "/etc/cloudflared/token")
                    #:log-file "/var/log/cloudflared.log"))
          (stop #~(make-kill-destructor)))))
                          (service openssh-service-type
                                   (openssh-configuration
                                    (openssh openssh)
                                    (port-number 22)
                                    (permit-root-login #f)
                                    (password-authentication? #f)
                                    (authorized-keys
                                     `(("stevedylandev"
                                        ,(local-file "/home/stevedylandev/.ssh/authorized_keys")))))))
                    %base-services)))
