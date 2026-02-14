# Diff

A simplified implementation of the Unix `diff` program in x86 assembly.

## Features
- Line-by-line comparison of two strings
- Shows changes between strings (`c` output for changed lines)
- Supports `-i` (ignore case) and `-B` (ignore blank lines) options
- Input can be hardcoded or provided via command-line arguments

## Building & Running

To compile and run your assembly program:

```bash
# Compile into executable
gcc -no-pie -o diff diff.s

```bash
# Basic run (hardcoded text)
./diff

# Run with command-line options
./diff -i -B

