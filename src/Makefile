all : final
final : lex.yy.c parser.tab.h parser.tab.c
	g++ -o final lex.yy.c parser.tab.c 
lex.yy.c : lexer.l parser.tab.h
	flex lexer.l
parser.tab.h parser.tab.c : parser.y
	bison -d -t parser.y
clean : 
	rm -f final lex.yy.c parser.tab.h parser.tab.c  *.out *.txt *.csv *.txt *.dot



	