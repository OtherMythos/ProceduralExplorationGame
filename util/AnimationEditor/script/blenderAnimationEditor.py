import bpy
import json
import os
import sys

def create_color_attribute_material():
    # Create a new material
    mat = bpy.data.materials.new(name="ColorAttributeMaterial")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links

    # Clear default nodes
    nodes.clear()

    # Add required nodes
    output_node = nodes.new(type='ShaderNodeOutputMaterial')
    output_node.location = (400, 0)

    principled_node = nodes.new(type='ShaderNodeBsdfPrincipled')
    principled_node.location = (0, 0)

    attr_node = nodes.new(type='ShaderNodeVertexColor')
    attr_node.location = (-300, 0)

    # Link Attribute -> Principled -> Output
    links.new(attr_node.outputs['Color'], principled_node.inputs['Base Color'])
    links.new(principled_node.outputs['BSDF'], output_node.inputs['Surface'])

    return mat

def assign_material_to_objects(mat):
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            mesh = obj.data
            # Ensure the materials slot exists
            if not mesh.materials:
                mesh.materials.append(mat)
            else:
                mesh.materials[0] = mat

def find_file_by_name(root_dir, target_filename):
    for dirpath, dirnames, filenames in os.walk(root_dir):
        if target_filename in filenames:
            return os.path.abspath(os.path.join(dirpath, target_filename))
    return None

def build_model_from_json(json_path, model_base_path):
    with open(json_path, "r") as f:
        model_data = json.load(f)

    nodes = model_data.get("nodes", [])

    for node in nodes:
        obj_filename = node["name"]
        obj_path = find_file_by_name(model_base_path, obj_filename)

        if obj_path is None or not os.path.exists(obj_path):
            print(f"OBJ file not found: {obj_filename}")
            continue

        obj = import_obj(obj_path)
        #for obj in imported_objs:
        obj.location = node["pos"]
        obj.scale = node["scale"]
        #assign_material_to_object(obj, material)

    #set_viewport_to_material_preview()

def import_obj(filepath):
    # Record objects before import
    existing_objects = set(bpy.data.objects)

    # Perform the import
    #bpy.ops.import_scene.obj(filepath=filepath)
    import_obj_to_scene(filepath)

    # Find new objects
    new_objects = set(bpy.data.objects) - existing_objects
    return list(new_objects)[0]

def import_obj_to_scene(path):
    for window in bpy.context.window_manager.windows:
        screen = window.screen
        for area in screen.areas:
            if area.type == 'VIEW_3D':
                with bpy.context.temp_override(window=window, area=area):
                    return bpy.ops.wm.obj_import(filepath=path)
    raise RuntimeError("No VIEW_3D area found to import OBJ.")

def set_viewport_to_material_preview():
    for window in bpy.context.window_manager.windows:
        for area in window.screen.areas:
            if area.type == 'VIEW_3D':
                for space in area.spaces:
                    if space.type == 'VIEW_3D':
                        space.shading.type = 'MATERIAL'

def clear_scene():
    bpy.ops.wm.read_homefile(use_empty=True)  # Start with an empty scene

    # Get a valid override context for the window and area
    #import_obj_to_scene("/Users/edward/Documents/ProceduralExplorationGame/build/assets/models/player/playerHead.obj")
    modelJson = sys.argv[sys.argv.index("--") + 1]
    buildModels = sys.argv[sys.argv.index("--") + 2]

    build_model_from_json(modelJson, buildModels)

    material = create_color_attribute_material()
    assign_material_to_objects(material)

    set_viewport_to_material_preview()

clear_scene()