import bpy
import json
import os
import sys
import math
from mathutils import Vector
import xml.etree.ElementTree as ET
from mathutils import Quaternion, Matrix

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

def ogre_quaternion_to_blender(q):
    """
    Convert a quaternion from Ogre3D (Y-up) to Blender (Z-up).
    Assumes q is in (w, x, y, z) format.
    """
    # Quaternion from Ogre (w, x, y, z)
    ogre_q = Quaternion((q[0], q[1], q[2], q[3]))

    # Coordinate system conversion matrix: rotate -90° around X
    # This converts Y-up (Ogre) to Z-up (Blender)
    rot_conversion = Matrix.Rotation(-1.57079632679, 4, 'X')  # -90° in radians

    # Apply the rotation to convert basis
    m = ogre_q.to_matrix().to_4x4()
    m = rot_conversion @ m
    blender_q = m.to_quaternion()

    return blender_q

def parse_anim_xml(model_base_path, anim_name, file_name):
    xml_path = find_file_by_name(model_base_path, file_name)
    global found_xml_path
    found_xml_path = xml_path
    print(f"Found path {xml_path}")

    tree = ET.parse(xml_path)
    root = tree.getroot()

    global xml_doc
    xml_doc = tree

    outData = {
        "endFrame": 40,
        "keyframes": {}
    }

    for anim in root.find("animations"):
        print(anim.tag)
        if(anim.tag != anim_name):
            continue
        for t in anim.findall("t"):
            print("found transform")
            outData["endFrame"] = int(anim.attrib["end"])

            if(t.attrib["type"] != "transform"):
                continue
            targetId = int(t.attrib["target"])

            transformData = {}
            for k in t.findall("k"):
                frame = int(k.attrib["t"])

                frameData = {"node": t}
                if "position" in k.attrib:
                    x, y, z = map(float, k.attrib["position"].split(','))
                    frameData["position"] = [x, -z, y]
                    #obj.location = (x, y, z)
                    #obj.keyframe_insert(data_path="location", frame=frame)

                if "rot" in k.attrib:
                    rx, ry, rz = map(float, k.attrib["rot"].split(','))
                    frameData["rot"] = [rx, -rz, ry]
                    #obj.rotation_euler = tuple(math.radians(a) for a in (rx, ry, rz))
                    #obj.keyframe_insert(data_path="rotation_euler", frame=frame)

                if "quat" in k.attrib:
                    x, y, z, w = map(float, k.attrib["quat"].split(','))
                    frameData["quat"] = [x, y, z, w]
                    #obj.rotation_euler = tuple(math.radians(a) for a in (rx, ry, rz))
                    #obj.keyframe_insert(data_path="rotation_euler", frame=frame)

                transformData[frame] = frameData

            outData["keyframes"][targetId] = transformData

    print(outData)

    return outData

def link_anim_to_target(animId, anim_data):
    count = 0
    for i in anim_data["animIds"]:
        if(i == animId):
            return count
        count += 1

    return None

def build_model_from_json(model_json_path, anim_json_path, model_base_path, anim_name):
    with open(model_json_path, "r") as f:
        model_data = json.load(f)
    with open(anim_json_path, "r") as f:
        anim_data = json.load(f)

    parsed_anim = parse_anim_xml(model_base_path, anim_name, anim_data.get("filePath"))

    nodes = model_data.get("nodes", [])
    animNodes = anim_data.get("animIds", [])

    global anim_pairs
    anim_pairs = {}

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
        obj.rotation_euler = (0, 0, 0)

        #Match the anim id with the model def
        animId = node["animId"]
        animTarget = link_anim_to_target(animId, anim_data)
        keyframe_data = parsed_anim["keyframes"]
        if animTarget in keyframe_data:
            target_anim_data = {
                "object": obj,
                "node": None
            }
            d = keyframe_data[animTarget]
            for k in d:
                keyframeData = d[k]
                print(keyframeData)
                target_anim_data["node"] = keyframeData["node"]

                if "position" in keyframeData:
                    vec = keyframeData["position"]
                    obj.location = (vec[0], vec[1], vec[2])
                    obj.keyframe_insert(data_path="location", frame=k)

                if "rot" in keyframeData:
                    vec = keyframeData["rot"]
                    obj.rotation_euler = tuple(math.radians(a) for a in (vec[0], vec[1], vec[2]))
                    obj.keyframe_insert(data_path="rotation_euler", frame=k)

                if "quat" in keyframeData:
                    obj.rotation_mode = 'QUATERNION'
                    vec = keyframeData["quat"]
                    #blender_q = ogre_quaternion_to_blender((vec[0], vec[1], vec[2], vec[3]))
                    #obj.rotation_quaternion = (vec[0], -vec[1], -vec[2], vec[3])
                    #obj.keyframe_insert(data_path="rotation_quaternion", frame=k)

            anim_pairs[animTarget] = target_anim_data

    return parsed_anim

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
    animJson = sys.argv[sys.argv.index("--") + 2]
    buildModels = sys.argv[sys.argv.index("--") + 3]
    animName = sys.argv[sys.argv.index("--") + 4]

    anim_data = build_model_from_json(modelJson, animJson, buildModels, animName)

    material = create_color_attribute_material()
    assign_material_to_objects(material)

    set_viewport_to_material_preview()

    #TODO properly define this somewhere
    bpy.context.scene.frame_start = 0
    bpy.context.scene.frame_end = anim_data["endFrame"]
    bpy.context.scene.frame_current = 0

def draw_export_button(self, context):
    layout = self.layout
    layout.separator()
    layout.operator("export.custom_xml_animation", text="Export Animation", icon='EXPORT')

class EXPORT_OT_custom_xml_animation(bpy.types.Operator):
    bl_idname = "export.custom_xml_animation"
    bl_label = "Export Custom XML Animation"

    def vec3ToOgre(self, vec):
        v = Vector((vec[0], vec[1], vec[2]))
        y_val = v.y
        v.y = v.z
        v.z = -y_val
        return v

    def quatToOgre(self, quat):
        v = Vector((quat[0], -quat[1], -quat[2], quat[3]))
        return v

    def execute(self, context):
        for i in anim_pairs:
            obj = anim_pairs[i]["object"]
            node = anim_pairs[i]["node"]
            fcurves = obj.animation_data.action.fcurves
            keyframes = sorted(set(p.co.x for fc in fcurves for p in fc.keyframe_points))

            tail = None
            for child in list(node):
                if tail is None:
                    tail = child.tail
                node.remove(child)

            for frame in keyframes:
                bpy.context.scene.frame_set(int(frame))
                pos = ", ".join(map(str, self.vec3ToOgre(obj.location)))
                rot = ", ".join(str(math.degrees(a)) for a in obj.rotation_euler)
                #rot = ", ".join(str(a) for a in self.quatToOgre(obj.rotation_quaternion))
                #elem = ET.SubElement(node, "k", {"t": str(int(frame)), "position": pos, "quat": rot})
                elem = ET.SubElement(node, "k", {"t": str(int(frame)), "position": pos, "rot": rot})
                elem.tail = tail
                print(pos)
                print(rot)

        xml_doc.write(found_xml_path)

        self.report({'INFO'}, f"Animation exported to {found_xml_path}")
        return {'FINISHED'}

def register():
    bpy.utils.register_class(EXPORT_OT_custom_xml_animation)
    bpy.types.VIEW3D_HT_header.append(draw_export_button)

def unregister():
    bpy.types.VIEW3D_HT_header.remove(draw_export_button)
    bpy.utils.unregister_class(EXPORT_OT_custom_xml_animation)


if __name__ == "__main__":
    clear_scene()
    register()