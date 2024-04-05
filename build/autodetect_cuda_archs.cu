		#include <stdio.h>
		int main() {
		int count = 0; 
		if (cudaSuccess != cudaGetDeviceCount(&count)) { return -1; }
		if (count == 0) { return -1; }
		for (int device = 0; device < count; ++device) {
			cudaDeviceProp prop; 
			bool is_unique = true; 
			if (cudaSuccess == cudaGetDeviceProperties(&prop, device)) {
				for (int device_1 = device - 1; device_1 >= 0; --device_1) {
					cudaDeviceProp prop_1; 
					if (cudaSuccess == cudaGetDeviceProperties(&prop_1, device_1)) {
						if (prop.major == prop_1.major && prop.minor == prop_1.minor) {
							is_unique = false; 
							break; 
						}
					}
					else { return -1; }
				}
				if (is_unique) {
					fprintf(stderr, "%d%d", prop.major, prop.minor);
				}
			}
			else { return -1; }
		}
		return 0; 
		}
		