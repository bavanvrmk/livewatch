#include <stdint.h>

// Define the address of our watched variable
// In the SoC, this maps to the WATCH_ADDR parameter
#define WATCH_ADDR 0x00001000

// A shared memory variable
volatile uint32_t *shared_counter = (volatile uint32_t *)WATCH_ADDR;

// Mock function representing what Core 0 would run
void core0_main() {
    while (1) {
        // Read-modify-write (Simulating a race condition if not locked)
        uint32_t val = *shared_counter;
        
        // Simulating some delay or other work
        for (int i = 0; i < 10; i++) {
            asm volatile("nop");
        }
        
        // Write back
        *shared_counter = val + 1;
    }
}

// Mock function representing what Core 1 would run
void core1_main() {
    while (1) {
        // Read-modify-write
        uint32_t val = *shared_counter;
        
        // Simulating some delay
        for (int i = 0; i < 5; i++) {
            asm volatile("nop");
        }
        
        // Write back
        // Core 1 might write the same value as Core 0 if they read at the same time
        *shared_counter = val + 1;
    }
}

// In a bare-metal environment, the bootloader or crt0 
// would branch Core 0 to core0_main and Core 1 to core1_main.
int main() {
    // Initialization code...
    *shared_counter = 0;
    
    // (Execution diverges to the respective core main functions)
    return 0;
}
