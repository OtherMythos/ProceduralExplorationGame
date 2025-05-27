import argparse
import subprocess
import os

def main():
    parser = argparse.ArgumentParser(description="Launch Blender with a character model for animation.")
    parser.add_argument('--name', required=True, help="Name of the model (e.g. Skeleton)")
    parser.add_argument('--modelDefDir', default="/Users/edward/Documents/ProceduralExplorationGame/build", help="Directory containing .obj files")

    args = parser.parse_args()

    # Construct paths
    blender_script = os.path.abspath("script/blenderAnimationEditor.py")
    model_json = os.path.join("/tmp/modelOut", f"{args.name}.json")
    model_dir = args.modelDefDir

    # Launch Blender with Python script and arguments
    cmd = [
        "blender",
        "--python", blender_script,
        "--",  # Signals start of script args
        model_json,
        model_dir
    ]

    print("Running:", " ".join(cmd))
    subprocess.run(cmd)

if __name__ == "__main__":
    main()