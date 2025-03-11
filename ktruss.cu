#include <cuda.h>
#include <stdio.h>
#include <vector>

// CSR format for the graph
struct Graph {
    int* rowPtr;  // Row pointers
    int* colIdx;  // Column indices
    int numNodes;
    int numEdges;
    std::vector<std::pair<int, int>> edges; // Explicit edge list
};

// Kernel to count triangles per edge
__global__ void countTriangles(int* rowPtr, int* colIdx, int* edgeSrc, int* edgeDst, int* support, int numEdges) {
    int edgeIdx = blockIdx.x * blockDim.x + threadIdx.x;
    if (edgeIdx >= numEdges) return;

    int u = edgeSrc[edgeIdx];
    int v = edgeDst[edgeIdx];
    int uStart = rowPtr[u], uEnd = rowPtr[u + 1];
    int vStart = rowPtr[v], vEnd = rowPtr[v + 1];
    int count = 0;

    // Use two-pointer technique for efficiency
    int i = uStart, j = vStart;
    while (i < uEnd && j < vEnd) {
        int uNeighbor = colIdx[i];
        int vNeighbor = colIdx[j];
        if (uNeighbor == v) { i++; continue; } // Skip v in u's list
        if (vNeighbor == u) { j++; continue; } // Skip u in v's list
        if (uNeighbor == vNeighbor) {
            count++;
            i++;
            j++;
        } else if (uNeighbor < vNeighbor) {
            i++;
        } else {
            j++;
        }
    }
    support[edgeIdx] = count;
}

// Main k-truss function
void kTruss(Graph& g, int k) {
    // Populate edge arrays
    std::vector<int> edgeSrc(g.numEdges), edgeDst(g.numEdges);
    for (int i = 0; i < g.numEdges; i++) {
        edgeSrc[i] = g.edges[i].first;
        edgeDst[i] = g.edges[i].second;
    }

    // Debug: Print edges
    printf("Debug - Edge List:\n");
    for (int i = 0; i < g.numEdges; i++) {
        printf("Edge %d: %d-%d\n", i, edgeSrc[i], edgeDst[i]);
    }

    // Allocate GPU memory
    int *d_rowPtr, *d_colIdx, *d_edgeSrc, *d_edgeDst, *d_support;
    cudaMalloc(&d_rowPtr, (g.numNodes + 1) * sizeof(int));
    cudaMalloc(&d_colIdx, (g.rowPtr[g.numNodes]) * sizeof(int));
    cudaMalloc(&d_edgeSrc, g.numEdges * sizeof(int));
    cudaMalloc(&d_edgeDst, g.numEdges * sizeof(int));
    cudaMalloc(&d_support, g.numEdges * sizeof(int));

    cudaMemcpy(d_rowPtr, g.rowPtr, (g.numNodes + 1) * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_colIdx, g.colIdx, (g.rowPtr[g.numNodes]) * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_edgeSrc, edgeSrc.data(), g.numEdges * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_edgeDst, edgeDst.data(), g.numEdges * sizeof(int), cudaMemcpyHostToDevice);

    // Launch kernel
    int threads = 256;
    int blocks = (g.numEdges + threads - 1) / threads;
    countTriangles<<<blocks, threads>>>(d_rowPtr, d_colIdx, d_edgeSrc, d_edgeDst, d_support, g.numEdges);
    cudaDeviceSynchronize();

    // Check for CUDA errors
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) printf("CUDA Error after kernel launch: %s\n", cudaGetErrorString(err));
    err = cudaDeviceSynchronize();
    if (err != cudaSuccess) printf("CUDA Error after synchronize: %s\n", cudaGetErrorString(err));

    // Copy supports back to host
    std::vector<int> support(g.numEdges);
    cudaMemcpy(support.data(), d_support, g.numEdges * sizeof(int), cudaMemcpyDeviceToHost);
    err = cudaGetLastError();
    if (err != cudaSuccess) printf("CUDA Error after memcpy: %s\n", cudaGetErrorString(err));

    // Debug: Print supports before pruning
    printf("Debug - Supports Before Pruning:\n");
    for (int i = 0; i < g.numEdges; i++) {
        printf("Edge %d: %d-%d, Support: %d\n", i, edgeSrc[i], edgeDst[i], support[i]);
    }

    // Iterative pruning for k-truss
    for (int iter = 0; iter < g.numEdges; iter++) {
        bool changed = false;
        for (int i = 0; i < g.numEdges; i++) {
            if (support[i] >= 0 && support[i] < k - 2) {
                support[i] = -1; // Mark for removal
                changed = true;
            }
        }
        if (!changed) break;
    }

    // Print remaining edges
    printf("3-Truss Edges:\n");
    for (int i = 0; i < g.numEdges; i++) {
        if (support[i] >= k - 2) {
            printf("Edge %d: %d-%d, Support: %d\n", i, edgeSrc[i], edgeDst[i], support[i]);
        }
    }

    cudaFree(d_rowPtr); cudaFree(d_colIdx); cudaFree(d_edgeSrc); cudaFree(d_edgeDst); cudaFree(d_support);
}

int main() {
    // Hardcoded small graph: 4 nodes, 5 edges
    int numNodes = 4;
    int numEdges = 5;
    std::vector<int> rowPtr = {0, 2, 4, 6, 7}; // CSR row pointers
    std::vector<int> colIdx = {1, 2, 0, 2, 0, 1, 3, 3}; // CSR column indices (undirected)
    std::vector<std::pair<int, int>> edges = {{0, 1}, {0, 2}, {1, 2}, {1, 3}, {2, 3}}; // Explicit edge list

    Graph g = {rowPtr.data(), colIdx.data(), numNodes, numEdges, edges};
    kTruss(g, 3); // Find 3-truss
    return 0;
}
