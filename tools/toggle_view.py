import os
import json
import argparse

SETTINGS_PATH = '.vscode/settings.json'

PERMANENT_EXCLUDES = {
    # Python
    "**/.venv": True,
    "**/__pycache__": True,
    "**/*.pyc": True,
    # VCS / IDE
    "**/.git": True,
    "**/.vscode": True,
    "**/.agents": True,
    "**/.github": True,
    # Dart / Flutter
    "**/.dart_tool": True,
    "**/.flutter-plugins": True,
    "**/.flutter-plugins-dependencies": True,
    "**/client_flutter/.metadata": True,
    "**/client_flutter/*.iml": True,
    "**/client_flutter/pubspec.lock": True,
    "**/client_flutter/devtools_options.yaml": True,
    # Flutter target platforms we don't build for
    "**/client_flutter/ios": True,
    "**/client_flutter/linux": True,
    "**/client_flutter/macos": True,
    "**/client_flutter/web": True,
    # Rust
    "**/target": True,
    "**/*.lock": True,
    # Node / TS
    "**/node_modules": True,
    "**/dist": True,
    "**/.next": True,
    # Go
    "**/vendor": True,
    # Generic build artifacts
    "**/build": True,
}

# These folders are always visible regardless of --focus
ALWAYS_VISIBLE = {
    '_architecture',
    'tools',
    'schemas',
}


def main():
    parser = argparse.ArgumentParser(
        description='Toggle workspace visibility in VSCode — horAIzon 3.0'
    )
    parser.add_argument(
        '--focus',
        nargs='+',
        help=(
            'Root folders (or subpaths) to keep visible. '
            'Examples: client_flutter   shua_governor   shua_diary/src'
        ),
    )
    parser.add_argument(
        '--reset',
        action='store_true',
        help='Show all root folders (clear dynamic excludes)',
    )
    args = parser.parse_args()

    if not os.path.exists(SETTINGS_PATH):
        print(f"[toggle_view] ERROR: {SETTINGS_PATH} not found.")
        print("  Create it first: mkdir -p .vscode && echo '{}' > .vscode/settings.json")
        return

    with open(SETTINGS_PATH, 'r') as f:
        settings = json.load(f)

    # Start from the permanent excludes — always enforced
    new_excludes = dict(PERMANENT_EXCLUDES)

    if args.focus:
        visible_roots = set(ALWAYS_VISIBLE)
        nested_focus: dict[str, set[str]] = {}

        for path in args.focus:
            parts = path.replace('\\', '/').strip('/').split('/')
            root = parts[0]
            visible_roots.add(root)
            if len(parts) > 1:
                nested_focus.setdefault(root, set()).add(parts[1])
            else:
                # Full root requested — clear any nested constraint
                nested_focus.pop(root, None)

        for item in os.listdir('.'):
            if item.startswith('.'):
                continue
            if item not in visible_roots:
                new_excludes[item] = True
            elif item in nested_focus and os.path.isdir(item):
                allowed = nested_focus[item]
                for sub in os.listdir(item):
                    if sub not in allowed:
                        new_excludes[f"{item}/{sub}"] = True

        print(f"[toggle_view] Focusing on: {', '.join(args.focus)}")

    elif args.reset:
        print("[toggle_view] Reset — all root folders visible.")

    else:
        parser.print_help()
        return

    settings['files.exclude'] = new_excludes

    with open(SETTINGS_PATH, 'w') as f:
        json.dump(settings, f, indent=2)

    print("[toggle_view] .vscode/settings.json updated.")


if __name__ == '__main__':
    main()
