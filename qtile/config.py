# Qtile config -- Darkmatter
# Palette matches the Darkmatter GTK theme, alacritty, and emacs themes.

import os

from libqtile import bar, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy

mod = "mod4"
terminal = "alacritty"
launcher = "rofi -show drun"

# Darkmatter palette (see the gtk3 theme README for the roles)
colors = {
    "shadow": "#060506",
    "bg": "#121113",
    "bg_alt": "#1c1b1d",
    "hover": "#222222",
    "border": "#2b2b2b",
    "grey": "#333333",
    "disabled": "#888888",
    "muted": "#999999",
    "near_fg": "#c1c1c1",
    "fg": "#ffffff",
    "green": "#5f8787",
    "yellow": "#fbcb97",
    "accent": "#fbcb97",
    "red": "#e75353",
}

font = "BerkeleyMono Nerd Font Mono"

keys = [
    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    # Move windows between columns or up/down in the current stack
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    # Grow windows
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "d", lazy.spawn(launcher), desc="Launch application"),
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
    Key([mod], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen"),
    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating"),
    Key([mod], "b", lazy.hide_show_bar(), desc="Toggle the bar"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
]

# Switch VTs under Wayland; deferred since qtile.core isn't set at load time
for vt in range(1, 8):
    keys.append(
        Key(
            ["control", "mod1"],
            f"f{vt}",
            lazy.core.change_vt(vt).when(func=lambda: qtile.core.name == "wayland"),
            desc=f"Switch to VT{vt}",
        )
    )

groups = [Group(i) for i in "123456789"]

for i in groups:
    keys.extend(
        [
            Key([mod], i.name, lazy.group[i.name].toscreen(), desc=f"Switch to group {i.name}"),
            Key(
                [mod, "shift"],
                i.name,
                lazy.window.togroup(i.name, switch_group=True),
                desc=f"Switch to & move focused window to group {i.name}",
            ),
        ]
    )

layout_theme = dict(
    border_width=2,
    margin=6,
    border_focus=colors["yellow"],
    border_normal=colors["bg"],
)

layouts = [
    layout.Columns(
        **layout_theme,
        border_focus_stack=colors["accent"],
        border_normal_stack=colors["bg"],
        border_on_single=True,
    ),
    layout.Max(margin=6),
]

widget_defaults = dict(
    font=font,
    fontsize=14,
    padding=6,
    background=colors["bg"],
    foreground=colors["near_fg"],
)
extension_defaults = widget_defaults.copy()


def sep():
    return widget.TextBox("│", foreground=colors["grey"], padding=2)


screens = [
    Screen(
        wallpaper=os.path.expanduser("~/wallpapers/assets/temple.png"),
        wallpaper_mode="fill",
        top=bar.Bar(
            [
                widget.GroupBox(
                    highlight_method="line",
                    highlight_color=[colors["bg"], colors["bg"]],
                    this_current_screen_border=colors["accent"],
                    this_screen_border=colors["grey"],
                    other_current_screen_border=colors["green"],
                    other_screen_border=colors["grey"],
                    active=colors["fg"],
                    inactive=colors["grey"],
                    urgent_alert_method="text",
                    urgent_text=colors["red"],
                    rounded=False,
                    disable_drag=True,
                    padding_x=6,
                ),
                sep(),
                widget.CurrentLayout(foreground=colors["yellow"]),
                sep(),
                widget.Prompt(
                    foreground=colors["accent"],
                    cursor_color=colors["fg"],
                    prompt="run: ",
                ),
                widget.WindowName(foreground=colors["muted"], max_chars=80),
                widget.Chord(
                    chords_colors={"launch": (colors["accent"], colors["bg"])},
                    name_transform=lambda name: name.upper(),
                ),
                widget.Systray(background=colors["bg"]),
                sep(),
                widget.Clock(
                    format="%a, %b %d - %-I:%M %p",
                    foreground=colors["fg"],
                ),
            ],
            28,
            background=colors["bg"],
            border_width=[0, 0, 1, 0],
            border_color=colors["border"],
        ),
    ),
]

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
floating_layout = layout.Floating(
    border_width=2,
    border_focus=colors["green"],
    border_normal=colors["grey"],
    float_rules=[
        # Run `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ],
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
auto_minimize = True

wl_input_rules = None
wl_xcursor_theme = None
wl_xcursor_size = 24

# Keeps java UI toolkits happy
wmname = "LG3D"
