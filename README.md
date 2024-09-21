# CS335 Project

This repository contains a compiler for a subset of Python, designed for educational purposes. It supports features like basic data types, classes, loops, and functions, generating x86 assembly code from Python source files.

## Running Instructions

### Prerequisites
- **Bison** and **Flex** installed on your system
- **GCC** for compiling the generated assembly code

### Compilation
1. Navigate to the `src` directory:
   ```bash
   cd src
2. Compile the Bison and Lexer files:
   ```bash
   make
### Running the Compiler
   ```bash
   ./final --input <python file path>
   ```
* **Options**:
    - `--help`: List all available options
    - `--AST <filename>`: Output the Abstract Syntax Tree (AST) to the specified dot file.
    - `--TAC <filename>`: Output Three Address Code (TAC) to the specified file.
    - `--symboltable <filename>`: Output the Symbol Table to the specified file.
    - `--x86 <filename>`: Output x86 assembly code to the specified file, default is `../outputs/output.s`.
    - `--verbose`: Display debug information.

### Generate and Run the executable
   ```bash
   gcc ../outputs/output.s
   ./a.out
   ```

## Features Supported

  - Primitive data types: `int`, `bool`, `str`
  - Static 1D lists
  - Classes and constructors
  - Class Inheritance
  - Loops, breaks, and if-else statements
  - Functions and recursion
  - Type checking for function returns and operations


## For More Details
For additional information, please refer to the documentation in the `doc` directory. You can also explore the source code and comment sections for insights on specific implementations and features.






