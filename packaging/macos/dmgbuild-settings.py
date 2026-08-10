# dmgbuild settings for FlameWhisper.dmg
# Used by scripts/create-dmg.sh — see https://dmgbuild.readthedocs.io
import os

HERE = os.environ.get("DMGBUILD_SETTINGS_DIR")
if HERE is None:
    try:
        HERE = os.path.dirname(os.path.abspath(__file__))
    except NameError:
        HERE = os.path.abspath("packaging/macos")

PROJECT_DIR = os.path.abspath(os.path.join(HERE, "..", ".."))

app = os.path.join(PROJECT_DIR, "dist", "FlameWhisper.app")
background = os.path.join(HERE, "dmg-background.png")

files = [app]
symlinks = {"Applications": "/Applications"}

icon_locations = {
    app: (150, 210),
    "Applications": (450, 210),
}

window_rect = ((200, 160), (600, 400))
icon_size = 110
text_size = 13

format = "UDZO"
volume_name = "FlameWhisper"
