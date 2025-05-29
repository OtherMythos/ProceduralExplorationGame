import argparse
import subprocess
import os

def main():
    parser = argparse.ArgumentParser(description="Launch Blender with a character model for animation.")
    parser.add_argument('--name', required=True, help="Name of the model (e.g. Skeleton)")
    parser.add_argument('--animName', required=True, help="Name of the animation to edit")
    parser.add_argument('--modelDefDir', default="/Users/edward/Documents/ProceduralExplorationGame/build", help="Directory containing .obj files")
    parser.add_argument('--animDumpDir', default="/Users/edward/Documents/ProceduralExplorationGame/.dumpedCharacterAnimations", help="Directory containing dumped animation json files")
    parser.add_argument('--modelDumpDir', default="/Users/edward/Documents/ProceduralExplorationGame/.dumpedCharacterModels", help="Directory containing dumped character model files")

    args = parser.parse_args()

    # Construct paths
    blender_script = os.path.abspath("script/blenderAnimationEditor.py")
    model_json = os.path.join(args.modelDumpDir, f"{args.name}.json")
    anim_json = os.path.join(args.animDumpDir, f"{args.animName}.json")
    model_dir = args.modelDefDir

    # Launch Blender with Python script and arguments
    cmd = [
        "blender",
        "--python", blender_script,
        "--",  # Signals start of script args
        model_json,
        anim_json,
        model_dir,
        args.animName
    ]

    print("Running:", " ".join(cmd))
    subprocess.run(cmd)

if __name__ == "__main__":
    main()