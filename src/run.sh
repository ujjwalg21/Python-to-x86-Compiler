./final --input ../tests/$1 --symboltable sym.csv --TAC 3ac.txt --AST ast.dot
gcc ../outputs/output.s
./a.out