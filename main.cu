#include <iostream>
#include "KittenLBVH/lbvh.cuh"

#include <unordered_set>

void main(int arg, char** args)
{
    // Tests the LBVH with a simple test case of 100k objects.

    const int   N = 100000;
    const float R = 0.001f;

    printf("Generating Data...\n");
    std::vector<Kitten::Bound<3, float>> points(N);

    srand(1);
    for (size_t i = 0; i < N; i++) {
        Kitten::Bound<3, float> b(Kitten::vec3(rand() / (float)RAND_MAX,
                                               rand() / (float)RAND_MAX,
                                               rand() / (float)RAND_MAX));
        b.pad(R);
        points[i] = b;
    }

    thrust::device_vector<Kitten::Bound<3, float>> d_points(points.begin(),
                                                            points.end());

    thrust::device_vector<Kitten::ivec2> d_res(100 * N);
    cudaDeviceSynchronize();

    // Build BVH
    Kitten::LBVH bvh;
    printf("Building LBVH...\n");
    bvh.compute(thrust::raw_pointer_cast(d_points.data()), N);
    cudaDeviceSynchronize();

    // Query BVH
    printf("Querying LBVH...\n");
    int numCols =
        bvh.query(thrust::raw_pointer_cast(d_res.data()), d_res.size());

    // Print results
    printf("Getting results...\n");
    thrust::host_vector<Kitten::ivec2> res(d_res.begin(),
                                           d_res.begin() + numCols);

    printf("%d collision pairs found on GPU.\n", res.size());
    // printf("GPU:\n");
    // for (size_t i = 0; i < res.size(); i++)
    // 	printf("%d %d\n", res[i].x, res[i].y);

    // Brute force compute the same result
    std::unordered_set<Kitten::ivec2> resSet;
    bool                              good = true;

    for (size_t i = 0; i < res.size(); i++) {
        Kitten::ivec2 a = res[i];
        if (a.x > a.y)
            std::swap(a.x, a.y);
        if (!resSet.insert(a).second) {
            printf("Error: Duplicate result\n");
            good = false;
        }
    }

    int numCPUFound = 0;
    printf("\nRunning brute force CPU collision detection...\n");
    for (int i = 0; i < N; i++)
        for (int j = i + 1; j < N; j++)
            if (points[i].intersects(points[j])) {
                numCPUFound++;
                if (resSet.find(Kitten::ivec2(i, j)) == resSet.end()) {
                    printf(
                        "Error: CPU result %d %d not found in GPU "
                        "result.\n",
                        i,
                        j);
                    good = false;
                }
            }

    if (numCPUFound != res.size()) {
        printf("Error: CPU and GPU results do not match\n");
        good = false;
    }

    printf("%d collision pairs found on CPU.\n", numCPUFound);
    printf(good ? "CPU and GPU results match.\n" :
                  "CPU and GPU results MISMATCH!\n");

    bvh.bvhSelfCheck();
}