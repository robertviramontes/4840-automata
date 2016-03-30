#include <stdio.h>
#include <stdlib.h>

const int GRID_WIDTH = 10;
const int GRID_HEIGHT = 10;

int ** generate_grid() {
    int i, j;
    int ** grid = (int **) malloc(sizeof(int *) * GRID_HEIGHT);

    for (i = 0; i < GRID_HEIGHT; i++) {
        grid[i] = (int *) malloc(sizeof(int) * GRID_WIDTH);
        for (j = 0; j < GRID_WIDTH; j++) {
            grid[i][j] = 0;
        }
    }

    return grid;
}

void free_grid(int ** grid) {
    int i;

    for (i = 0; i < GRID_HEIGHT; i++) {
        free(grid[i]);
    }

    free(grid);
}

void print_grid(int ** grid) {
    int i, j;
    for (i = 0; i < GRID_HEIGHT; i++) {
        for (j = 0; j < GRID_WIDTH; j++) {
            if (grid[i][j] == 0) {
                printf(" _");
            } else {
                printf(" *");
            }
        }
        printf("\n");
    }
}

int ** next_generation(int ** grid) {
    int ** next_grid = generate_grid();
    int i, j; // i = row, j = col
    for (i = 0; i < GRID_HEIGHT; i++) {
        for (j = 0; j < GRID_WIDTH; j++) {

            // Count neighbors
            int y = i > 0 ? i - 1 : i; 
            int count = 0;
            for (; y < GRID_HEIGHT && y < i + 2; y++) {
                int x = j > 0 ? j - 1 : j;
                for (; x < GRID_WIDTH && x < j + 2 ; x++) {
                    count += grid[y][x];
                }
            }

            count -= grid[i][j];

            if (grid[i][j] == 1) {
                if (count == 2 || count == 3) {
                    next_grid[i][j] = 1;
                } else {
                    next_grid[i][j] = 0;
                }
            } else if (grid[i][j] == 0 && count == 3) {
                next_grid[i][j] = 1;
            } else {
                next_grid[i][j] = 0;
            }
        }
    }

    return next_grid;
}

int main(void) {
    int ** grid = generate_grid();

    // Glider
    grid[0][1] = 1;
    grid[1][2] = 1;
    grid[2][0] = 1;
    grid[2][1] = 1;
    grid[2][2] = 1;

    while (1) {
        print_grid(grid);
        getchar();
        int ** next_grid = next_generation(grid);
        free_grid(grid);
        grid = next_grid;
    }

    free_grid(grid);
}
