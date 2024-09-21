%{
#include <bits/stdc++.h>
#include "parser.tab.h"
using namespace std;



#define MAX_DEPTH 100
#define YY_DECL int orig_yylex(void)
//indentation Stack
int indent_stack[MAX_DEPTH] ;
int level = 0 ;

int nesting = 0 ;
// stack for Braces
int nest_level = 0 ;
int enterLstart = 1 ;

// int last_newLine = 0 ;
// bool eof_flag = false ;

void NestingHandler(int a);
void process_indent(char* line); 
static void display_error(const char *msg);
void EndHandler() ;
int countt = 0;


/* The scanner state: based roughly on the code in the CPython tokeniser */
    int atbol;                  /* Nonzero if at begin of new line */
    int endbol;                 /* Nonzero if at end of EOF */
    int pendin;                 /* Pending indents (if > 0) or dedents (if < 0) */
    bool seen_endmarker;        /* Have we sent the ENDMARKER token yet? */

int NO_TOKEN = -1;
int pending_token = NO_TOKEN;          /* One token can be queued while processing indent/dedent */

int debug_mode = 0 ;

void debbugger1(string msg, int val) {
  // cout << "ENDMARKER IS : " << ENDMARKER << endl ;
  if(debug_mode)
    cout << "DEBUG: " << msg << val << endl ;
}
//Python Lexer
%}
/* We want to wrap the generated lexer with our own function */



%x LStart

%option noyywrap
%option nodefault
%option yylineno



TextBlocksingle           [\"][\"][\"]([^\"]|[\"]([^\"]|[\"][^\"]))*[\"][\"][\"]
TextBlockdouble           [\'][\'][\']([^\']|[\'][^\']|[\'][\'][^\'])*[\'][\'][\']


number    {integerUnsign}|{longintegerUnsign}|{floatnumber}|{imagnumber}

imagnumber     {imaghead}[jJ]
imaghead       {floatnumber}|{decintegerUnsign}

floatnumber    {pointfloat}|{expfloat}
expfloat       {expfloat_1}{exponent}
expfloat_1     {expfloat_2}|{pointfloat}
expfloat_2     {nonzero}{digit}*
pointfloat     {pointfloat_1}|{pointfloat_2}
pointfloat_1   {decintegerUnsign}?{fraction}
pointfloat_2   {decintegerUnsign}\.
fraction       \.{digit}+
exponent       [eE][+-]?{digit}+

longintegerUnsign    {integerUnsign}[lL]
integerUnsign        {decintegerUnsign}|{octintegerUnsign}|{hexintegerUnsign}|{binintegerUnsign}
decintegerUnsign     {nzointeger}|0
/* without 00000 */

nzointeger     {nonzero}{digit}*
hexintegerUnsign     0[xX]{hexdigit}+
octintegerUnsign     0[oO]{octdigit}+
binintegerUnsign     0[bB]{bindigit}+

digit          [0-9]
nonzero        [1-9]
octdigit       [0-7]
bindigit       [01]
hexdigit       [0-9a-fA-F]

bytesprefix    ("b"|"B"|"br"|"Br"|"bR"|"BR"|"rb"|"rB"|"Rb"|"RB")

%s File_End
%s DedentRelease

%%
              if(enterLstart) {
                BEGIN(LStart) ;
                enterLstart = 0 ;
              }

{integerUnsign} {
             yylval.intNumber = atoi(yytext);
             return LITERAL_INT;
           }
{floatnumber} {
             yylval.fltNumber = atof(yytext);
             return LITERAL_FLOAT;
           }


(?# higiygyugyuguyghhbhjb
hiuhiu
y)

<LStart>[ \t]*("#"[^\n\f\r]*)?[\f\n] {
  //ignore blank lines
  //but it will end the logical line
  if (!nest_level && nesting){
    nesting = 0 ;
    return NEWLINE;
  }
}

<LStart>[ \t]*/.  {
                // calculate first non space character
                process_indent(yytext) ;
                BEGIN(INITIAL) ;
}

<LStart>[^\t]  {
      // calculate first non space character
      process_indent(yytext) ;
      BEGIN(INITIAL) ;
      REJECT;
}

"\\"[ \t]*[\f\n] /*fdfdfdfdfd*/ {
  // ignore to give the parser NEWLINE;
  // but turn on nesting
  debbugger1("Nesting", 0) ;
  nesting = 1 ;
}


^{bytesprefix}?({TextBlocksingle}|{TextBlockdouble}) {
  // Handle Comments
  BEGIN(LStart) ;

}

{bytesprefix}({TextBlocksingle}|{TextBlockdouble}|\"[^\"\n\f\r]*\"|\'[^\'\n\f\r]*\') {
  //give the lexeme to the parser also handle byte strings
  yylval.sval = strdup(yytext) ;
  return BYTESTRING;
}

{TextBlocksingle}|{TextBlockdouble}|\"[^\"\n\f\r]*\"|\'[^\'\n\f\r]*\' {
  //give the lexeme to the parser also handle byte strings
  yylval.sval = strdup(yytext) ;
  return STRING;
}

(\"[^\"\n\f\r]*|\'[^\'\n\f\r]*)"\\"[\t]*\n {
  int last = yyleng - 1;
  while ((last >= 0) &&
        (yytext[last] != '\\')) {
    last-- ;
  }
  last--;

  // this may be incorrect
  while ((last >= 0)) {
    unput(yytext[last]);
    last-- ;
  }

  debbugger1("Multiline String Explicit Joined", 0) ;
}

"False"               { return KEY_FALS; }

"None"                { return KEY_NONE; }

"True"                { return KEY_TRU; }

"as"                  { return KEY_AS; }

"assert"              { return KEY_ASSERT; }

"async"               { return KEY_ASYNC; }

"await"               { return KEY_AWAIT; }

"break"               { return KEY_BREAK; }
"class"               { return KEY_CLASS; }
"continue"            { return KEY_CONTINUE; }
"def"                 { return KEY_DEF; }
"del"                 { return KEY_DEL; }
"elif"                { return KEY_ELIF; }
"else"                { return KEY_ELSE; }
"except"              { return KEY_EXCEPT; }
"finally"             { return KEY_FINALLY; }
"for"                 { return KEY_FOR; }
"from"                { return KEY_FROM; }
"global"              { return KEY_GLOBAL; }
"if"                  { return KEY_IF; }
"import"              { return KEY_IMPORT; }
"in"                  { return KEY_IN; }
"is"                  { return KEY_IS; }
"lambda"              { return KEY_LAMBDA; }
"nonlocal"            { return KEY_NONLOCAL; }
"pass"                { return KEY_PASS; }
"raise"               { return KEY_RAISE; }
"return"              { return KEY_RETURN; }
"try"                 { return KEY_TRY; }
"while"               { return KEY_WHILE; }
"with"                { return KEY_WITH; }
"yield"               { return KEY_YIELD;}

"int"                 { return KEY_INT; }

"float"               { return KEY_FLOAT; }
"str"                 { return KEY_STR; }
"bool"                { return KEY_BOOL; }
"list"         { return KEY_LIST; }

"and"                 { return OP_LOGICAL_AND; }
"not"                 { return OP_LOGICAL_NOT; }
"or"                  { return OP_LOGICAL_OR; }
"+"                   { return OP_PLUS; }
"-"                   { return OP_MINUS; }
"*"                   { return OP_TIMES; }
"/"                   { return OP_DIVIDE; }
"//"                  { return OP_FLOOR; }
"%"                   { return OP_MOD; }
"**"                  { return OP_EXP; }
"<<"                  { return OP_LSHIFT; }
">>"                  { return OP_RSHIFT; }
"&"                   { return OP_BITWISE_AND; }
"|"                   { return OP_BITWISE_OR; }
"^"                   { return OP_BITWISE_XOR; }
"~"                   { return OP_BITWISE_NOT; }
":="                  { return OP_WALRUS;}
"<"                   { return OP_LESS; }
">"                   { return OP_GREATER; }
"<="                  { return OP_LESS_EQ; }
">="                  { return OP_GREATER_EQ; }
"=="                  { return OP_EQ; }
"!="                  { return OP_NOT_EQ; }


"("                   { NestingHandler(0) ;return DELIM_LPAR; }
")"                   { NestingHandler(1) ;return DELIM_RPAR; }
"["                   { NestingHandler(0) ;return DELIM_LBRACKET; }
"]"                   { NestingHandler(1) ;return DELIM_RBRACKET; }
"{"                   { NestingHandler(0) ;return DELIM_LBRACE; }
"}"                   { NestingHandler(1) ;return DELIM_RBRACE; }

","                   { return DELIM_COMMA; }

":"                   { return DELIM_COLON; }

"."                   { return DELIM_DOT; }
";"                   { return DELIM_SEMICOLON; }
"@"                   { return DELIM_OP_AT; }
"="                   { return DELIM_ASSIGN; }
"->"                  { return DELIM_ARROW; }
"+="                  { return DELIM_PLUS_EQ; }
"-="                  { return DELIM_MINUS_EQ; }
"*="                  { return DELIM_TIMES_EQ; }
"/="                  { return DELIM_DIVIDE_EQ; }
"//="                 { return DELIM_FLOOR_EQ; }
"%="                  { return DELIM_MOD_EQ; }
"@="                  { return DELIM_MATMUL_EQ; }
"&="                  { return DELIM_AND_EQ; }
"|="                  { return DELIM_OR_EQ; }
"^="                  { return DELIM_XOR_EQ; }
">>="                 { return DELIM_RSHIFT_EQ; }
"<<="                 { return DELIM_LSHIFT_EQ; }
"**="                 { return DELIM_EXP_EQ; }


      /*
      some reserved IDENTIFIERS
      */
"self"               { yylval.sval = strdup(yytext); return RES_ID_SELF; }
"__init__"           { yylval.sval = strdup(yytext); return RES_ID_INIT; }
"main"               { yylval.sval = strdup(yytext); return RES_ID_MAIN; }
"__name__"               { yylval.sval = strdup(yytext); return RES_ID_NAME; }
  




[\n\f] {
  /* for newline */
  // debbugger("TOKEN: Newline", 0) ;
  if (!nest_level){
    BEGIN(LStart) ;
    return NEWLINE;
  }
}


"#"[^\n\f\r]* {
  // Handle Comments
  debbugger1("Comment", 0) ;
}


<<EOF>> {
  if (nest_level) {
    display_error("Unmatched Braces") ;
  }

  EndHandler() ;
  return ENDMARKER;
}


[a-zA-Z_][a-zA-Z0-9_]*   { 
  /* for IDENTIFIERS */
  yylval.sval = strdup(yytext) ;
  return IDENTIFIER;  
}


[ \t]+ {
  // cout << "DEBUG: Space" << endl ;
  // ignore whitespaces
}

. {
  // Handle Error
  display_error("Invalid Character") ;
}

%%

void EndHandler() {
  endbol = 1;
}

static void display_error(const char *msg)
{
    /* fprintf (stderr, "%d.%d-%d.%d:", yylloc.first_line, yylloc.first_column,
                                     yylloc.last_line,  yylloc.last_column); */
    fprintf(stderr, "Error:%d lexical error with [%s]: %s\n", yylineno, yytext, msg);
    /* line ki facility dalni hai  */
    exit(EXIT_FAILURE);
    /* dont know what it is */
}



void NestingHandler(int a) {
  if (a == 0) {
    /* turn on nesting */
    nesting = 1 ;
    ++nest_level ;
  } else {
    if (nest_level) {
      --nest_level ;

    if(nest_level == 0)
      nesting = 0 ;
    }
    else {
      display_error("Unmatched Braces") ;
    }
  }

}
string TOKENString(int token) {
  switch (token) {
    case NEWLINE: return "NEWLINE" ;
    case INDENT: return "INDENT" ;
    case DEDENT: return "DEDENT" ;
    case LITERAL_INT: return "LITERAL_INT" ;
    case LITERAL_FLOAT: return "LITERAL_FLOAT" ;
    case STRING: return "STRING" ;
    case IDENTIFIER: return "IDENTIFIER" ;

    case OP_BITWISE_AND: return "OP_BITWISE_AND" ;
    case OP_BITWISE_NOT: return "OP_BITWISE_NOT" ;
    case OP_BITWISE_OR: return "OP_BITWISE_OR" ;
    case OP_BITWISE_XOR: return "OP_BITWISE_XOR" ;
    case OP_DIVIDE: return "OP_DIVIDE" ;
    case OP_EQ: return "OP_EQ" ;
    case OP_TIMES: return "OP_TIMES" ;
    case OP_EXP: return "OP_EXP" ;
    case OP_GREATER: return "OP_GREATER" ;
    case OP_GREATER_EQ: return "OP_GREATER_EQ" ;
    case OP_LSHIFT: return "OP_LSHIFT" ;
    case OP_LESS: return "OP_LESS" ;
    case OP_LESS_EQ: return "OP_LESS_EQ" ;
    case OP_LOGICAL_AND: return "OP_LOGICAL_AND" ;
    case OP_LOGICAL_NOT: return "OP_LOGICAL_NOT" ;

    case DELIM_AND_EQ: return "DELIM_AND_EQ" ;
    case DELIM_ARROW: return "DELIM_ARROW" ;
    case DELIM_ASSIGN: return "DELIM_ASSIGN" ;
    case DELIM_COLON: return "DELIM_COLON" ;
    case DELIM_COMMA: return "DELIM_COMMA" ;
    case DELIM_DOT: return "DELIM_DOT" ;
    case DELIM_FLOOR_EQ: return "DELIM_FLOOR_EQ" ;
    case DELIM_LBRACE: return "DELIM_LBRACE" ;
    case DELIM_LBRACKET: return "DELIM_LBRACKET" ;
    case DELIM_LPAR: return "DELIM_LPAR" ;
    case DELIM_MINUS_EQ: return "DELIM_MINUS_EQ" ;
    case DELIM_MOD_EQ: return "DELIM_MOD_EQ" ;
    case DELIM_OR_EQ: return "DELIM_OR_EQ" ;
    case DELIM_PLUS_EQ: return "DELIM_PLUS_EQ" ;
    case DELIM_RBRACE: return "DELIM_RBRACE" ;
    case DELIM_RBRACKET: return "DELIM_RBRACKET" ;
    case DELIM_RPAR: return "DELIM_RPAR" ;
    case DELIM_SEMICOLON: return "DELIM_SEMICOLON" ;
    case DELIM_TIMES_EQ: return "DELIM_TIMES_EQ" ;
    case DELIM_XOR_EQ: return "DELIM_XOR_EQ" ;
    case DELIM_EXP_EQ: return "DELIM_EXP_EQ" ;
    case DELIM_MATMUL_EQ: return "DELIM_MATMUL_EQ" ;
    case DELIM_RSHIFT_EQ: return "DELIM_RSHIFT_EQ" ;
    case DELIM_LSHIFT_EQ: return "DELIM_LSHIFT_EQ" ;
    case DELIM_OP_AT: return "DELIM_OP_AT" ;

    case KEY_YIELD: return "KEY_YIELD" ;
    case KEY_WITH: return "KEY_WITH" ;
    case KEY_WHILE: return "KEY_WHILE" ;
    case KEY_TRY: return "KEY_TRY" ;
    case KEY_RETURN : return "KEY_RETURN" ;
    case KEY_BOOL: return "KEY_BOOL" ;
    case KEY_STR: return "KEY_STR" ;
    case KEY_FLOAT: return "KEY_FLOAT" ;
    case KEY_INT: return "KEY_INT" ;
    case KEY_LIST: return "KEY_LIST" ;
    case KEY_FALS: return "KEY_FALS" ;
    case KEY_TRU: return "KEY_TRU" ;
    case KEY_BREAK: return "KEY_BREAK" ;
    case KEY_AS: return "KEY_AS" ;
    case KEY_ASSERT: return "KEY_ASSERT" ;
    case KEY_ASYNC: return "KEY_ASYNC" ;
    case KEY_AWAIT: return "KEY_AWAIT" ;
    case KEY_CLASS: return "KEY_CLASS" ;
    case KEY_CONTINUE: return "KEY_CONTINUE" ;
    case KEY_DEF: return "KEY_DEF" ;
    case KEY_DEL: return "KEY_DEL" ;
    case KEY_ELIF: return "KEY_ELIF" ;
    case KEY_ELSE: return "KEY_ELSE" ;
    case KEY_EXCEPT: return "KEY_EXCEPT" ;
    case KEY_FINALLY: return "KEY_FINALLY" ;
    case KEY_FOR: return "KEY_FOR" ;
    case KEY_FROM: return "KEY_FROM" ;
    case KEY_GLOBAL: return "KEY_GLOBAL" ;
    case KEY_IF: return "KEY_IF" ;
    case KEY_IMPORT: return "KEY_IMPORT" ;
    case KEY_IN: return "KEY_IN" ;
    case KEY_IS: return "KEY_IS" ;
    case KEY_LAMBDA: return "KEY_LAMBDA" ;
    case KEY_NONE: return "KEY_NONE" ;
    case KEY_NONLOCAL: return "KEY_NONLOCAL" ;
    case KEY_PASS: return "KEY_PASS" ;
    case KEY_RAISE: return "KEY_RAISE" ;

    case ENDMARKER: return "ENDMARKER" ;
    default: return "TOKEN" ;
  }
}
 int yylex(void)
{
    int token = NO_TOKEN;
    if (seen_endmarker){
      yyterminate();
    }
    //First check for any pending indents or dedents 
    if (pendin < 0) {
        pendin ++;
        token = DEDENT;
    }
    else if (pendin > 0) {
        pendin --;
        token = INDENT;
    }
    // Next check for a pending token 
    else if (pending_token != NO_TOKEN) {
        token = pending_token;
        pending_token = NO_TOKEN;
    }
    // Finally, call the actual scanner 
    else {
        token = orig_yylex();
        if (token == NEWLINE) {
            atbol = true;
        }
        else if (atbol || endbol) {
            if(token == ENDMARKER)
            {
              /* make a empty char* */
              char* line = NULL;
              yyleng = 0;
              process_indent(line);
              pending_token = token;
              if(atbol) token = yylex();
              else token = NEWLINE;
            }
            else{
              pending_token = token;
              token = yylex();
            }
          atbol = false;
            
        }
        //if we get here then nothing is pending, so just return the token 
    }
    if (token == ENDMARKER){
      seen_endmarker = true;  //Wrap up the next time around 
    }
    debbugger1("TOKEN: " + TOKENString(token) + " " + to_string(token) + " ", countt++) ;
    return token;
}

unsigned int white_count(char* line) {
  unsigned int count = 0 ;
  int maxl = yyleng ;
  for (int i = 0; i < maxl; i++) {
    if (line[i] == ' ') {
      count++ ;
    } else {
      break ;
    }
  }
  return count ;
}

void process_indent(char* line) {

  if (nesting)
    /* Ignore indents while nested. */
    return;

  unsigned int indent = white_count(line) ;

  if (indent == indent_stack[level]) {
    /* do nothing if equal */
  }

  if (indent > indent_stack[level]) {
    assert(level+1 < MAX_DEPTH) ;
    pendin++;
    indent_stack[++level] = indent ;
  }

  while (indent < indent_stack[level]) {
    --level ;
    pendin--;
    /* correct it  */
  }

  if(indent != indent_stack[level])
  {
    /* Handle error */
  }

  assert(level >= 0) ;
}
    