import os
import subprocess


def get_dosbox_path():
    """Find the DOSBox executable."""
    possible_paths = [
        r"C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe",
        r"C:\Program Files (x86)\DOSBox-0.74\DOSBox.exe",
        r"C:\Program Files\DOSBox-0.74-3\DOSBox.exe",
        r"C:\Program Files\DOSBox-0.74\DOSBox.exe",
        os.path.expanduser(r"~\AppData\Local\DOSBox\DOSBox.exe"),
    ]

    for path in possible_paths:
        if os.path.isfile(path):
            return path

    # If DOSBox is available in PATH
    return "dosbox"


def run_main():
    """Build and run main.asm using DOSBox, MASM, and LINK."""
    base_dir = os.path.dirname(os.path.abspath(__file__))
    source_name = "main.asm"
    source_path = os.path.join(base_dir, source_name)

    if not os.path.isfile(source_path):
        print(f"\n[!] Assembly file '{source_name}' not found.")
        print(f"    Expected location: {source_path}")
        return

    dosbox_exe = get_dosbox_path()
    target_dir = os.path.abspath(base_dir)
    program_name = "main"

    # DOSBox commands
    commands = [
        f'MOUNT C "{target_dir}"',
        "C:",
        f"MASM {source_name};",
        f"LINK {program_name}.obj;",
        f"{program_name}.exe",
        "PAUSE",
        "EXIT",
    ]

    cmd = [dosbox_exe]

    for command in commands:
        cmd.extend(["-c", command])

    print(f"\n[+] Launching {source_name}...")
    print(f"[+] Directory: {target_dir}\n")

    try:
        subprocess.run(cmd, check=True)

    except FileNotFoundError:
        print("\n[!] DOSBox was not found.")
        print("[!] Please install DOSBox or add it to PATH.")

    except subprocess.CalledProcessError as error:
        print(f"\n[!] DOSBox exited with error code {error.returncode}")

    except OSError as error:
        print(f"\n[!] Failed to launch DOSBox: {error}")


def main():
    """Main program loop."""

    print("=" * 40)
    print("      DOSBox Assembly Runner (main.asm)")
    print("=" * 40)

    while True:
        print()

        user_input = (
            input("Press [Enter] to run main.asm or 'q' to Exit: ")
            .strip()
            .lower()
        )

        # Exit
        if user_input in {"q", "quit", "exit"}:
            print("\nExiting runner. Goodbye!")
            break

        # Run main.asm
        run_main()


if __name__ == "__main__":
    main()