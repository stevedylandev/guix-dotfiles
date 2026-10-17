(use-modules (gnu)
             (gnu system nss)
             (guix gexp)
             (rosenthal services networking)
             (nongnu packages linux) (nongnu system linux-initrd))

(use-service-modules base desktop xorg networking ssh docker dbus shepherd sddm)

(use-package-modules bootloaders wm window-management text-editors fonts
                     terminals version-control ncurses admin
                     compton lxde ssh golang docker containers xdisorg
                     rsync emacs base shells image-viewers librewolf
                     tmux python video image node linux)

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
               (supplementary-groups '("wheel" "netdev" "audio" "video" )))
              %base-user-accounts))

 (packages (append (list
                    ;; window managers
                    qtile sway rofi
                    ;; wayland stuff
                    swaybg swayidle swaylock wl-clipboard
                    ;; text editor
                    vis emacs
                    ;; browser
                    librewolf
                    ;; terminal emulator
                    kitty
                    ;; utils
                    git btop ncurses openssh rsync fastfetch tmux
                    ;; av
                    ffmpeg grim slurp pipewire wireplumber
                    ;; dev
                    go  python docker-cli node
                    (specification->package "cloudflared")) ; from Rosenthal channel
                   %base-packages))

 (services (append (list

                    (service plasma-desktop-service-type)
                    (service sddm-service-type
                             (sddm-configuration
                              (theme "breeze")))
                    ;; (service greetd-service-type
                    ;;               (greetd-configuration
                    ;;                (terminals
                    ;;                 (list
                    ;;                  ;; Text login on tty7 that starts sway
                    ;;                  (greetd-terminal-configuration
                    ;;                   (terminal-vt "7")
                    ;;                   (terminal-switch #t)
                    ;;                   (default-session-command
                    ;;                     (greetd-agreety-session
                    ;;                      (command
                    ;;                       (greetd-user-session
                    ;;                        (command (file-append sway "/bin/sway"))
                    ;;                        (command-args '())
                    ;;                        (xdg-session-type "wayland"))))))))))
                    ;; (service dhcpcd-service-type)
                    (service network-manager-service-type)
                    (service wpa-supplicant-service-type)
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
