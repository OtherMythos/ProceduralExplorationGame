from cairosvg import svg2png
from assetModules.AssetModule import *

from pathlib import Path
import os
import shutil
import json
import re


def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def rgb_to_hex(rgb):
    return '#%02x%02x%02x' % tuple(max(0, min(255, int(v))) for v in rgb)


def blend(c1, c2, t):
    r1, g1, b1 = hex_to_rgb(c1)
    r2, g2, b2 = hex_to_rgb(c2)
    return rgb_to_hex((r1*(1-t)+r2*t, g1*(1-t)+g2*t, b1*(1-t)+b2*t))


def extract_top_paths(atlas_path):
    txt = open(atlas_path, 'r', encoding='utf-8').read()
    paths = re.findall(r'<path[^>]+/>', txt)
    if len(paths) < 3:
        raise RuntimeError('Could not find three top paths in atlas')
    return paths[0], paths[1], paths[2]


def make_group(path_outer, path_mid, path_inner, outer_fill, mid_fill, inner_fill, y):
    def replace_fill(path_str, new_fill):
        s = re.sub(r'fill="#?[0-9a-fA-F]{6}"', f'fill="{new_fill}"', path_str)
        return s

    outer = replace_fill(path_outer, outer_fill)
    mid = replace_fill(path_mid, mid_fill)
    inner = replace_fill(path_inner, inner_fill)
    if y == 0:
        return '  ' + outer + '\n  ' + mid + '\n  ' + inner + '\n'
    else:
        return f'  <g transform="translate(0,{y})">\n    ' + outer + '\n    ' + mid + '\n    ' + inner + '\n  </g>\n'


def normalize_hex(s):
    if not s:
        return s
    s = s.strip()
    # Examples of accepted inputs: "#0xff0000", "0xff0000", "#ff0000", "ff0000"
    if s.startswith('#0x'):
        return '#' + s[3:]
    if s.startswith('0x'):
        return '#' + s[2:]
    if s.startswith('#') and '0x' in s:
        return '#' + s.replace('0x', '').lstrip('#')
    if len(s) == 6 and all(c in '0123456789abcdefABCDEF' for c in s):
        return '#' + s
    return s


def generate_coloured_atlas_svg(atlas_path, entries):
    """Build a coloured atlas SVG from a template and palette entries.
    Returns (svg_string, new_height)."""
    path_outer, path_mid, path_inner = extract_top_paths(str(atlas_path))
    groups = []
    for i, (entry_name, entry_val) in enumerate(entries):
        raw_hex = entry_val.get('hex') if isinstance(entry_val, dict) else entry_val
        if not raw_hex:
            print(f"Skipping {entry_name}: no hex value")
            continue
        norm = normalize_hex(raw_hex)
        if not norm or not norm.startswith('#'):
            print(f"Skipping {entry_name}: invalid hex '{raw_hex}'")
            continue
        outer = blend(norm, '#000000', 0.6)
        mid   = blend(norm, '#000000', 0.3)
        inner = norm
        groups.append(make_group(path_outer, path_mid, path_inner, outer, mid, inner, i * 128))
    new_height = max(128, len(groups) * 128)
    svg_out = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg width="256" height="{new_height}" xmlns="http://www.w3.org/2000/svg">',
        '\n'.join(groups),
        '</svg>',
    ]
    return '\n'.join(svg_out), new_height


def generate_skin_entry(template, template_key, entry_name, i, new_height):
    """Build a single skin dict from a template for one palette colour entry."""
    entry = dict(template)
    entry['tex_resolution'] = [256, new_height]
    entry.pop('atlas', None)
    entry.pop('colour', None)
    if 'material' in entry and 'COLOUR' in entry['material']:
        entry['material'] = entry['material'].replace('COLOUR', str(entry_name))
    y_offset = i * 128
    if 'grid_uv' in template:
        entry['grid_uv'] = {
            k: [v[0], v[1] + y_offset, v[2], v[3]] for k, v in template['grid_uv'].items()
        }
    return entry


def update_skins_json(sk_json_path, entries, new_height):
    """Update a Skins.colibri.json in-place: expand all COLOUR skin and pack templates."""
    with open(sk_json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    #Find all skin templates containing COLOUR
    skin_templates = {k: v for k, v in list(data['skins'].items()) if 'COLOUR' in k}

    #Remove previously generated entries for each template pattern
    for template_key in skin_templates:
        prefix = template_key.split('COLOUR')[0]
        suffix = template_key.split('COLOUR')[1]
        for k in list(data['skins'].keys()):
            if k.startswith(prefix) and k.endswith(suffix) and 'COLOUR' not in k:
                del data['skins'][k]

    #Generate entries for each template x each palette colour
    for template_key, template in skin_templates.items():
        for i, (entry_name, entry_val) in enumerate(entries):
            raw_hex = entry_val.get('hex') if isinstance(entry_val, dict) else entry_val
            norm = normalize_hex(raw_hex)
            if not norm or not norm.startswith('#'):
                continue
            skin_key = template_key.replace('COLOUR', str(entry_name))
            data['skins'][skin_key] = generate_skin_entry(template, template_key, entry_name, i, new_height)

    #Expand skin_packs COLOUR templates
    if 'skin_packs' in data:
        original_packs = dict(data['skin_packs'])
        for pack_key, pack_val in original_packs.items():
            if 'COLOUR' in pack_key or (isinstance(pack_val, dict) and any('COLOUR' in str(v) for v in pack_val.values())):
                for entry_name, entry_val in entries:
                    new_key = pack_key.replace('COLOUR', str(entry_name))
                    new_val = json.loads(json.dumps(pack_val))
                    for k, v in new_val.items():
                        if isinstance(v, str) and 'COLOUR' in v:
                            new_val[k] = v.replace('COLOUR', str(entry_name))
                    data['skin_packs'][new_key] = new_val
            if 'COLOUR' in pack_key:
                del data['skin_packs'][pack_key]

    with open(sk_json_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4)


class AssetModuleSkinPalette(AssetModule):
    def __init__(self, settings):
        super().__init__(settings)
        self.extension = ".skinColourPalette"

    def exportForFile(self, filePath, resSettings):
        # filePath is expected to be a pathlib.Path
        repo_root = Path(filePath).resolve().parents[2]
        template_skin = repo_root / 'assets' / 'skins' / 'Skin'
        out_skins_dir = repo_root / 'assets' / 'skins'

        atlas_template = template_skin / 'Atlas.svg'
        if not atlas_template.exists():
            print(f"Atlas template missing: {atlas_template}")
            return

        try:
            with open(filePath, 'r', encoding='utf-8') as f:
                palette_data = json.load(f)
        except Exception as e:
            print(f"Failed to read palette file {filePath}: {e}")
            return

        # Support new format: palette_data['colours']
        if 'colours' in palette_data and isinstance(palette_data['colours'], dict):
            entries = list(palette_data['colours'].items())
        else:
            entries = list(palette_data.items())
        palette_name = filePath.stem
        ret_rel = Path('assets') / 'skins' / palette_name / 'Atlas.svg'
        try:
            out_atlas = self.prepareOutputDirectoryForFile(repo_root / ret_rel, True)
        except Exception:
            out_atlas = repo_root / ret_rel

        output_dir = Path(out_atlas).parent
        if output_dir.exists():
            shutil.rmtree(output_dir)
        shutil.copytree(template_skin, output_dir)

        svg_content, new_height = generate_coloured_atlas_svg(atlas_template, entries)
        with open(output_dir / 'Atlas.svg', 'w', encoding='utf-8') as f:
            f.write(svg_content)

        atlas_small_edge_template = template_skin / 'AtlasSmallEdge.svg'
        if atlas_small_edge_template.exists():
            small_edge_content, _ = generate_coloured_atlas_svg(atlas_small_edge_template, entries)
            with open(output_dir / 'AtlasSmallEdge.svg', 'w', encoding='utf-8') as f:
                f.write(small_edge_content)

        # Update Skins.colibri.json tex_resolution and add skin entries
        sk_json_path = output_dir / 'Skins.colibri.json'
        if sk_json_path.exists():
            try:
                update_skins_json(sk_json_path, entries, new_height)
            except Exception as e:
                print(f"Warning: failed to update Skins.colibri.json in {output_dir}: {e}")

        # Convert all SVG files in the output_dir to PNG

        for svg_file in output_dir.glob('*.svg'):
            png_file = svg_file.with_suffix('.png')
            try:
                svg2png(url=str(svg_file), write_to=str(png_file))
                svg_file.unlink() # Remove the SVG after conversion
            except Exception as e:
                print(f"Warning: failed to convert {svg_file} to PNG: {e}")

        print(f'Created skin palette directory: {output_dir} from {filePath.name}')
