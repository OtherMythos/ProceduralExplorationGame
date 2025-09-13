#include "WaterMeshGenerator.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace ProceduralExplorationGameCore{

    // Helper function to create a unique key for grid coordinates
    uint64_t WaterMeshGenerator::makeKey(int x, int y) const {
        return (static_cast<uint64_t>(x) << 32) | static_cast<uint64_t>(y);
    }

    // Helper function to create a unique key for quads
    uint64_t WaterMeshGenerator::makeQuadKey(int x, int y) const {
        return makeKey(x, y);
    }

    // Add vertex and return its index
    uint32_t WaterMeshGenerator::addVertex(const Ogre::Vector3& vertex, const Ogre::Vector2 uv) {
        vertices.push_back({vertex, uv});
        return static_cast<uint32_t>(vertices.size() - 1);
    }

    // Get or create vertex at grid position
    uint32_t WaterMeshGenerator::getVertexIndex(int x, int y, AV::uint8 vertFlag) {
        uint64_t key = makeKey(x, y);
        auto it = vertexMap.find(key);
        if (it != vertexMap.end()) {
            return it->second;
        }

        Ogre::Vector3 vertex(x * cellSize, float(vertFlag), y * cellSize);
        uint32_t index = addVertex(vertex, Ogre::Vector2(float(x) / float(gridWidth-1), float(y) / float(gridHeight-1)));
        vertexMap[key] = index;
        return index;
    }

    // Check if a point is inside a circle
    bool WaterMeshGenerator::isPointInCircle(const Ogre::Vector2& point, const Ogre::Vector2& center, float radius) const {
        return (point - center).length() <= radius;
    }

    // Check if a quad intersects with a circle
    bool WaterMeshGenerator::quadIntersectsCircle(int quadX, int quadY, const Hole& hole) const {
        Ogre::Vector2 quadMin(quadX * cellSize, quadY * cellSize);
        Ogre::Vector2 quadMax((quadX + 1) * cellSize, (quadY + 1) * cellSize);

        // Check if any corner is inside the circle
        Ogre::Vector2 corners[4] = {
            quadMin,
            Ogre::Vector2(quadMax.x, quadMin.y),
            quadMax,
            Ogre::Vector2(quadMin.x, quadMax.y)
        };

        for (int i = 0; i < 4; ++i) {
            if (isPointInCircle(corners[i], hole.center, hole.radius)) {
                return true;
            }
        }

        // Check if circle center is inside quad
        if (hole.center.x >= quadMin.x && hole.center.x <= quadMax.x &&
            hole.center.y >= quadMin.y && hole.center.y <= quadMax.y) {
            return true;
        }

        // Check if circle intersects quad edges (simplified check)
        Ogre::Vector2 quadCenter((quadMin.x + quadMax.x) * 0.5f, (quadMin.y + quadMax.y) * 0.5f);
        float quadRadius = (quadMax - quadMin).length() * 0.5f;
        float distanceToQuadCenter = (hole.center - quadCenter).length();

        return distanceToQuadCenter <= (hole.radius + quadRadius);
    }

    // Generate circle vertices for a hole
    std::vector<uint32_t> WaterMeshGenerator::generateCircleVertices(const Hole& hole) {
        std::vector<uint32_t> circleIndices;

        for (int i = 0; i < hole.circleSegments; ++i) {
            float angle = (2.0f * M_PI * i) / hole.circleSegments;
            Ogre::Vector3 vertex(
                hole.center.x + hole.radius * std::cos(angle),
                0.0f,
                hole.center.y + hole.radius * std::sin(angle)
            );
            Ogre::Vector2 uv(float(vertex.x) / float(gridWidth-1), float(vertex.y) / float(gridHeight-1));
            circleIndices.push_back(addVertex(vertex, uv));
        }

        return circleIndices;
    }

    // Triangulate around a hole
    void WaterMeshGenerator::triangulateAroundHole(const Hole& hole, const std::vector<uint32_t>& circleIndices) {
        // Find boundary vertices around the hole
        std::vector<uint32_t> boundaryVertices;

        // Calculate the bounding box of the hole
        int minX = std::max(0, static_cast<int>((hole.center.x - hole.radius) / cellSize) - 1);
        int maxX = std::min(gridWidth, static_cast<int>((hole.center.x + hole.radius) / cellSize) + 2);
        int minY = std::max(0, static_cast<int>((hole.center.y - hole.radius) / cellSize) - 1);
        int maxY = std::min(gridHeight, static_cast<int>((hole.center.y + hole.radius) / cellSize) + 2);

        // Collect boundary vertices (vertices on the edge of removed quads)
        for (int y = minY; y <= maxY; ++y) {
            for (int x = minX; x <= maxX; ++x) {
                Ogre::Vector2 gridPos(x * cellSize, y * cellSize);
                float distToCenter = (gridPos - hole.center).length();

                // If vertex is outside hole but close to boundary
                if (distToCenter > hole.radius && distToCenter <= hole.radius + cellSize * 1.5f) {
                    // Check if this vertex is on the boundary of removed area
                    bool isBoundary = false;

                    // Check adjacent quads
                    for (int dy = -1; dy <= 0; ++dy) {
                        for (int dx = -1; dx <= 0; ++dx) {
                            int qx = x + dx;
                            int qy = y + dy;
                            if (qx >= 0 && qx < gridWidth - 1 && qy >= 0 && qy < gridHeight - 1) {
                                uint64_t quadKey = makeQuadKey(qx, qy);
                                if (removedQuads.count(quadKey) > 0) {
                                    isBoundary = true;
                                    break;
                                }
                            }
                        }
                        if (isBoundary) break;
                    }

                    if (isBoundary) {
                        boundaryVertices.push_back(getVertexIndex(x, y));
                    }
                }
            }
        }

        // Simple triangulation: connect each circle edge to nearby boundary vertices
        // This is a simplified approach - for production code, you'd want a more sophisticated
        // triangulation algorithm like Delaunay triangulation

        for (size_t i = 0; i < circleIndices.size(); ++i) {
            uint32_t circleVertex1 = circleIndices[i];
            uint32_t circleVertex2 = circleIndices[(i + 1) % circleIndices.size()];

            // Find the closest boundary vertex to this circle edge
            if (!boundaryVertices.empty()) {
                Ogre::Vector3 circlePos1 = vertices[circleVertex1].pos;
                Ogre::Vector3 circlePos2 = vertices[circleVertex2].pos;
                Ogre::Vector3 edgeCenter = (circlePos1 + circlePos2) * 0.5f;

                float minDist = std::numeric_limits<float>::max();
                uint32_t closestBoundary = boundaryVertices[0];

                for (uint32_t boundaryVertex : boundaryVertices) {
                    Ogre::Vector3 boundaryPos = vertices[boundaryVertex].pos;
                    float dist = (Ogre::Vector3(edgeCenter.x - boundaryPos.x, 0, edgeCenter.z - boundaryPos.z)).length();
                    if (dist < minDist) {
                        minDist = dist;
                        closestBoundary = boundaryVertex;
                    }
                }

                // Create triangle connecting circle edge to boundary
                triangles.emplace_back(circleVertex1, circleVertex2, closestBoundary);
            }
        }
    }

    // Generate the base grid triangles (avoiding removed quads)
    void WaterMeshGenerator::generateGridTriangles(ExplorationMapData* mapData) {
        const AV::uint32 width = mapData->width;
        const AV::uint32 height = mapData->height;
        const AV::uint32 seaLevel = mapData->seaLevel;

        std::vector<AV::uint8> resolvedFlags;
        resolvedFlags.resize(gridWidth * gridHeight, 0);

        for(int y = 0; y < height; y++){
            for(int x = 0; x < width; x++){
                if(mapData->voxelBuffer == 0) break;
                float xFloat = (float(x) / float(width)) * gridWidth;
                float yFloat = (float(y) / float(height)) * gridHeight;
                int xa = int(std::floor(xFloat));
                int ya = int(std::floor(yFloat));

                if(xa < 0 || ya < 0 || xa >= gridWidth || ya >= gridHeight) continue;

                const AV::uint32* fullFlags = FULL_PTR_FOR_COORD_SECONDARY(mapData, WRAP_WORLD_POINT(x, y));

                resolvedFlags[xa + ya * gridWidth] |= (*fullFlags & TEST_CHANGE_WATER_FLAG) ? 1 : 0;
            }
        }

        for (int y = 0; y < gridHeight - 1; ++y) {
            for (int x = 0; x < gridWidth - 1; ++x) {
                uint64_t quadKey = makeQuadKey(x, y);

                // Skip quads that are removed due to holes
                if (removedQuads.count(quadKey) > 0) {
                    continue;
                }

                int reverseWidth = x + 1;
                int reverseHeight = gridHeight - y - 2;
                AV::uint8 vertFlag = 0;
                if(reverseWidth >= 0 && reverseWidth < gridWidth && reverseHeight < gridHeight){
                    vertFlag = resolvedFlags[reverseWidth + reverseHeight * gridWidth];
                }

                // Create quad vertices
                uint32_t v0 = getVertexIndex(x, y, vertFlag);
                uint32_t v1 = getVertexIndex(x + 1, y, vertFlag);
                uint32_t v2 = getVertexIndex(x + 1, y + 1, vertFlag);
                uint32_t v3 = getVertexIndex(x, y + 1, vertFlag);

                // Create two triangles for the quad
                triangles.emplace_back(v0, v1, v2);
                triangles.emplace_back(v0, v2, v3);
            }
        }
    }

    WaterMeshGenerator::MeshData WaterMeshGenerator::generateMesh(int width, int height, const std::vector<Hole>& holes, ExplorationMapData* mapData, float cellSize) {
        // Initialize
        this->gridWidth = width;
        this->gridHeight = height;
        this->cellSize = cellSize;

        vertices.clear();
        triangles.clear();
        removedQuads.clear();
        vertexMap.clear();

        // Mark quads that intersect with holes as removed
        for (const Hole& hole : holes) {
            for (int y = 0; y < gridHeight - 1; ++y) {
                for (int x = 0; x < gridWidth - 1; ++x) {
                    if (quadIntersectsCircle(x, y, hole)) {
                        removedQuads.insert(makeQuadKey(x, y));
                    }
                }
            }
        }

        // Generate the main grid triangles
        generateGridTriangles(mapData);

        // Generate holes and triangulate around them
        for (const Hole& hole : holes) {
            //std::vector<uint32_t> circleIndices = generateCircleVertices(hole);
            //triangulateAroundHole(hole, circleIndices);
        }

        return MeshData{vertices, triangles};
    }

    /*
    // Example usage function
    MeshData createGridMeshWithHoles(int width, int height, const std::vector<Hole>& holes) {
        GridMeshGenerator generator;
        return generator.generateMesh(width, height, holes, 1.0f);
    }
    */

}
