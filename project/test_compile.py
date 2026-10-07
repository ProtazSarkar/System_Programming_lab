import subprocess
import os

dosbox = r"C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe"
cwd = r"c:\Assignments\System_Programming_lab\project"

# Remove MAIN.OBJ and MAIN.EXE to test clean build
for fname in ["MAIN.OBJ", "MAIN.EXE"]:
    path = os.path.join(cwd, fname)
    if os.path.exists(path):
        try:
            os.remove(path)
            print(f"Removed {fname}")
        except Exception as e:
            print(f"Could not remove {fname}: {e}")

cmd = [
    dosbox,
    "-c", f'MOUNT C "{cwd}"',
    "-c", "C:",
    "-c", "MASM MAIN.ASM;",
    "-c", "LINK MAIN.OBJ;",
    "-c", "PAUSE",
    "-c", "EXIT"
]

print("Launching DOSBox build...")
subprocess.run(cmd)

print("Check generated files:")
print("MAIN.OBJ exists:", os.path.exists(os.path.join(cwd, "MAIN.OBJ")))
print("MAIN.EXE exists:", os.path.exists(os.path.join(cwd, "MAIN.EXE")))
