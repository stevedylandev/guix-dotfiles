(use-modules (gnu) (gnu system nss) (guix gexp) (rosenthal services networking)
             (nongnu packages linux) (nongnu system linux-initrd))
(use-service-modules base desktop xorg networking ssh docker dbus shepherd)
(use-package-modules bootloaders wm window-management text-editors fonts
                     terminals version-control ncurses xdisorg admin
                     xorg compton lxde ssh golang docker containers rsync emacs base
                     shells image-viewers librewolf)

(operating-system
 (host-name "benson")
 (timezone "America/New_York")
 (locale "en_US.utf8")

 ;; Mainline kernel + firmware from nonguix; linux-libre can't load the
 ;; amdgpu blobs the Radeon 780M (Phoenix) needs.
 (kernel linux)
 (initrd microcode-initrd)
 (firmware (list amdgpu-firmware amd-microcode))

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
                    qtile cwm rofi
                    ;; xorg stuff
                    xorg-server xinit xwallpaper xset xrandr feh
                    ;; text editor
                    vis emacs
                    ;; browser
                    librewolf
                    ;; terminal emulator
                    alacritty kitty
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
                                                ;; 'networking' is up as soon as dhcpcd is spawned, before it has a
                                                ;; lease, so cloudflared can exit at boot. Wait between respawns so
                                                ;; it keeps retrying instead of hitting the respawn limit (5 in 7s)
                                                ;; and getting disabled.
                                                (respawn-delay 5)
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
                   (modify-services %base-services
                                    (guix-service-type
                                     config => (guix-configuration
                                                (inherit config)
                                                (authorized-keys
                                                 (cons (local-file "nonguix-signing-key.pub")
                                                       %default-authorized-guix-keys))
                                                (substitute-urls
                                                 (append (list "https://substitutes.nonguix.org")
                                                         %default-substitute-urls))))))))
