#!/usr/bin/env python3

import argparse

def generate_tile_grid(width, height, file_path, value):
    """
    Generate a tiled grid of values and write to a file.

    Args:
        width: Number of columns in the grid
        height: Number of rows in the grid
        file_path: Path where the grid file will be written
        value: The value to fill the grid with
    """
    with open(file_path, 'w') as f:
        for row in range(height):
            row_values = [str(value) for _ in range(width)]
            f.write(','.join(row_values) + ',\n')

def main():
    parser = argparse.ArgumentParser(description='Generate a tiled grid of values')
    parser.add_argument('width', type=int, help='Width of the grid (number of columns)')
    parser.add_argument('height', type=int, help='Height of the grid (number of rows)')
    parser.add_argument('file_path', type=str, help='Output file path')
    parser.add_argument('value', type=int, help='Value to fill the grid with')

    args = parser.parse_args()

    generate_tile_grid(args.width, args.height, args.file_path, args.value)
    print(f'Generated {args.width}x{args.height} grid with value {args.value} at {args.file_path}')

if __name__ == '__main__':
    main()
