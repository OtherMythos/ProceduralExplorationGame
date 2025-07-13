#pragma once

#include <vector>
#include <cmath>
#include <algorithm>
#include <unordered_set>
#include <unordered_map>

#include "Ogre.h"

namespace ProceduralExplorationGameCore{


    class WaterMeshGenerator {
    public:
        struct Hole {
            Ogre::Vector2 center;
            float radius;
            int circleSegments; // Number of segments to approximate the circle

            Hole(Ogre::Vector2 center, float radius, int segments = 16)
                : center(center), radius(radius), circleSegments(segments) {}
        };

        struct Triangle {
            uint32_t v0, v1, v2;
            Triangle(uint32_t v0, uint32_t v1, uint32_t v2) : v0(v0), v1(v1), v2(v2) {}
        };

        struct Vertex {
            Ogre::Vector3 pos;
            Ogre::Vector2 uv;
        };

        struct MeshData {
            std::vector<Vertex> vertices;
            std::vector<Triangle> triangles;
        };

        MeshData generateMesh(int width, int height, const std::vector<Hole>& holes, float cellSize = 1.0f);

    private:
        std::vector<Vertex> vertices;
        std::vector<Triangle> triangles;
        std::unordered_set<uint64_t> removedQuads;
        std::unordered_map<uint64_t, uint32_t> vertexMap;

        int gridWidth, gridHeight;
        float cellSize;

        uint64_t makeKey(int x, int y) const;
        uint64_t makeQuadKey(int x, int y) const;
        uint32_t addVertex(const Ogre::Vector3& vertex, const Ogre::Vector2 uv);
        uint32_t getVertexIndex(int x, int y);
        bool isPointInCircle(const Ogre::Vector2& point, const Ogre::Vector2& center, float radius) const;
        bool quadIntersectsCircle(int quadX, int quadY, const Hole& hole) const;
        std::vector<uint32_t> generateCircleVertices(const Hole& hole);
        void triangulateAroundHole(const Hole& hole, const std::vector<uint32_t>& circleIndices);
        void generateGridTriangles();

    };


}
