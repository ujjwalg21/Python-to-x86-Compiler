%{
// updates - backpaching me while, for ka samajh raha tha
// assignable expressions and list expressions ko or clear karne ka sochraha tha
#include<bits/stdc++.h>
#include <string>
using namespace std;
int yylex();
void yyerror(const char *s);
extern int yylineno;
extern FILE *yyin;
extern char * yytext;

// Options
int root=-1;
int line=0;
int nelem=0;
int debug = 0;
int islist=0;

void debugFun(string s)
{
    if(debug == 1) cout << "DEBUG: " << s << endl;
}

// For type, line no., parent, backlist, AST
map<int,string> additional_info;
map<int,int> line_no;
map<int, int> parent;
map<int,vector<int>> backlist;

uint countnode=0;
map<int, pair<string, vector<int> > > tree;

int makenode(string name){
    countnode++;
    vector<int>childs;
    tree[countnode].first=name;
    tree[countnode].second=childs;
    return countnode;
}

/* ----------------------Milestone 2 ----------------------*/
int makenode(string name, string type){
    countnode++;
    vector<int>childs;
    tree[countnode].first=name;
    tree[countnode].second=childs;
    additional_info[countnode] = type;
    line_no[countnode] = line;
    backlist[countnode] = {};
    return countnode;
}

int getSize(string id){
    string t = "";
    for(int i=0;i<id.size();i++){
        if(id[i]=='['){
            break;
        }
        t+=id[i];
    }
    id=t;
    return 8;
}

string prevscope="global";

vector<string> key_words = {"False","None","True","and","as","assert","async","await","break","class","continue","def","del","elif","else","except","finally","for","from","global","if","import","in","is","lambda","nonlocal","not","or","pass","raise","return","try","while","with","yield"}; 

// -----------------Symbol Table--------------------

class Sym_Entry{
    public:
    string token;
    string type;
    int size;
    int offset;
    string scope;
    int line;
    string rtype;
    int nargs;
    int argno;
    map<int,vector<int>> arrshape;

    
    Sym_Entry(){

    }

    Sym_Entry(string token, string type, int size, int offset, string scope, int line,int argn){
        this->token=token;
        this->type=type;
        this->size=size;
        this->offset=offset;
        this->scope=scope;
        this->line=line;
        this->nargs= nelem;
        this->argno=argn;

    }

    void print_entry(ofstream *myfile){
        // cout<<token<<" "<<type<<" "<<size<<" "<<offset<<" "<<scope<<" " << line << " " << nargs << " " << argno << endl;
        // cout << this->scope << endl;
        *myfile<< this->token << "," << this->type << "," << this->size << "," << this->offset << "," << this->scope << "," << this->line  << endl;
    }
};

class SymbolTable {
    public:
    map<string, Sym_Entry> table;
    SymbolTable *parent;

    string scope_name;

    vector <SymbolTable*> children;
    int level_no;
    void entry(string lexeme,string token, string type, int size, int offset, string scope, int line,int argno){
        // do lookup instead in grammar rules
        if(table.find(lexeme)!=table.end()){
            cout<<"Variable Redeclaration Error: "<<lexeme << " in line " << yylineno<<endl;
            // exit(0);
        }
        table[lexeme]=Sym_Entry(token,type,size,offset,scope,line,argno);

    }

    SymbolTable(SymbolTable *child, string scope){
        if(!child){
            parent=NULL;
            level_no=0;
        }
        else{
            parent=child;
            level_no=child->level_no+1;
            child->children.push_back(this);
        }
        this->scope_name=scope;
        
    }

    Sym_Entry* lookup(string lexeme){
        SymbolTable *temp=this;
        
        while(temp){
            if(temp->table.find(lexeme)!=temp->table.end()){
                return &temp->table[lexeme];
            }
            temp=temp->parent;
        }
        // cout<<"Variable Not Declared Error: "<<lexeme<<endl;
        return NULL;
        // exit(0);
    }


    void print_table(ofstream *myfile){
        if(prevscope!=scope_name){
            *myfile << "Scope: " << scope_name << endl;
            prevscope=scope_name;
        }
        
        // myfile<<"Level: "<<level_no;

        for(auto i:table){
            *myfile<<"\t"<<i.first<<",";
            i.second.print_entry(myfile);            
        }
        *myfile << endl ;
        for(auto i:children){
            i->print_table(myfile);
        }
    }

    SymbolTable * findTable(string scope){
        SymbolTable *temp=this;
        if(debug) cout << this->scope_name << endl;
        for(auto i:temp->children){
            if(debug) cout << i->scope_name << " " << scope << yylineno << endl;
            if(i->scope_name==scope){
                if(debug) cout <<"returning " << i->scope_name << endl;
                return i;
            }
            // cout << i->scope_name << endl;
        }
       
        if(scope == temp->scope_name){
            return temp;
        }
        if(temp->parent){
            return temp->parent->findTable(scope);
        }

        
        return NULL;
    }
};
// -------------------Symbol Table--------------------


int ins_count =1;
// for the 3AC code generation in QUAD format
class quadruple {
    public:
    string op;
    string arg1;
    string arg2;
    string result;
    int ins_line=0;
    string type;
    int idx;
    quadruple(string op, string arg1, string arg2, string result, int idx, string type){
        this->op = op;
        this->arg1 = arg1;
        this->arg2 = arg2;
        this->result = result;
        this->idx = idx;
        this->type = type;
        this->ins_line = ins_count;
        ins_count++;
    }
};
vector<vector<quadruple>> allquadsarray;
// print quiads to new file 3ac.txt
// void PrintQuadTopArray()
// {
//     for(auto i:allquadsarray[0]){
//         cout<<i.op<<" "<<i.arg1<<" "<<i.arg2<<" "<<i.result<<endl;
//     }

// }


int currDepth = 0;

void print_quads(const std::string &filename){
    ofstream myfile;
    myfile.open(filename);
    int inFunc = 0;

    for(auto i:allquadsarray[currDepth]){
        if(i.op == "label")
        {            
            myfile << i.op << " " << i.arg1 << " " << i.arg2 << " " << i.result << endl;
        }
        // if op contain .
        else if(i.op.find(".") != string::npos){
            myfile << i.op << " " << i.arg1 << " " << i.arg2 << " " << i.result << endl;
            inFunc = 1;
        }
        else
        {
            // kaise karenge 3ac code ki formatting sahi
            // first check number of non empty elements in quad
            // if i.result non empty, then its assignment statement and i.result is result
            myfile << "\t";

            if(i.result != ""){
                int argcount = (i.arg1 != "") + (i.arg2 != "");
                if(i.op == "goto"){
                    if(i.result == "if"){
                        myfile << "if " << i.arg1 << " goto " << i.arg2 << endl;
                    }
                    else {
                        myfile << "goto " << i.arg2 << endl;
                    }
                    
                    // myfile << i.op << " " << i.result << endl;
                }
                else if(i.op != "")
                {
                    if(argcount == 0){
                        myfile << i.result << " = " << i.op << endl;
                    }
                    else if(argcount == 1){
                        myfile << i.result << " = " << i.op << " " << i.arg1 << endl;
                    }
                    else{
                        myfile << i.result << " = " << i.arg1 << " " << i.op << " " << i.arg2 << endl;
                    }
                    
                }
                else{
                    if(i.type == "load")
                    {
                        myfile << i.result << " = " << i.arg1 << "[" << i.arg2 << "]" << endl;
                    }
                    else if(i.type == "store")
                    {
                        myfile << i.result << "[" << i.arg2 << "]" << " = " << i.arg1 << endl;
                    }
                    else myfile << i.result << " = " << i.arg1 << endl;
                }
            }
            else{
                myfile << i.op;
                if(i.arg1 != ""){
                    myfile << " " << i.arg1;
                }
                if(i.arg2 != ""){
                    myfile << " " << i.arg2;
                }
                myfile << endl;
            }
            if(inFunc == 1 && i.op == "endfunc"){
                inFunc = 0;
                myfile << endl;
            }
        }
        
    }
    myfile.close();
}



// it will keep track of vectors of quads, with some latest vector that will be used by gen
// will contain, create new_array, merge_top_vec(will merge in main quad stream to quad)
void new_quad_array(){
    currDepth++;
    allquadsarray.push_back(vector<quadruple>());
}

void merge_top_vec_quad(){
    allquadsarray[currDepth-1].insert(allquadsarray[currDepth-1].end(), allquadsarray[currDepth].begin(), allquadsarray[currDepth].end());
    allquadsarray.pop_back();
    currDepth--;
}


void gen(string op, string arg1, string arg2, string result){
    string type;
    if(op == "goto"){
        type = "goto";
        if(result == "if")
            type = "conditional";
    }
    else if(op == "label"){
        type = "label";
    }
    else if(op == "beginfunc"){
        type = "beginfunc";
    }
    else if(op == "endfunc"){
        type = "endfunc";
    }
    else if(op == "param"){
        type = "param";
        debugFun("param");
    }
    else if(op == "call"){
        type = "funccall";
    }
    else if(op.size() == 0 && arg2.size() == 0){
        type = "assign";
        int flag =0;
        for(int i=0; i<arg1.size(); i++){
            if(arg1[i] == '['){
                type = "load";
                arg2 = arg1.substr(i+1, arg1.size()-i-2);
                arg1 = arg1.substr(0, i);
                flag = 1;
                debugFun(arg1 + " " + arg2 + "\n" + "-------------------------\n");
                break;
            }
        }

        if(flag == 0){
            for(int i=0; i<result.size(); i++){
                if(result[i] == '['){
                    type = "store";
                    // cout << result[result.size()-2]<< endl;
                    arg2 = result.substr(i+1, result.size()-i-2);
                    result = result.substr(0, i);
                    flag = 1;
                    debugFun(result + " " + arg2 + " \n" + "-------------------------\n");
                    break;
                }
            }
        }

        if(flag == 0){
            for(int i=0; i<arg1.size(); i++){
                if(arg1[i] == '\"' || arg1[i] == '\''){
                    // cout << "DEBUG321" << arg1 << endl;
                    arg1 = "\"" + arg1.substr(1, arg1.size()-2) + "\"";
                    type = "string";
                    break;
                }
            }
            
        }
    }
    else if(op == "popparam"){
        type = "popparam";
    }
    else if(op == "return"){
        type = "return";
    }
    else if(op == "returnval"){
        type = "returnval";
    }
    else if(arg2.size() == 0){
        // cout << op << " " << arg1 << " " << result << " " << "unary\n";
        // cout << "unary\n";
        type = "unary";  
    }
    else{
        type = "binary";
    }


    // old implementation
    // quad.push_back(quadruple(op, arg1, arg2, result, quad.size(),type)); 

    // new implementation
    debugFun(to_string(currDepth) + " " + to_string(allquadsarray.size()) + " " + to_string(allquadsarray[currDepth].size()) + " " + to_string(allquadsarray[0].size()) + " " + op + " " + arg1 + " " + arg2 + " " + result + " " + type);
    allquadsarray[currDepth].push_back(quadruple(op, arg1, arg2, result, allquadsarray[0].size(),type));
}

string newtemp(){
    static int tempno=0;
    string temp = "#t" + to_string(tempno);
    tempno++;
    return temp;
}

string newlabel(){
    static int labelno=0;
    string label = "L" + to_string(labelno);
    labelno++;
    return label;
}

int offset=0;






SymbolTable * current_table = new SymbolTable(NULL,"global");
string current_scope="global";
stack<SymbolTable*> table_stack;
stack<int>offsets;
stack<string>scopes;
// list of symbol tables
vector<SymbolTable*> list_of_tables(1,current_table);
// function parameters
vector <pair<pair<string,int>,pair<string,int>> > funcparams;    // lexeme,argno,type, line
int funcargno=-1;
// function arguments
// vector <pair<string, pair<string,int>>> funcargs;    // lexeme,type, arg no.
int fl=0;
stack<pair<string,int>> args;
int addoff = 0;
char curr_rtype[1000]="";
// vector of class names and their scopes
vector<pair<string,string>> classlist;

// vector of func names and their scopes
vector<pair<string,string>> funclist;

// func arguments
vector<string> funcargs;
map<string,string> funcargmap;


// string functype;

int infunction = 0;
int inclass = 0;
int self =0;
int islistexp = 0; // assignments, primary expression, variable declaration
// and is altered in all
// It used for, is it expression of list or not
int isobject =0;

vector<string>storelist;

vector<pair<string,string>> labels;



void backpatch(){
    for(auto &i:allquadsarray[currDepth]){
        if(i.op=="goto" && i.arg2 == "" && i.result == ""){
            i.arg2 = labels[labels.size()-1].first;
        }
            
    }
}





/* ------------------------ X86 Code ------------------------*/

const int stack_offset = 8;

int func_count = 0;
map<string, string> func_name_map;

bool isVariable(string s) { 
      // if the first character is a digit/-/+, then it is a constant and not a variable
    // Undefined behaviour when s is ""
    if(s == "") {
        cout << "Empty string is neither constant/variable. Aborting...";
        exit(1);
    }
    return !(s[0] >= '0' && s[0] <= '9') && (s[0] != '-') && (s[0] != '+');
}
class subroutine_entry{

    public:
    string name = "";
    int offset = 0;         // offset from the base pointer in subroutine


    subroutine_entry(){}
    subroutine_entry(string name, int offset) {
        this -> name = name;
        this -> offset = offset;
    }
    // other entries may be added later
};

map<string,int> label_map;

class subroutine_table{
    public:
    string subroutine_name;
    bool is_main_function = false;
    map<string, subroutine_entry> lookup_table;
    int total_space;
    int number_of_params = 0;

    subroutine_table(){}
    void construct_subroutine_table(vector<quadruple> subroutine_ins) {
        int pop_cnt = 2;         // 1 8 byte space for the return address + old base pointer
        int local_offset = 8;    // 8 callee saved registers hence, 8 spaces kept free, rsp shall automatically be restored, rbp too
        
        for(auto q : subroutine_ins) {
            if(q.type == "beginfunc" || q.type == "shift" || q.type == "funccall") {   // No nested procedures
                continue; 
            }
            
            if(q.type == "popparam") {
                this -> lookup_table[q.result] = subroutine_entry(q.result, stack_offset*pop_cnt);
                pop_cnt++;
            }


            else if(q.type == "label"){
                label_map[q.arg1] = q.ins_line;
            }
            else {
                if(q.type == "conditional") {
                    if(this -> lookup_table.find(q.arg1) == this -> lookup_table.end() && isVariable(q.arg1)) {
                        this -> lookup_table[q.arg1] = subroutine_entry(q.arg1, -stack_offset*local_offset);
                        local_offset++;
                        // label_map[q.arg2] = q.ins_line;
                    
                    }
                }
                else if(q.type == "goto"){
                    // label_map[q.arg2] = q.ins_line;
                    continue;
                }
                else {
                    debugFun("stack_offset: " + to_string(stack_offset) + " local_off: " + to_string(local_offset));
                    if(q.arg1 != "" && this -> lookup_table.find(q.arg1) == this -> lookup_table.end() && isVariable(q.arg1)) {
                        this -> lookup_table[q.arg1] = subroutine_entry(q.arg1, -stack_offset*local_offset);
                        local_offset++;
                    }
                    else if(q.arg2 != "" && this -> lookup_table.find(q.arg2) == this -> lookup_table.end() && isVariable(q.arg2)) {
                        this -> lookup_table[q.arg2] = subroutine_entry(q.arg2, -stack_offset*local_offset);
                        local_offset++;
                    }
                    else if(q.result != "" && this -> lookup_table.find(q.result) == this -> lookup_table.end() && isVariable(q.result)) {
                        this -> lookup_table[q.result] = subroutine_entry(q.result, -stack_offset*local_offset);
                        local_offset++;
                    }
                }
            }
        }

        this -> total_space = stack_offset * local_offset;   // total space occupied by callee saved registers + locals + temporaries
    }
    // bool isVariable(string s);
};



class x86inst{
    public:
    string op;
    string arg1;
    string arg2;
    string code;
    string instrtype;

    x86inst(string op = "", string arg1 = "", string arg2= "",string instrtype = ""){
        this->op = op;
        this->arg1 = arg1;
        this->arg2 = arg2;
        // this->result = result;
        this->instrtype = instrtype;
    }
};

vector<vector<quadruple>> subroutines;
vector<x86inst> strings;
map<string,string>string_map;



void get_tac_subroutines(){
    vector<quadruple> subroutine;


    bool func_started = false;

    for(auto q: allquadsarray[0]){
        if(q.type == "beginfunc"){
            func_started = true;
        }

        if(func_started){
            subroutine.push_back(q);
        }

        if(q.type == "string"){
            x86inst ins = x86inst(".str"+to_string(strings.size()/2), ":", "");
            strings.push_back(ins);

            // if single quoted string convert to double quoted
            if(q.arg1[0] == '\''){
                q.arg1 = "\"" + q.arg1.substr(1, q.arg1.size()-2) + "\"";
                ins = x86inst("\t.string", q.arg1, "", "");
                // cout << q.arg1 << endl;
                string_map[q.arg1] = ".str" + to_string((strings.size()-1)/2);
            }
            else{
                // cout << q.arg1 << endl;
                ins = x86inst("\t.string", q.arg1, "", "");
                string_map[q.arg1] = ".str" + to_string((strings.size()-1)/2);

            }



            // cout << "STRING MAP:" << q.arg1 << " " << string_map[q.arg1] << endl;
            strings.push_back(ins);

                        
        }

        if(q.type == "endfunc"){
            func_started = false;
            if(subroutine.size() > 0){
                subroutines.push_back(subroutine);
                subroutine.clear();
            }
        }
    }
}





// vector<x86inst> insts;

vector<x86inst>code;

string get_func_name(string s) {
    if(func_name_map.find(s) == func_name_map.end()) {
        func_count++;
        // func_name_map[s] = "func" + to_string(func_count);
        func_name_map[s] = s;
    }

    return func_name_map[s];
}


vector<x86inst> make_x86(quadruple q, int x=0, int y=0, int z=0 ){
    vector<x86inst> insts;  
    x86inst ins;

    // if(q.code == ""){
    //     return insts;        
    // }
    // else{
    //     if(q.type != "shift" && q.type != "pop_param"){
    //         ins = x86inst("", "", "", "", "comment", q.code.substr(2, q.code.size() - 2));
    //         insts.push_back(ins);
    //     }
    // }

    // if(q.is_target) {   // if this is a target, a label needs to be added
    //     ins = x86inst("", "L" + to_string(q.ins_line), "", "", "label");
    //     insts.push_back(ins);
    // }
    if(q.type == "binary"){            // c(z) = a(x) op b(y)
        // Load value of a into %rax

        if(q.op == "+"){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = x86inst("add", "$" + q.arg2, "%rdx");
            }
            else{
                ins = x86inst("add", to_string(y) + "(%rbp)", "%rdx");
            }
        }
        else if(q.op == "-"){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = x86inst("sub", "$" + q.arg2, "%rdx");
            }
            else{
                ins = x86inst("sub", to_string(y) + "(%rbp)", "%rdx");
            }
        }
        else if(q.op == "*"){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = x86inst("imul", "$" + q.arg2, "%rdx");
            }
            else{
                ins = x86inst("imul", to_string(y) + "(%rbp)", "%rdx");
            }
        }
        else if(q.op == "/"){
            if(!isVariable(q.arg1)){   // arg1 is a literal
                ins = x86inst("movq", "$" + q.arg1, "%rax");
                insts.push_back(ins);
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rax");
                insts.push_back(ins);                
            }
            ins = x86inst("cqto");
            insts.push_back(ins);

            if(!isVariable(q.arg2)){  // arg2 is a literal
                ins = x86inst("movq", "$" + q.arg2, "%rbx");
            }
            else{
                ins = x86inst("movq", to_string(y) + "(%rbp)", "%rbx");
            }
            insts.push_back(ins);
            ins = x86inst("idiv", "%rbx", "");
            insts.push_back(ins);
            ins = x86inst("movq", "%rax", "%rdx");
        }
        else if(q.op == "//"){
            if(!isVariable(q.arg1)){   // arg1 is a literal
                ins = x86inst("movq", "$" + q.arg1, "%rax");
                insts.push_back(ins);
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rax");
                insts.push_back(ins);                
            }
            ins = x86inst("cqto");
            insts.push_back(ins);

            if(!isVariable(q.arg2)){  // arg2 is a literal
                ins = x86inst("movq", "$" + q.arg2, "%rbx");
            }
            else{
                ins = x86inst("movq", to_string(y) + "(%rbp)", "%rbx");
            }
            insts.push_back(ins);
            ins = x86inst("idiv", "%rbx", "");
            insts.push_back(ins);
            ins = x86inst("movq", "%rax", "%rdx");
        }
        else if(q.op == "%"){
            if(!isVariable(q.arg1)){   // arg1 is a literal
                ins = x86inst("movq", "$" + q.arg1, "%rax");
                insts.push_back(ins);
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rax");
                insts.push_back(ins);                
            }
            ins = x86inst("cqto");
            insts.push_back(ins);

            if(!isVariable(q.arg2)){  // arg2 is a literal
                ins = x86inst("movq", "$" + q.arg2, "%rbx");
            }
            else{
                ins = x86inst("movq", to_string(y) + "(%rbp)", "%rbx");
            }
            insts.push_back(ins);
            ins = x86inst("idiv", "%rbx", "");
        }
        else if(q.op == "<<"){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = x86inst("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = x86inst("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = x86inst("sal", "%cl", "%rdx");
        }
        else if(q.op == ">>"){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = x86inst("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = x86inst("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = x86inst("sar", "%cl", "%rdx");
        }
        
        else if(q.op == ">"){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);

            if(!isVariable(q.arg2)){
                ins = x86inst("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = x86inst("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = x86inst("cmp", "%rdx", "%rcx");
            insts.push_back(ins);
            ins = x86inst("jl", "1f");  // true
            insts.push_back(ins);
            ins = x86inst("movq", "$0", "%rdx");
            insts.push_back(ins);
            ins = x86inst("jmp", "2f"); // false
            insts.push_back(ins);
            ins = x86inst("", "1", "", "label");
            insts.push_back(ins);
            ins = x86inst("movq", "$1", "%rdx");
            insts.push_back(ins);
            ins = x86inst("jmp", "2f");
            insts.push_back(ins);
            ins = x86inst("", "2", "", "label");
        }
        else if(q.op == "<"){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);

            if(!isVariable(q.arg2)){
                ins = x86inst("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = x86inst("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = x86inst("cmp", "%rdx", "%rcx");
            insts.push_back(ins);
            ins = x86inst("jg", "1f");  // true
            insts.push_back(ins);
            ins = x86inst("movq", "$0", "%rdx");
            insts.push_back(ins);
            ins = x86inst("jmp", "2f"); // false
            insts.push_back(ins);
            ins = x86inst("", "1", "", "label");
            insts.push_back(ins);
            ins = x86inst("movq", "$1", "%rdx");
            insts.push_back(ins);
            ins = x86inst("jmp", "2f");
            insts.push_back(ins);
            ins = x86inst("", "2", "", "label");
        }
        else if(q.op == ">="){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);

            if(!isVariable(q.arg2)){
                ins = x86inst("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = x86inst("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = x86inst("cmp", "%rdx", "%rcx");
            insts.push_back(ins);
            ins = x86inst("jle", "1f");  // true
            insts.push_back(ins);
            ins = x86inst("movq", "$0", "%rdx");
            insts.push_back(ins);
            ins = x86inst("jmp", "2f"); // false
            insts.push_back(ins);
            ins = x86inst("", "1", "", "label");
            insts.push_back(ins);
            ins = x86inst("movq", "$1", "%rdx");
            insts.push_back(ins);
            ins = x86inst("jmp", "2f");
            insts.push_back(ins);
            ins = x86inst("", "2", "", "label");
        }
        else if(q.op == "<="){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);

            if(!isVariable(q.arg2)){
                ins = x86inst("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = x86inst("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = x86inst("cmp", "%rdx", "%rcx");
            insts.push_back(ins);
            ins = x86inst("jge", "1f");  // true
            insts.push_back(ins);
            ins = x86inst("movq", "$0", "%rdx");
            insts.push_back(ins);
            ins = x86inst("jmp", "2f"); // false
            insts.push_back(ins);
            ins = x86inst("", "1", "", "label");
            insts.push_back(ins);
            ins = x86inst("movq", "$1", "%rdx");
            insts.push_back(ins);
            ins = x86inst("jmp", "2f");
            insts.push_back(ins);
            ins = x86inst("", "2", "", "label");
        }
        else if(q.op == "=="){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);

            if(!isVariable(q.arg2)){
                ins = x86inst("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = x86inst("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = x86inst("cmp", "%rdx", "%rcx");
            insts.push_back(ins);
            ins = x86inst("je", "1f");  // true
            insts.push_back(ins);
            ins = x86inst("movq", "$0", "%rdx");
            insts.push_back(ins);
            ins = x86inst("jmp", "2f"); // false
            insts.push_back(ins);
            ins = x86inst("", "1", "", "label");
            insts.push_back(ins);
            ins = x86inst("movq", "$1", "%rdx");
            insts.push_back(ins);
            ins = x86inst("jmp", "2f");
            insts.push_back(ins);
            ins = x86inst("", "2", "", "label");
        }
        else if(q.op == "!="){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);

            if(!isVariable(q.arg2)){
                ins = x86inst("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = x86inst("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = x86inst("cmp", "%rdx", "%rcx");
            insts.push_back(ins);
            ins = x86inst("jne", "1f");  // true
            insts.push_back(ins);
            ins = x86inst("movq", "$0", "%rdx");
            insts.push_back(ins);
            ins = x86inst("jmp", "2f"); // false
            insts.push_back(ins);
            ins = x86inst("", "1", "", "label");
            insts.push_back(ins);
            ins = x86inst("movq", "$1", "%rdx");
            insts.push_back(ins);
            ins = x86inst("jmp", "2f");
            insts.push_back(ins);
            ins = x86inst("", "2", "", "label");
        }
        else if(q.op == "&"){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = x86inst("and", "$" + q.arg2, "%rdx");
            }
            else{
                ins = x86inst("and", to_string(y) + "(%rbp)", "%rdx");
            }     
        }
        else if(q.op == "|"){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = x86inst("or", "$" + q.arg2, "%rdx");
            }
            else{
                ins = x86inst("or", to_string(y) + "(%rbp)", "%rdx");
            }     
        }
        else if(q.op == "^"){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = x86inst("xor", "$" + q.arg2, "%rdx");
            }
            else{
                ins = x86inst("xor", to_string(y) + "(%rbp)", "%rdx");
            }
        }
        else if(q.op == "and"){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            ins = x86inst("cmpq", "$0", "%rdx");
            insts.push_back(ins);
            ins = x86inst("je", "1f");
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = x86inst("movq", "$" + q.arg2, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(y) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            ins = x86inst("cmpq", "$0", "%rdx");
            insts.push_back(ins);
            ins = x86inst("je", "1f");
            insts.push_back(ins);
            ins = x86inst("movq", "$1", "%rdx");
            insts.push_back(ins);
            ins = x86inst("jmp", "2f");
            insts.push_back(ins);
            ins = x86inst("", "1", "", "label");
            insts.push_back(ins);
            ins = x86inst("movq", "$0", "%rdx");
            insts.push_back(ins);
            ins = x86inst("", "2", "", "label");
        }
        else if(q.op == "or"){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            ins = x86inst("cmpq", "$0", "%rdx");
            insts.push_back(ins);
            ins = x86inst("jne", "1f");     // true
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = x86inst("movq", "$" + q.arg2, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(y) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            ins = x86inst("cmpq", "$0", "%rdx");
            insts.push_back(ins);
            ins = x86inst("jne", "1f");     // true
            insts.push_back(ins);
            ins = x86inst("movq", "$0", "%rdx");
            insts.push_back(ins);
            ins = x86inst("jmp", "2f");     // false
            insts.push_back(ins);
            ins = x86inst("", "1", "", "label");
            insts.push_back(ins);
            ins = x86inst("movq", "$1", "%rdx");
            insts.push_back(ins);
            ins = x86inst("", "2", "", "label");
        }
        else if(q.op == "**"){
            // power operator
            // a**b = a to the power b
            // generate x86 code for this   

            // if a is a literal
            if (!isVariable(q.arg1)) {
                ins = x86inst("movq", "$" + q.arg1, "%rax");
                insts.push_back(ins);
            } else {
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rax");
                insts.push_back(ins);
            }

            // Check if arg2 is a variable
            if (!isVariable(q.arg2)) {
                ins = x86inst("movq", "$" + q.arg2, "%rbx");
            } else {
                ins = x86inst("movq", to_string(y) + "(%rbp)", "%rbx");
            }
            insts.push_back(ins);

            // Initialize %rdx to 1
            ins = x86inst("movq", "$1", "%rdx");
            insts.push_back(ins);

            // Rest of the code remains the same
            ins = x86inst("cmpq", "$0", "%rbx");
            insts.push_back(ins);
            ins = x86inst("je", "1f");
            insts.push_back(ins);
            ins = x86inst("jmp", "2f");
            insts.push_back(ins);
            ins = x86inst("", "1", "", "label");
            insts.push_back(ins);
            ins = x86inst("movq", "%rax", "%rdx");
            insts.push_back(ins);
            ins = x86inst("", "2", "", "label");
            insts.push_back(ins);
            ins = x86inst("dec", "%rbx"); // Decrement %rbx after the jump
            insts.push_back(ins);
            ins = x86inst("cmpq", "$0", "%rbx");
            insts.push_back(ins);
            ins = x86inst("je", "3f");
            insts.push_back(ins);
            ins = x86inst("imul", "%rax", "%rdx"); // Multiply %rdx with %rax
            insts.push_back(ins);
            ins = x86inst("jmp", "2b");
            insts.push_back(ins);
            ins = x86inst("", "3", "", "label");
            insts.push_back(ins);
            ins = x86inst("imul", "%rax", "%rdx"); // Move the result to %rax
            insts.push_back(ins);
            ins = x86inst("movq", "%rdx", "%rax"); // Move the result to %rax
            // insts.push_back(ins);





            
        }
        insts.push_back(ins);
        
        ins = x86inst("movq", "%rdx", to_string(z) + "(%rbp)");
        insts.push_back(ins);
    }
    else if(q.type == "label"){
        ins=x86inst(q.arg1,"","","label");
        insts.push_back(ins);
    }
    
    else if(q.type == "unary"){        // b(y) = op a(x)
        if(q.op == "~"){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            ins = x86inst("neg", "%rdx", "");
        }
        else if(q.op == "!"){
            if(!isVariable(q.arg1)){
                ins = x86inst("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            ins = x86inst("not", "%rdx", "");
        }
        else if(q.op == "-"){
            ins = x86inst("xor", "%rdx", "%rdx");
            insts.push_back(ins);
            if(!isVariable(q.arg1)){
                ins = x86inst("sub", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("sub", to_string(x) + "(%rbp)", "%rdx");
            }
        }
        else if(q.op == "+"){
            ins = x86inst("xor", "%rdx", "%rdx");
            insts.push_back(ins);
            if(!isVariable(q.arg1)){
                ins = x86inst("add", "$" + q.arg1, "%rdx");
            }
            else{
                ins = x86inst("add", to_string(x) + "(%rbp)", "%rdx");
            }
        }
        else if(q.op == "not"){
            // compare with 0 if equal make it 1 and if not make it 0
            if(!isVariable(q.arg1)){
                ins = x86inst("cmpq", "$0", "$" + q.arg1);
                insts.push_back(ins);

                // if above is true  then make it 1
                
            }
            else{
                ins = x86inst("cmpq", "$0", to_string(x) + "(%rbp)");
                insts.push_back(ins);
            }

            ins = x86inst("je", "1f");
            insts.push_back(ins);

            ins = x86inst("movq", "$0", "%rdx");
            insts.push_back(ins);

            ins = x86inst("jmp", "2f");
            insts.push_back(ins);

            ins = x86inst("", "1", "", "label");
            insts.push_back(ins);

            ins = x86inst("movq", "$1", "%rdx");
            insts.push_back(ins);

            ins = x86inst("", "2", "", "label");

            // ins = x86inst("xor", "%rdx", "%rdx");
            // insts.push_back(ins);
            // if(!isVariable(q.arg1)){
            //     ins = x86inst("xor", "$" + q.arg1, "%rdx");
            // }
            // else{
            //     ins = x86inst("xor", to_string(x) + "(%rbp)", "%rdx");
            // }
        }
        insts.push_back(ins);
        
        ins = x86inst("movq", "%rdx", to_string(y) + "(%rbp)");
        insts.push_back(ins);
    }
    else if(q.type == "assign"){   // b(y) = a(x)
        if(!isVariable(q.arg1)){
            ins = x86inst("movq", "$" + q.arg1, to_string(y) + "(%rbp)");
            insts.push_back(ins);
        }
        else{
            ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            insts.push_back(ins);            
            ins = x86inst("movq", "%rdx", to_string(y) + "(%rbp)");
            insts.push_back(ins);
        }
    }
    else if(q.type == "conditional"){  // if_false/if_true(op) a(x) goto y
        if(!isVariable(q.arg1)){
            ins = x86inst("movq", "$" + q.arg1, "%rdx");
        }
        else{
            ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
        }
        insts.push_back(ins);
        ins = x86inst("cmpq", "$0", "%rdx");
        insts.push_back(ins);
        
        // if(q.op == "if_false"){
        //     ins = x86inst("je", "L" + to_string(y));
        // }
        // else if(q.op == "if_true"){
            // ins = x86inst("jne", "L" + to_string(y));
        // }

        ins = x86inst("jne",q.arg2,"","jump");
        insts.push_back(ins);
    } 
    else if(q.type == "goto"){         // goto (x)
        ins = x86inst("jmp", q.arg2, "", "jump");
        insts.push_back(ins);
    }
    else if(q.type == "store"){        // *(r(z) + a2) = a1(x)
        if(!isVariable(q.arg1)){
            ins = x86inst("movq", "$" + q.arg1, "%rax");
        }
        else{
            ins = x86inst("movq", to_string(x) + "(%rbp)", "%rax");
        }
        insts.push_back(ins);
        
        ins = x86inst("movq", to_string(z) + "(%rbp)", "%rdx");
        insts.push_back(ins);

        if(q.arg2 == "" || !isVariable(q.arg2)) {
            ins = x86inst("movq", "%rax", q.arg2 + "(%rdx)");
            insts.push_back(ins);
        }
        else {
            ins = x86inst("movq", to_string(y) + "(%rbp)", "%rcx");
            insts.push_back(ins);

            ins = x86inst("add", "%rdx", "%rcx");
            insts.push_back(ins);

            ins = x86inst("movq", "%rax", "(%rcx)");
            insts.push_back(ins);

            // exit(1);  
        }
    }
    else if(q.type == "load"){         // r(z) = *(a1(x) + a2(y))
    // TODO: Problem in this part
        ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
        insts.push_back(ins);

        if(q.arg2 == "" || !isVariable(q.arg2)) {
            ins = x86inst("movq", q.arg2 + "(%rdx)", "%rdx");
            insts.push_back(ins);
        }
        else {
            ins = x86inst("movq", to_string(y) + "(%rbp)", "%rcx");
            insts.push_back(ins);

            ins = x86inst("add", "%rdx", "%rcx");
            insts.push_back(ins);

            ins = x86inst("movq", "(%rcx)", "%rdx");
            insts.push_back(ins);
            
            // exit(1);
        }

        ins = x86inst("movq", "%rdx", to_string(z) + "(%rbp)");
        insts.push_back(ins);
    }
    else if(q.type == "beginfunc") {  // perform callee duties
        if(y == 1) {        // make start label if it is the main function
            ins = x86inst("", "main", "", "label");
            insts.push_back(ins);
        }
        else{
            ins = x86inst("",q.arg1, "", "label");     // add label
            insts.push_back(ins);
        }


        ins = x86inst("pushq", "%rbp");      // old base pointer
        insts.push_back(ins);
        ins = x86inst("movq", "%rsp", "%rbp");    // shift base pointer to the base of the new activation frame
        insts.push_back(ins);
        ins = x86inst("pushq", "%rbx");
        insts.push_back(ins);
        ins = x86inst("pushq", "%rdi");
        insts.push_back(ins);
        ins = x86inst("pushq", "%rsi");
        insts.push_back(ins);
        ins = x86inst("pushq", "%r12");
        insts.push_back(ins);
        ins = x86inst("pushq", "%r13");
        insts.push_back(ins);
        ins = x86inst("pushq", "%r14");
        insts.push_back(ins);
        ins = x86inst("pushq", "%r15");
        insts.push_back(ins);

    //     // shift stack pointer to make space for locals and temporaries, ignore if no locals/temporaries in function
        if(x > 0) {
            ins = x86inst("sub", "$" + to_string(x), "%rsp");
            insts.push_back(ins);
        }
    }
    else if(q.type == "return") {    // clean up activation record
        if(q.arg1 != "") {      // Load %rax with the return value if non-void function
            if(!isVariable(q.arg1)) {
                ins = x86inst("movq", "$" + q.arg1, "%rax");
            }
            else {
                ins = x86inst("movq", to_string(y) + "(%rbp)", "%rax");
            }
            insts.push_back(ins);
        }
        
        ins = x86inst("add", "$" + to_string(x), "%rsp");   // delete all local and temporary variables
        insts.push_back(ins);
        ins = x86inst("popq", "%r15");                      // restore old register values
        insts.push_back(ins);
        ins = x86inst("popq", "%r14");
        insts.push_back(ins);
        ins = x86inst("popq", "%r13");
        insts.push_back(ins);
        ins = x86inst("popq", "%r12");
        insts.push_back(ins);
        ins = x86inst("popq", "%rsi");
        insts.push_back(ins);
        ins = x86inst("popq", "%rdi");
        insts.push_back(ins);
        ins = x86inst("popq", "%rbx");
        insts.push_back(ins);
        ins = x86inst("popq", "%rbp");
        insts.push_back(ins);

        ins = x86inst("ret");
        insts.push_back(ins);
    }
    else if(q.type == "endfunc") {
        if(x == 1) {        // if main function
            ins = x86inst("movq", "$60", "%rax");
            insts.push_back(ins);
            ins = x86inst("xor", "%rdi", "%rdi");
            insts.push_back(ins);
            ins = x86inst("syscall");
            insts.push_back(ins);
        }
        else {              // otherwise we perform usual callee clean up
            // end func cannot return any values    
            ins = x86inst("add", "$" + to_string(y), "%rsp");   // delete all local and temporary variables
            insts.push_back(ins);
            ins = x86inst("popq", "%r15");                      // restore old register values
            insts.push_back(ins);
            ins = x86inst("popq", "%r14");
            insts.push_back(ins);
            ins = x86inst("popq", "%r13");
            insts.push_back(ins);
            ins = x86inst("popq", "%r12");
            insts.push_back(ins);
            ins = x86inst("popq", "%rsi");
            insts.push_back(ins);
            ins = x86inst("popq", "%rdi");
            insts.push_back(ins);
            ins = x86inst("popq", "%rbx");
            insts.push_back(ins);
            ins = x86inst("popq", "%rbp");
            insts.push_back(ins);
            ins = x86inst("ret");
            insts.push_back(ins);
        }
    }
    else if(q.type == "shift") {
        // no need to do anything really for x86
    }
    else if(q.type == "funccall") {
        if(x == 0) {        // if function is called without any parameters, we have yet to perform caller responsibilities
            ins = x86inst("pushq", "%rax");
            insts.push_back(ins);
            ins = x86inst("pushq", "%rcx");
            insts.push_back(ins);
            ins = x86inst("pushq", "%rdx");
            insts.push_back(ins);
            ins = x86inst("pushq", "%r8");
            insts.push_back(ins);
            ins = x86inst("pushq", "%r9");
            insts.push_back(ins);
            ins = x86inst("pushq", "%r10");
            insts.push_back(ins);
            ins = x86inst("pushq", "%r11");
            insts.push_back(ins);
        }
        ins = x86inst("call", get_func_name(q.arg1));      // call the function
        insts.push_back(ins);

        if(get_func_name(q.arg1) == "printstr" || get_func_name(q.arg1) == "printint") {          // deal specially with print
            ins = x86inst("add", "$8", "%rsp");
            insts.push_back(ins);
        }
        else if(get_func_name(q.arg1) == "allocmem") {
            ins = x86inst("add", "$8", "%rsp");             // deal specially with allocmem
            insts.push_back(ins);
        }
        else if(x > 0) {                             // pop the parameters
            ins = x86inst("add", "$" + to_string(x*stack_offset), "%rsp");
            insts.push_back(ins);
        }
    }
    else if(q.type == "returnval") {
        // move the return value stored in %rax to the required location
        if(q.result != "") {      // if the function returns a value
            ins = x86inst("mov", "%rax", to_string(x) + "(%rbp)");
            insts.push_back(ins);
        }

        // restore original state of registers
        ins = x86inst("popq", "%r11");
        insts.push_back(ins);
        ins = x86inst("popq", "%r10");
        insts.push_back(ins);
        ins = x86inst("popq", "%r9");
        insts.push_back(ins);
        ins = x86inst("popq", "%r8");
        insts.push_back(ins);
        ins = x86inst("popq", "%rdx");
        insts.push_back(ins);
        ins = x86inst("popq", "%rcx");
        insts.push_back(ins);
        ins = x86inst("popq", "%rax");
        insts.push_back(ins);
    }
    else if(q.type == "param"){   // pushq a(x) || pushq const
        if(y == 1) {        // first parameter, perform caller saved registers
            ins = x86inst("pushq", "%rax");
            insts.push_back(ins);
            ins = x86inst("pushq", "%rcx");
            insts.push_back(ins);
            ins = x86inst("pushq", "%rdx");
            insts.push_back(ins);
            ins = x86inst("pushq", "%r8");
            insts.push_back(ins);
            ins = x86inst("pushq", "%r9");
            insts.push_back(ins);
            ins = x86inst("pushq", "%r10");
            insts.push_back(ins);
            ins = x86inst("pushq", "%r11");
            insts.push_back(ins);
        }
        if(!isVariable(q.arg1)) {  // it is just a constant
            ins = x86inst("pushq", "$" + q.arg1, "");
            insts.push_back(ins);
        } 
        else {
            ins = x86inst("pushq", to_string(x) + "(%rbp)"); // load rbp + x
            insts.push_back(ins);    
        }
    }
    else if(q.type == "cast"){     // r(y) = (op) a(x)
        if(!isVariable(q.arg1)) {  // it is a constant
            ins = x86inst("movq", "$" + q.arg1, "%rdx");
        } 
        else {
            ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx"); // load rbp + x
        }
        insts.push_back(ins);    
        ins = x86inst("movq", "%rdx", to_string(y) + "(%rbp)");
        insts.push_back(ins);    
    }
    else if(q.type == "string"){
        // cout << "STRING MAP: " << string_map[q.arg1] << endl;
        ins = x86inst("leaq", string_map[q.arg1] + "(%rip)", "%rdx");
        insts.push_back(ins);

        ins = x86inst("movq", "%rdx", to_string(y) + "(%rbp)");    
        insts.push_back(ins);

    
    }
    else if(q.type == "arrayload"){

        if(!isVariable(q.arg2)){
            ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            insts.push_back(ins);

            ins = x86inst("movq", "$" + q.arg2, "%rcx");
            insts.push_back(ins);

            ins = x86inst("add", "%rcx", "%rdx");
            insts.push_back(ins);

            ins = x86inst("movq", "%rdx", to_string(z) + "(%rbp)");
            insts.push_back(ins);

        }

        else {
            ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
            insts.push_back(ins);

            ins = x86inst("movq", to_string(y) + "(%rbp)", "%rcx");
            insts.push_back(ins);

            ins = x86inst("add", "%rcx", "%rdx");
            insts.push_back(ins);

            ins = x86inst("movq", "%rdx", to_string(z) + "(%rbp)");
            insts.push_back(ins);


        }
        
        
            

    }
    

    else if(q.type == "arraystore"){
                // if(!isVariable(q.arg1)){
        //     ins = x86inst("movq", "$" + q.arg1, to_string(y) + "(%rbp)");
        //     insts.push_back(ins);
        // }
        // else{
        //     ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
        //     insts.push_back(ins);            
        //     ins = x86inst("movq", "%rdx", to_string(y) + "(%rbp)");
        //     insts.push_back(ins);
        // }
        // if(!isVariable(q.arg2)) {  // it is a constant
        //     ins = x86inst("movq", "$" + q.arg1, "%rdx");
        // } 
        // else {
        //     ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx"); // load rbp + x
        // }
        

        // if(!isVariable(q.arg1)){
        //     ins = x86inst("movq", "$" + q.arg1, "%rdx");
        //     insts.push_back(ins);
        // }
        // else{
        //     ins = x86inst("movq", to_string(x) + "(%rbp)", "%rdx");
        //     insts.push_back(ins);
        // }

        // if(!isVariable(q.arg2)){
        //     ins = x86inst("movq", "$" + q.arg2, "%rcx");
        //     insts.push_back(ins);
        // }
        // else{
        //     ins = x86inst("movq", to_string(y) + "(%rbp)", "%rcx");
        //     insts.push_back(ins);
        // }

        // //  add offset of arg2 with result then store arg1(rdx) in that location
        // ins = x86inst("add", "$"+to_string(z), "%rcx");
        // insts.push_back(ins);

        // ins = x86inst("movq", "%rdx", "(%rcx)");
        // insts.push_back(ins);
        
        
    }

    return insts;
}





void print_x86(const std::string &filename){
    ofstream myfile;
    myfile.open(filename);

    for(auto i:code){
        // myfile << i.op <<  " " << i.arg1 << " " << i.arg2 << endl;
        if(i.instrtype != "label"){
            myfile << "\t";
        }
        if(i.op.size()>0){
            myfile << i.op << " ";
        }
        if(i.arg1.size()>0){
            myfile << i.arg1;
        }
        if(i.arg2.size()>0){
            myfile << ", " << i.arg2;
        }
        if(i.instrtype == "label"){
            myfile << ":";
        }
        myfile<<endl;
    }
    // myfile.close();
    myfile << "\n";
    ifstream printfunc("helperFuncs.s");
    string line;

    while(getline(printfunc, line)){
        myfile << line << '\n';
    }

    
}


void append_ins(x86inst ins) {
    code.push_back(ins);
}


void gen_basic_block(vector<quadruple>basic_block, subroutine_table* sub_table){
    for(auto q : basic_block){
        vector<x86inst> insts;


        // TODO: leaving conditionals and goto for now
        if(q.type == "conditional"){
            // int x = sub_table->lookup_table[q.arg1].offset;
            // int y = 
            int x = sub_table -> lookup_table[q.arg1].offset;
            int y = label_map[q.arg2];

            insts = make_x86(q,x,y);


        }
        else if(q.type == "goto"){
            insts = make_x86(q, label_map[q.arg2]);
        }

        else if(q.type == "binary"){
            int z = sub_table->lookup_table[q.result].offset;
            int x = sub_table->lookup_table[q.arg1].offset;
            int y = sub_table->lookup_table[q.arg2].offset;

            debugFun(to_string(z) + " " + to_string(x) + " " + to_string(z));

            insts = make_x86(q,x,y,z);
        }

        else if(q.type == "unary"){
            int x = sub_table->lookup_table[q.arg1].offset;
            int y = sub_table->lookup_table[q.result].offset;

            insts = make_x86(q,x,y);
        }
        else if(q.type == "label"){
            insts = make_x86(q);
        }

        else if(q.type == "assign"){
            if(debug) cout << "DEBUG: assignment " << q.arg1 << " " << q.result << endl; 
            int x = sub_table->lookup_table[q.arg1].offset;
            int y = sub_table->lookup_table[q.result].offset;
            insts = make_x86(q,x,y);
        }
        else if(q.type =="store"){
            int x = sub_table->lookup_table[q.arg1].offset;
            int y = sub_table->lookup_table[q.arg2].offset;
            int z = sub_table->lookup_table[q.result].offset;

            insts = make_x86(q,x,y,z);
        }
        else if(q.type == "load"){
            int x = sub_table->lookup_table[q.arg1].offset;
            int y = sub_table->lookup_table[q.arg2].offset;
            int z = sub_table->lookup_table[q.result].offset;


            insts = make_x86(q,x,y,z);
        }
        else if(q.type == "cast"){
            int x = sub_table -> lookup_table[q.arg1].offset;
            int y = sub_table -> lookup_table[q.result].offset;

            insts = make_x86(q,x,y);
        }

        else if(q.type == "beginfunc"){
            // bool isMain = false;
            if(q.arg1 == "main"){
                sub_table->is_main_function = true;
            }
            insts = make_x86(q,sub_table -> total_space - 8 * stack_offset, sub_table -> is_main_function);
        }

        else if(q.type == "endfunc"){
            insts = make_x86(q, sub_table -> is_main_function, sub_table -> total_space - 8 * stack_offset);
        }
        else if(q.type == "funccall"){
            insts = make_x86(q, sub_table -> number_of_params);
            sub_table -> number_of_params = 0;

        }
        else if(q.type == "shift"){
            insts = make_x86(q);
        }
        else if(q.type == "param"){
            int x = sub_table -> lookup_table[q.arg1].offset;
            sub_table -> number_of_params++;
            insts = make_x86(q, x, sub_table -> number_of_params);
        }

        else if(q.type == "return"){
            insts = make_x86(q, sub_table -> total_space - 8 * stack_offset, sub_table -> lookup_table[q.arg1].offset);
        }
        else if(q.type == "returnval"){
            insts = make_x86(q, sub_table -> lookup_table[q.result].offset);
        }
        else if(q.type == "arrayload"){ 
            int x = sub_table -> lookup_table[q.arg1].offset;
            int y = sub_table -> lookup_table[q.arg2].offset;
            int z = sub_table -> lookup_table[q.result].offset;

            insts = make_x86(q,x,y,z);
        }

        else if(q.type == "arraystore"){
            int x = sub_table -> lookup_table[q.arg1].offset;
            int y = sub_table -> lookup_table[q.arg2].offset;
            int z = sub_table -> lookup_table[q.result].offset;

            insts = make_x86(q,x,y,z);
        }
        else if(q.type == "popparam"){
            insts = make_x86(q);
        }
        else if(q.type == "string"){
            int x = sub_table->lookup_table[q.arg1].offset;
            int y = sub_table->lookup_table[q.result].offset;
            insts = make_x86(q,x,y);
        }
        
        
        for(auto ins : insts) {
            append_ins(ins);
        }
    }

}

vector<subroutine_table*> sub_tables;

void gen_tac_basic_block(vector<quadruple> subroutine,subroutine_table* sub_table){
    set<int>leaders;

    vector<quadruple> basic_block;

    int base_offset = subroutine[0].ins_line;
    leaders.insert(base_offset);

    // TODO: resolve this issue for gotos and jumps
    for(int i=0;i<subroutine.size();i++){
        if(debug) cout << "DEBUG: subroutine size " << subroutine.size() << endl;
        if(subroutine[i].type == "conditional" || subroutine[i].type == "goto"){
            // if(debug) cout << "DEBUG: conditional/goto " << subroutine[i].arg2 << endl;
            // if(debug) cout << "DEBUG: " << 
            // if((subroutine[i].arg2).size()>0)
            leaders.insert(label_map[subroutine[i].arg2]);
            leaders.insert(subroutine[i].ins_line + 1);
        }
        else if(subroutine[i].type == "funccall") {
            if(debug) cout << "DEBUG: funccall " << subroutine[i].arg1 << endl;
            leaders.insert(subroutine[i].ins_line);
            leaders.insert(subroutine[i].ins_line + 1); // call func is made of a singular basic block
        }
    }

    vector<int> ascending_leaders;

    for(auto i:leaders){
        ascending_leaders.push_back(i);
    }


    int prev_leader = ascending_leaders[0]; 

    for(int i=1;i<ascending_leaders.size();i++){
        basic_block.clear();
        for(int j=prev_leader;j<ascending_leaders[i];j++){
            basic_block.push_back(subroutine[j-base_offset]);
        }
        prev_leader = ascending_leaders[i];

        gen_basic_block(basic_block,sub_table);
    }

    basic_block.clear();

    int final_leader = ascending_leaders[ascending_leaders.size()-1];

    for(int i=final_leader;i-base_offset<subroutine.size();i++){
        basic_block.push_back(subroutine[i-base_offset]);
    }

    gen_basic_block(basic_block,sub_table);


    

}


void gen_global() {
    // @TODO
    x86inst ins;
    ins = x86inst(".data", "", "", "segment");
    code.push_back(ins);

    // CHANGE: %ld to %s
    
    ins = x86inst("integer_format:", ".asciz", "\"%ld\\n\"", "ins");
    code.push_back(ins);

    ins = x86inst("string_format:", ".asciz", "\"%s\\n\"", "ins");
    code.push_back(ins);

    ins = x86inst(".global", "main", "", "segment");      // define entry point
    code.push_back(ins);
}

void gen_fixed_subroutines() {
    func_name_map["printstr"] = "printstr";
    func_name_map["printint"] = "printint";
    func_name_map["allocmem"] = "allocmem";
}


void gen_text(){


    gen_global();
    x86inst ins(".text\n", "", "", "segment");
    code.push_back(ins); 

    gen_fixed_subroutines();

    get_tac_subroutines();

    for(auto ins: strings){
        code.push_back(ins);
    }

    for(auto subroutine : subroutines){
        subroutine_table * sub_table = new subroutine_table();

        sub_table -> construct_subroutine_table(subroutine);

        sub_tables.push_back(sub_table);

        gen_tac_basic_block(subroutine, sub_table);
        

    }


}




/*-----------------------------------------------------------*/
//------------My changes

void Err_Handler(string s, string ErrType)
{
        if (ErrType ==  "NameError")
            {cout << "NameError: " << s << " is not defined in line " << yylineno << endl;
            }
        else if(ErrType == "VariableRedeclaration")
            {cout << "Variable Redeclaration Error: " << s <<" in line " << yylineno<<endl;
            }
        else if (ErrType ==  "Uncaught")
            {cout << "Uncaught Error: " << s << yylineno << endl;}
        else if (ErrType == "CannotBeSubscribed")
        {
            cout << "TypeError: " << s << "object is not subscriptable in line " << yylineno << endl;
        }
    
    exit(0);
}

void addChild(int p, int c){
    tree[p].second.push_back(c);
    parent[c] = p;
}

void writeDotFile(const std::map<int, std::pair<std::string, std::vector<int>>> &tree, const std::string &filename) {
    std::ofstream dotFile(filename);
    if (!dotFile.is_open()) {
        std::cerr << "Error opening file: " << filename << std::endl;
        return;
    }
    
    dotFile << "digraph Tree {\n";
    
    for (const auto &node : tree) {
        int nodeId = node.first;
        std::string label = node.second.first;
        std::vector<int> children = node.second.second;

        set<string> BytePrefix = {"b", "B", "br", "Br", "bR", "BR", "rb", "rB", "Rb", "RB"};
        // Write node
        if (label[label.size() - 1] == '\"') {
            // remove last character and prefix upto "
            label = label.substr(0, label.size() - 2);
            int i = 0;
            while (i < label.size() && label[i] != '\"') {
                i++;
                
            }
            label = label.substr(0,i) + "\\\"" + label.substr(i + 1, label.size()) + "\\\"";
        }

        dotFile << "    " << nodeId << " [label=\"" << label << "\"];\n";

        // Write edges
        for (int child : children) {
            if(child != -1) dotFile << "    " << nodeId << " -> " << child << ";\n";
        }
    }

    dotFile << "}\n";
    dotFile.close();
}

string findLastBreakLabel(){
    for(int i = labels.size() - 1; i >= 0; i--){
        if(labels[i].second == "while.false" || labels[i].second == "for.false"){
            return labels[i].first;
        }
    }
    // Give Error If not any
    Err_Handler("Break statement outside loop", "Uncaught");
    exit(0);
}
string findLastContinueLabel(){
    for(int i = labels.size() - 1; i >= 0; i--){
        if(labels[i].second == "while.next" || labels[i].second == "for.next"){
            return labels[i].first;
        }
    }
    Err_Handler("Continue statement outside loop", "Uncaught");
    exit(0);
}
%}
%union {
    
    char * sval;
    int id;
    // for int num
    int intNumber;
    // for float num also
    float fltNumber;
    
    struct {
        int first;
        int nelem;
        int line;
        char lexeme[1000];
        char type[1000];      
        // char argstring[10000];
        // char arrtype[1000];
        // char type[1000];
        char val[1000];
        char varname[1000];
        char tempvar[1000];
        // char gotoname[1000];
        // char nextgoto[1000];
        // char nextgoto1[1000];
        // char nextgoto2[1000];
        // char arraystore[1000];
    } node;

}


%token<fltNumber> LITERAL_FLOAT
%token<intNumber> LITERAL_INT
%token KEY_FALS KEY_NONE KEY_TRU KEY_AS KEY_ASSERT KEY_ASYNC KEY_AWAIT KEY_BREAK KEY_CLASS KEY_CONTINUE KEY_DEF KEY_DEL KEY_ELIF KEY_ELSE KEY_EXCEPT KEY_FINALLY KEY_FOR KEY_FROM KEY_GLOBAL KEY_IF KEY_IMPORT KEY_IN KEY_IS KEY_LAMBDA KEY_NONLOCAL KEY_PASS KEY_RAISE KEY_RETURN KEY_TRY KEY_WHILE KEY_WITH KEY_YIELD 

%token <sval> IDENTIFIER

%token <sval> RES_ID_SELF
%token <sval> RES_ID_INIT
%token <sval> RES_ID_MAIN
%token <sval> RES_ID_NAME

%token KEY_INT KEY_FLOAT KEY_STR KEY_BOOL

%token OP_PLUS OP_MINUS OP_TIMES OP_DIVIDE OP_FLOOR OP_MOD OP_EXP OP_LSHIFT OP_RSHIFT OP_BITWISE_AND OP_BITWISE_OR OP_BITWISE_XOR OP_BITWISE_NOT OP_WALRUS OP_LESS OP_GREATER OP_LESS_EQ OP_GREATER_EQ OP_EQ OP_NOT_EQ OP_LOGICAL_NOT OP_LOGICAL_OR OP_LOGICAL_AND 

%token NEWLINE

%token <sval>STRING
%token <sval>BYTESTRING

%token KEY_LIST
%token DELIM_LPAR DELIM_RPAR DELIM_LBRACKET DELIM_RBRACKET DELIM_LBRACE DELIM_RBRACE DELIM_COMMA DELIM_COLON DELIM_DOT DELIM_SEMICOLON DELIM_ARROW

%token DELIM_OP_AT DELIM_ASSIGN DELIM_PLUS_EQ DELIM_MINUS_EQ DELIM_TIMES_EQ DELIM_DIVIDE_EQ DELIM_FLOOR_EQ DELIM_MOD_EQ DELIM_MATMUL_EQ DELIM_AND_EQ DELIM_OR_EQ DELIM_XOR_EQ DELIM_RSHIFT_EQ DELIM_LSHIFT_EQ DELIM_EXP_EQ


%left OP_PLUS OP_MINUS OP_TIMES OP_DIVIDE OP_FLOOR
%left OP_MOD OP_LSHIFT OP_RSHIFT 
%left OP_LESS OP_GREATER OP_LESS_EQ OP_GREATER_EQ 
%left OP_EQ OP_NOT_EQ
%left OP_BITWISE_AND OP_BITWISE_OR OP_BITWISE_XOR 
%left OP_LOGICAL_OR OP_LOGICAL_AND
%left DELIM_OP_AT


%right OP_BITWSIE_NOT OP_WALRUS OP_LOGICAL_NOT
%right OP_EXP 
%right DELIM_ASSIGN DELIM_PLUS_EQ DELIM_MINUS_EQ DELIM_TIMES_EQ DELIM_DIVIDE_EQ DELIM_FLOOR_EQ DELIM_MOD_EQ DELIM_MATMUL_EQ DELIM_AND_EQ DELIM_OR_EQ DELIM_XOR_EQ DELIM_RSHIFT_EQ DELIM_LSHIFT_EQ DELIM_EXP_EQ 



%token ENDMARKER

%token INDENT
%token DEDENT
%type <node> input
%type <node> statements
%type <node> statement simplestatement expressionstatement delstatement returnstatement globalstatement nonlocalstatement assign_statement assignments Ids Variable_Declaration Type_Declaration Primitive_Type NumericType List_Type List_expression expression logical_or_expression logical_and_expression bitwise_or_expression bitwise_xor_expression bitwise_and_expression equality_expression relational_expression shift_expression additive_expression multiplicative_expression exponentiation_expression negated_expression primary_expression funccall arguments compoundstatement ifstatement elifblocks elifblock elseblock whilestatement forstatement for_expression Assignable_List funcdef params Return_Type Suite classdef Names raisestatement ifstart elifstart elsestart ifstatement1 forstatement1 forstart whilestart whilestatement1 funcstart classstart classarguments funccallParent Ids1 while
%start input
%%
    /* take care of precedence for LR1 grammer, non ambiguous grammer */

/* Start symbol */
    input : /**/
    statements END  {
            debugFun("input");
            int uid = makenode("input");
            int child = makenode("ENDMARKER");
            addChild(uid, $1.first);
            addChild(uid, child);
            root = uid;
            $$.first = uid;
            }
        |  END {
            debugFun("input");
            int uid = makenode("input");
            int child = makenode("ENDMARKER");
            addChild(uid, child);
            root = uid;
            $$.first = uid;}
        ;
/* Used in Input */
    /* Used in Input */
    END : /**/
        NEWLINE END  {
            debugFun("end newline");
        }
        | ENDMARKER { 
            debugFun("end"); 
        }
        ;

    /*  */
    statements : /**/
        statement   { 
            debugFun("statements----");
            $$ = $1;
        }
        | statements statement { 
            debugFun("statements--");
            int uid = makenode("statements");
            addChild(uid, $1.first);
            addChild(uid, $2.first);
            $$.first = uid;
        }
        ;

    statement : /**/
        simplestatement NEWLINE  {
            debugFun("statements");
            $$ = $1;
        }
        | compoundstatement  { 
            debugFun("statements");
            $$ = $1;
        }
        ;

    /* SIMPLE STATEMENT */
    simplestatement : /**/
        expressionstatement          { 
            debugFun("simple statement");
            $$ = $1;
        }
        | delstatement              { 
            debugFun("simple statement");
            $$ = $1;
        }
        | KEY_BREAK           {
            debugFun("simple break statement");
            $$.first = makenode("break", "break");

            string label = findLastBreakLabel();
            gen("goto", "", label, "");
        }
        | KEY_CONTINUE         { 
            debugFun("simple continue statement");
            $$.first = makenode("continue", "continue");

            string label = findLastContinueLabel();
            gen("goto", "", label,"");

        }
        | KEY_PASS  {
            debugFun("simple pass statement");
            $$.first = makenode("pass", "pass");
        }
        | globalstatement         { 
            debugFun("simple statement");
            $$ = $1;
        }
        | nonlocalstatement      { 
            debugFun("simple statement");
            $$ = $1;
        }
        | assign_statement        { 
            debugFun("simple statement");
            $$ = $1;
        }
        | returnstatement         { 
            debugFun("simple statement");
            $$ = $1;
        }
        | expression                 { 
            debugFun("simple expression");
            $$ = $1;
        }
        | raisestatement           { 
            debugFun("simple statement");
            $$ = $1;
        }
        ;


    expressionstatement : /**/
        Variable_Declaration    { 
            debugFun("expression statement");
            $$ = $1;

            Sym_Entry *entry = current_table->lookup($1.lexeme);

            if(entry && entry->scope == current_scope && inclass <= 0){
                Err_Handler($1.lexeme, "VariableRedeclaration");
                exit(0);
            }
            else{
                // cout <<"func_"+scopes.top().substr(6,scopes.top().size())+".__init__" << endl;
                string scp= "func_"+scopes.top().substr(6,scopes.top().size())+".__init__";
                // cout << self << endl;
                // cout << current_scope << endl;
                // cout << inclass << endl;
                int a = inclass>0 &&  scp == current_scope && self ==1;
                // cout << "a:" <<a << endl;
                if(inclass>0 && scp == current_scope && self ==1){
                    // current_table->entry($1.lexeme, "variable", $1.type, getSize($1.type), offset, scopes.top(), $1.line, nelem);
                    // cout << "insuide" << endl;
                    SymbolTable *class_table = current_table->findTable(scopes.top()); 
                    
                    
                    // get class table offset pushed on stack
                    int offset_classs = offsets.top();

                    class_table->entry($1.lexeme, "variable", $1.type, getSize($1.type), offset_classs, scopes.top(), $1.line, nelem);
                    offset_classs += getSize($1.type);
                    offsets.pop();
                    offsets.push(offset_classs);
                    self =0;
                    // in this case offset of class should be increased and used
                }
                else{
                    current_table->entry($1.lexeme, "variable", $1.type, getSize($1.type), offset, current_scope, $1.line, nelem);
                    offset += getSize($1.type);
                }
                // current_table->entry($1.lexeme, "variable", $1.type, getSize($1.type), offset, current_scope, $1.line, nelem);
                debugFun("Variable Declaration Ke ander, Offset increased to = " + to_string(offset));
            }
        }
        // self.var declaration done in Var declaration itself
        ;

    delstatement : /**/
        KEY_DEL expression   { 
            debugFun("del statement");
            int uid = makenode("del");
            addChild(uid, $2.first);
            $$.first = uid;
        }
        ;

    returnstatement : /**/
        KEY_RETURN expression   { 
            debugFun("return statement");
            int uid = makenode("return", "return");
            addChild(uid, $2.first);
            $$.first = uid;

            if(current_scope.compare(0, 5, "func_") != 0){
                cout << "SyntaxError: 'return' outside function in line " << yylineno << endl;
                exit(0);
            }

            if(strcmp($2.type, curr_rtype) != 0){
                cout << "TypeError: return type mismatch in line " << yylineno << endl;
                exit(0);
            }

            // gen("return", $2.lexeme, "", "");
            gen("return", $2.tempvar, "", "");
            // gen("goto", "", "", "ra");
            
        }
        | KEY_RETURN  { 
            debugFun("return statement");
            $$.first = makenode("return", "return");

            if(current_scope.compare(0, 5, "func_") != 0){
                cout << "SyntaxError: 'return' outside function in line " << yylineno << endl;
                exit(0);
            }

            if(strcmp("None", curr_rtype) != 0){
                cout << "TypeError: return type mismatch in line " << yylineno << endl;
                exit(0);
            }

            // gen("goto", "", "", "ra");
            gen("return", "", "", "");

            
        }
        ;
        /* Low Priority */
    raisestatement : /**/
        KEY_RAISE expression   { 
            debugFun("raise statement");
            int uid = makenode("raise");
            addChild(uid, $2.first);
            $$.first = uid;
        }
        | KEY_RAISE  { 
            debugFun("raise statement");
            $$.first = makenode("raise");
        }
        ;

    /* Low Priority */
    globalstatement : /**/
        KEY_GLOBAL Names     { 
            debugFun("global statement");
            int uid = makenode("global");
            addChild(uid, $2.first);
            $$.first = uid;
        }
        ;

    /* Low Priority */
    nonlocalstatement : /**/
        KEY_NONLOCAL Names   { 
            debugFun("nonlocal statement");
            int uid = makenode("nonlocal");
            addChild(uid, $2.first);
            $$.first = uid;
        }
        ;


    /* Assignment Statement */
    /* Correct according to expression typecasting */
    assign_statement : /**/
        assignments{
            debugFun("Assignment");
            $$ = $1;
        }
        | Ids DELIM_PLUS_EQ expression  {
            debugFun("Assignment: += ");
            int uid = makenode("+=", "add_assign");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            if(!(strcmp($1.type,"str")==0 && strcmp($3.type,"str")==0) && strcmp($3.type,"None")!=0){

                if(strcmp($1.type, "int") != 0 && strcmp($1.type, "float") != 0){
                    cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for +: '" << $1.type << "' and '" << $3.type << "'" << endl;
                    exit(0);
                }
                if(strcmp($3.type, "int") != 0 && strcmp($3.type, "float") != 0){
                    cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for +: '" << $1.type << "' and '" << $3.type << "'" << endl;
                    exit(0);
                }


            }
            if(strcmp($3.type,"None")!=0){
                string temp1 =newtemp();
                gen("+",$1.tempvar,$3.tempvar,temp1);
                gen("",temp1,"",$1.tempvar);

                
            }
            strcpy($$.tempvar, $1.tempvar);

        }
        | Ids DELIM_MINUS_EQ expression  {
            debugFun("Assignment: -= ");
            int uid = makenode("-=", "sub_assign");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            if(strcmp($1.type, "int") != 0 && strcmp($1.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for -: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }
            if(strcmp($3.type, "int") != 0 && strcmp($3.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for -: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }




            string temp1 =newtemp();
            gen("-",$1.tempvar,$3.tempvar,temp1);
            gen("",temp1,"",$1.tempvar);

            strcpy($$.tempvar, $1.tempvar);


        }
        | Ids DELIM_TIMES_EQ expression  { 
            debugFun("Assignment: *= ");
            int uid = makenode("*=", "mul_assign");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            if(strcmp($1.type, "int") != 0 && strcmp($1.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for *: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }
            if(strcmp($3.type, "int") != 0 && strcmp($3.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for *: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }

            string temp1 =newtemp();
            gen("*",$1.tempvar,$3.tempvar,temp1);
            gen("",temp1,"",$1.tempvar);

            strcpy($$.tempvar, $1.tempvar);
        }
        | Ids DELIM_DIVIDE_EQ expression  {
            debugFun("Assignment: /= ");
            int uid = makenode("/=", "div_assign");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            if(strcmp($1.type, "int") != 0 && strcmp($1.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for /: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }
            if(strcmp($3.type, "int") != 0 && strcmp($3.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for /: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }

            

            string temp1 =newtemp();
            gen("/",$1.tempvar,$3.tempvar,temp1);
            gen("",temp1,"",$1.tempvar);

            strcpy($$.tempvar, $1.tempvar);
        }
        | Ids DELIM_FLOOR_EQ expression  {
            debugFun("Assignment: //= ");
            int uid = makenode("//=", "floor_assign");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            if(strcmp($1.type, $3.type) != 0){
                cout << "TypeError: Type mismatch of " << $1.type << " and " << $3.type << " in line " << yylineno << endl;
                exit(0);
            }

            string temp1 =newtemp();
            gen("//",$1.tempvar,$3.tempvar,temp1);
            gen("",temp1,"",$1.tempvar);

            strcpy($$.tempvar, $1.tempvar);
        }
        | Ids DELIM_MOD_EQ expression  { 
            debugFun("Assignment: %= ");
            int uid = makenode("%=", "mod_assign");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            if(strcmp($1.type, "int") != 0 || strcmp($3.type, "int") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for <<: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }

            string temp1 =newtemp();
            gen("%",$1.tempvar,$3.tempvar,temp1);
            gen("",temp1,"",$1.tempvar);

            strcpy($$.tempvar, $1.tempvar);
        }
        | Ids DELIM_MATMUL_EQ expression  { 
            debugFun("Assignment: @= ");
            int uid = makenode("@=", "matmul_assign");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            if(strcmp($1.type, $3.type) != 0){
                cout << "TypeError: Type mismatch of " << $1.type << " and " << $3.type << " in line " << yylineno << endl;
                exit(0);
            }

            string temp1 =newtemp();
            gen("@",$1.tempvar,$3.tempvar,temp1);
            gen("",temp1,"",$1.tempvar);

            strcpy($$.tempvar, $1.tempvar);
        }
        | Ids DELIM_AND_EQ expression  {
            debugFun("Assignment: &= ");
            int uid = makenode("&=", "and_assign");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            if(strcmp($1.type, $3.type) != 0){
                cout << "TypeError: Type mismatch of " << $1.type << " and " << $3.type << " in line " << yylineno << endl;
                exit(0);
            }

            string temp1 =newtemp();
            gen("&",$1.tempvar,$3.tempvar,temp1);
            gen("",temp1,"",$1.tempvar);

            strcpy($$.tempvar, $1.tempvar);
        }
        | Ids DELIM_OR_EQ expression  { 
            debugFun("Assignment: |= ");
            int uid = makenode("|=", "or_assign");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            if(strcmp($1.type, $3.type) != 0){
                cout << "TypeError: Type mismatch of " << $1.type << " and " << $3.type << " in line " << yylineno << endl;
                exit(0);
            }

            string temp1 =newtemp();
            gen("or",$1.tempvar,$3.tempvar,temp1);
            gen("",temp1,"",$1.tempvar);

            strcpy($$.tempvar, $1.tempvar);
        }
        | Ids DELIM_XOR_EQ expression  { 
            debugFun("Assignment: ^= ");
            int uid = makenode("^=", "xor_assign");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            if(strcmp($1.type, "int") != 0 || strcmp($3.type, "int") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for <<: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }

            string temp1 =newtemp();
            gen("^",$1.tempvar,$3.tempvar,temp1);
            gen("",temp1,"",$1.tempvar);

            strcpy($$.tempvar, $1.tempvar);
        }
        | Ids DELIM_RSHIFT_EQ expression  {
            debugFun("Assignment: >>= " );
            int uid = makenode(">>=", "rshift_assign");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            if(strcmp($1.type, "int") != 0 || strcmp($3.type, "int") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for <<: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }

            string temp1 =newtemp();
            gen(">>",$1.tempvar,$3.tempvar,temp1);
            gen("",temp1,"",$1.tempvar);

            strcpy($$.tempvar, $1.tempvar);
        }
        | Ids DELIM_LSHIFT_EQ expression  { 
            debugFun("Assignment: <<= " );
            int uid = makenode("<<=", "lshift_assign");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;


            if(strcmp($1.type, "int") != 0 || strcmp($3.type, "int") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for <<: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }

            string temp1 =newtemp();
            gen("<<",$1.tempvar,$3.tempvar,temp1);
            gen("",temp1,"",$1.tempvar);

            strcpy($$.tempvar, $1.tempvar);
        }
        | Ids DELIM_EXP_EQ expression  { 
            debugFun("Assignment: **= ");
            int uid = makenode("**=", "exp_assign");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            if(strcmp($1.type, "int") != 0 && strcmp($1.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for ** or pow(): '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }
            if(strcmp($3.type, "int") != 0 && strcmp($3.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for ** or pow(): '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }

            string temp1 =newtemp();
            gen("**",$1.tempvar,$3.tempvar,temp1);
            gen("",temp1,"",$1.tempvar);

            strcpy($$.tempvar, $1.tempvar);
        }
        ; 

    assignments : /**/
        Ids DELIM_ASSIGN assignments { 
            debugFun("assignments");
            int uid = makenode("=", "assign");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            if(strcmp($1.type, $3.type) != 0){
                if(!(strcmp($1.type, "int") == 0 && strcmp($3.type, "float") == 0) && !(strcmp($1.type, "float") == 0 && strcmp($3.type, "int") == 0)){
                    cout << "TypeError in line " << yylineno << ": unsupported assignment for: '" << $1.type << "' and '" << $3.type << "'" << endl;
                    exit(0);
                }
                
                
            }

            strcpy($$.type, $1.type);

            // string temp1 = new

            // string temp1 =newtemp();
            gen("",$3.tempvar,"",$1.tempvar);

            strcpy($$.tempvar, $1.tempvar);

        }
        | Ids DELIM_ASSIGN expression  {
            debugFun("assignments");
            int uid = makenode("=", "assign");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            if(strcmp($1.type, $3.type) != 0){
                if(!(strcmp($1.type, "int") == 0 && strcmp($3.type, "float") == 0) && !(strcmp($1.type, "float") == 0 && strcmp($3.type, "int") == 0)){
                    cout << "TypeError in line " << yylineno << ": unsupported assignment for: '" << $1.type << "' and '" << $3.type << "'" << endl;
                    exit(0);
                }
                  
            }

            strcpy($$.type, $1.type);
            strcpy($$.tempvar, $1.tempvar);

            // string temp1 =newtemp();
            // gen("=",$3.tempvar,"",temp1);

            // Is list exp is used in assignmets
            if(islistexp == 0){
                gen("",$3.tempvar,"",$1.tempvar);

            }
            else {

                string typ($$.type);
                string type = typ.substr(5, typ.size()-1);

                int size = getSize(type);

                
                string var(newtemp());

                gen("",to_string(1 + storelist.size()) + "*" + to_string(size),"",var);
                gen("param",var,"","");

                gen("call","allocmem","1","");
                string var1(newtemp());
                gen("returnval","","",var1);

                int k = 0;

                // storing size to first element
                gen("",to_string(storelist.size()),"",var1+"["+to_string(k)+"]");
                k+=size;
                for(int i=0;i<storelist.size();i++){
                    gen("",storelist[i],"", var1+"["+to_string(k)+"]");
                    k+=size;
                }
                gen("",var1,"",$1.tempvar);

                islistexp = 0;
                storelist.clear();   
            }
            // strcpy($$.tempvar, temp1.c_str());
        }


    // tempvar attr will contain, final access value
    // it is doing lookup for error handling
    Ids : /*Used in assign_statements, assignments, Assignable_List, equality_expression,*/
        Ids1 {
            debugFun("ids");
            $$ = $1;
            if(islist == 0){
                debugFun("ids");

                string lexeme($1.lexeme);
                Sym_Entry *entry = current_table->lookup(lexeme);
                if(!entry)
                    Err_Handler(lexeme, "NameError");
                else{
                    strcpy($$.type, entry->type.c_str());

                    strcpy($$.lexeme, lexeme.c_str());

                    // its is not used anywhere currently
                    strcpy($$.tempvar, $1.lexeme);
                }
            }
            else {
                 Sym_Entry *entry = current_table->lookup($1.lexeme);

                // TypeError: 'int' object does not support item assignment
                if(!entry)
                    Err_Handler($1.lexeme, "NameError");
                else if(entry && entry->type.compare(0, 4, "list") != 0  && entry->type.compare(0, 3, "str") != 0)
                    Err_Handler(entry->type, "CannotBeSubscribed");

                if(entry->type.compare(0, 4, "list") == 0){
                    int k=0;
                    char ty[100];
                    for(int i=5 ;i<entry->type.size()-1;i++){
                        ty[k++]= entry->type[i];
                    }
                    ty[k]='\0';                    
                    strcpy($$.type,ty);
                }
                else if(entry->type.compare(0, 3, "str") == 0){
                    strcpy($$.type, "str");
                }
                string var($1.lexeme);
                strcpy($$.lexeme, $1.lexeme);
                string temp = newtemp();
                gen("*", $1.tempvar, to_string(getSize($$.type)), temp);
                // elevated array
                gen("+", temp, to_string(getSize($$.type)), temp);

                // mistake here for using it in primary expression, had to give a check
                strcpy($$.tempvar, (var + "["+ temp + "]").c_str());
                islist = 0;
                
            }
        }
         | RES_ID_SELF DELIM_DOT Ids1 {
            debugFun("ids");
            int uid = makenode("atomic_expr");
            addChild(uid, makenode("self", "name"));
            int dot = makenode(".", "dot");
            addChild(uid, dot);
            addChild(dot, $3.first);
            $$.first = uid;
            
            // Check declare befor use
            Sym_Entry *entry = current_table->lookup("self");
            if(entry){
                if(inclass >0 ){
                    SymbolTable *class_table = current_table->findTable(scopes.top());
                    Sym_Entry *identry = class_table->lookup($3.lexeme);
                    if(identry){
                        // for normal base type
                        strcpy($$.type, identry->type.c_str());
                        // type is needed for type checking

                        strcpy($$.lexeme, $3.lexeme);
                        // giving tempvar, why need lexeme?

                        // this may be wrong as it is entry of class not current instance of object
                        string var("self");
                        strcpy($$.tempvar, (var + "[" + to_string(identry->offset) + "]").c_str());

                        strcpy($$.varname, "self");
                        // I think no need to give varname here

                        if(islist)
                        {
                            // for lists

                            if(identry->type.compare(0, 4, "list") == 0){
                                // to take type inside lise[ - ]
                                int k=0;
                                char ty[100];
                                for(int i=5 ;i<identry->type.size()-1;i++){
                                    ty[k++]= identry->type[i];
                                }
                                ty[k]='\0';                    
                                strcpy($$.type,ty);

                                // cout << "type====== of list " << $$.type << endl;
                            }
                            else if(identry->type.compare(0, 3, "str") == 0){
                                strcpy($$.type, "str");
                                // cout << "type====== ======== of list " << $$.type << endl;
                            }

                            // out of index bound not checked, will done when implementation of list will change
                            string temp = newtemp();
                            string v1($1);
                            v1 = v1 + "[";
                            string v2 = to_string(identry->offset);
                            string v3 = "]";

                            gen("",v1 + v2 + v3, "", temp);
                            string temp2 = newtemp();
                            gen("*", $3.tempvar, to_string(getSize($$.type)), temp2);

                            // elevated array access
                            gen("+", temp2, to_string(getSize($$.type)), temp2);
                            
                            strcpy($$.tempvar, (temp + "[" + temp2 + "]").c_str());

                            islist = 0;
                        }

                    }
                    else Err_Handler($3.lexeme, "NameError");
                }

                else {
                    isobject=1;
                // ye uper decide karhe hai its location and then using this for assignment isliye set kiya
                
                    for(auto it: classlist){
                        // cout << it.first << " " << entry->type << endl; 
                        debugFun(it.first + " " + entry->type + "\n");
                        if(it.first == entry->type){
                            SymbolTable *class_table = current_table->findTable("class_"+it.first);
                            Sym_Entry *identry = class_table->lookup($3.lexeme);
                            if(identry){
                                // for normal base type
                                strcpy($$.type, identry->type.c_str());
                                // type is needed for type checking

                                strcpy($$.lexeme, $3.lexeme);
                                // giving tempvar, why need lexeme?

                                // this may be wrong as it is entry of class not current instance of object
                                string var($1);
                                strcpy($$.tempvar, ("*("+ var+"+"+to_string(identry->offset)+")").c_str());

                                strcpy($$.varname, $1);
                                // I think no need to give varname here

                                if(islist)
                                {
                                    // for lists

                                    if(identry->type.compare(0, 4, "list") == 0){
                                        // to take type inside lise[ - ]
                                        int k=0;
                                        char ty[100];
                                        for(int i=5 ;i<identry->type.size()-1;i++){
                                            ty[k++]= identry->type[i];
                                        }
                                        ty[k]='\0';                    
                                        strcpy($$.type,ty);
                                    }
                                    else if(identry->type.compare(0, 3, "str") == 0){
                                        strcpy($$.type, "str");
                                    }


                                    // out of index bound not checked, will done when implementation of list will change
                                    string temp = newtemp();
                                    string v1($1);
                                    v1 = v1 + "[";
                                    string v2 = to_string(identry->offset);
                                    string v3 = "]";

                                    gen("",v1 + v2 + v3, "", temp);
                                    string temp2 = newtemp();
                                    gen("*", $3.tempvar, to_string(getSize($$.type)), temp2);

                                    // elevated array access
                                    gen("+", temp2, to_string(getSize($$.type)), temp2);
                                    strcpy($$.tempvar, (temp + "[" + temp2 + "]").c_str());
                                    
                                    islist = 0;
                                }
                            }
                            else Err_Handler($3.lexeme, "NameError");
                        }
                    }
                }
            }
            else Err_Handler("self", "NameError");
         }
        | IDENTIFIER DELIM_DOT Ids1 {

            int uid = makenode("atomic_expr");
            addChild(uid, makenode($1, "name"));
            int dot = makenode(".", "dot");
            addChild(uid, dot);
            addChild(dot, $3.first);
            $$.first = uid;

            // Check declare befor use

            
            Sym_Entry *entry = current_table->lookup($1);
            if(entry){
                // SymbolTable *class_table = current_table->findTable("class_"+entry->type);

                isobject=1;
                // ye uper decide karhe hai its location and then using this for assignment isliye set kiya
                
                for(auto it: classlist){
                    debugFun(it.first + " " + entry->type + " \n");
                    if(it.first == entry->type){
                        SymbolTable *class_table = current_table->findTable("class_"+it.first);
                        Sym_Entry *identry = class_table->lookup($3.lexeme);
                        if(identry){
                            // for normal base type
                            strcpy($$.type, identry->type.c_str());
                            // type is needed for type checking

                            strcpy($$.lexeme, $3.lexeme);
                            // giving tempvar, why need lexeme?

                            // this may be wrong as it is entry of class not current instance of object
                            string var($1);
                            strcpy($$.tempvar, (var + "[" + to_string(identry->offset) + "]").c_str());

                            strcpy($$.varname, $1);
                            // I think no need to give varname here

                            if(islist)
                            {
                                // for lists

                                if(identry->type.compare(0, 4, "list") == 0){
                                    // to take type inside lise[ - ]
                                    int k=0;
                                    char ty[100];
                                    for(int i=5 ;i<identry->type.size()-1;i++){
                                        ty[k++]= identry->type[i];
                                    }
                                    ty[k]='\0';                    
                                    strcpy($$.type,ty);
                                }
                                else if(identry->type.compare(0, 3, "str") == 0){
                                    strcpy($$.type, "str");
                                }


                                // give correct tempvar and other info also

                                // old implementation
                                // string temp = newtemp();
                                // gen("+", $1, to_string(identry->offset), temp);
                                // string temp2 = newtemp();
                                // gen("*", $3.tempvar, to_string(getSize($$.type)), temp2);
                                // strcpy($$.tempvar,  (temp+ "[" + temp2 + "]").c_str());

                                // new implementation
                                // getting the address of array in object list
                                // out of index bound not checked, will done when implementation of list will change
                                string temp = newtemp();
                                string v1 = $1;
                                v1 = v1 + "[";
                                string v2 = to_string(identry->offset);
                                string v3 = "]";

                                gen("",v1 + v2 + v3, "", temp);
                                string temp2 = newtemp();
                                gen("*", $3.tempvar, to_string(getSize($$.type)), temp2);

                                // elevated array access
                                gen("+", temp2, to_string(getSize($$.type)), temp2);
                                strcpy($$.tempvar, (temp + "[" + temp2 + "]").c_str());
                                

                                islist = 0;
                            }
                        }
                        else Err_Handler($3.lexeme, "NameError");
                    }
                }
            }
            else Err_Handler($1, "NameError");
        }

    Ids1 : /**/
        Names {
            $$ = $1;
            islist=0;
        }
        | Names DELIM_LBRACKET expression DELIM_RBRACKET {

            // MultiDirection Arrays are not Supported as we dont have function to get size of element of array
            debugFun("ids");
            int uid = makenode("atom_expr");

            addChild(uid, $1.first);
            int child= makenode("[]");
            addChild(uid, child);
            addChild(child, $3.first);
            $$= $1; //ye kyu kiya hai nahi samajh aarha

            // Check declare befor use
            $$.first = uid;
                // Check declare befor use

            // type checking and index calculations sare done in Ids
            strcpy($$.tempvar, $3.tempvar);
           
            if(strcmp($3.type, "int") != 0){
                cout << "TypeError in line " << yylineno << ": list indices must be integers, not " << $3.type << endl;
                exit(0);
            }
            islist = 1 ;
        }
        ;


    /* TYPE DECLARATION */
    /* SUPPORT TYPECASTING  and  multiple assignmentsent  a:int = b=c  */
    Variable_Declaration : /*Used in Params,Expression_statement*/
        Type_Declaration DELIM_ASSIGN expression { 
            debugFun("variable");
            int uid = makenode("Variable Declaration");

            // int uid = makenode("=", "assign");

            addChild(uid, $1.first);
            addChild(uid, makenode("=", "assign"));
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.lexeme, $1.lexeme);
            strcpy($$.type, $1.type);
            $$.line = $1.line;

            if(strcmp($1.type, $3.type) != 0){
                if(!(strcmp($1.type, "int") == 0 && strcmp($3.type, "float") == 0) && !(strcmp($1.type, "float") == 0 && strcmp($3.type, "int") == 0)){
                    cout << "TypeError in line " << yylineno << ": unsupported assignment for: '" << $1.type << "' and '" << $3.type << "'" << endl;
                    exit(0);
                }
                  
            }

            string typ($$.type);
            string var1;
            // if(typ.compare(0, 4, "list") !=0){
            if(islistexp == 0){
                string a($3.tempvar);
                var1 = a;

                
                
            }

            else {
                // For list expression
                string typ($$.type);
                string type = typ.substr(5, typ.size()-1);

                int size = getSize(type);

                int k=0;
                
                string var(newtemp());

                gen("",to_string(1 + storelist.size()) + "*" + to_string(size),"",var);
                gen("param",var,"","");

                gen("call","allocmem","1","");
                var1 = newtemp();
                gen("returnval","","",var1);
                
                gen("",to_string(storelist.size()),"",var1+"["+to_string(k)+"]");
                k+=size;
                for(int i=0;i<storelist.size();i++){
                    gen("",storelist[i],"", var1+"["+to_string(k)+"]");
                    k+=size;
                }
                islistexp = 0;
                storelist.clear();      
            }
            if(self==0) gen("",var1,"",$1.lexeme);
            else{
                string ab = "self";
                ab = ab + "[";
                ab = ab + to_string(offsets.top());
                ab = ab + "]";
                gen("",var1,"",ab);
                // not self = 0 after this because it is need in declaration
            }

        }
        /* | Names DELIM_COLON List_Type DELIM_ASSIGN expression { cout << "list" << endl;} */
        | Type_Declaration {
            debugFun("variable");
            int uid = makenode("Variable Declaration");
            addChild(uid, $1.first);
            $$.first = uid;

            
            strcpy($$.lexeme, $1.lexeme);
            strcpy($$.type, $1.type);
            $$.line = $1.line;
            // if no assignment, then declare memory of classes




            if(strcmp($$.tempvar,"Class") == 0)
            {
                Sym_Entry *entry = current_table->lookup($1.type);
                if(entry && entry->token == "class")
                {
                    string temp = newtemp();
                    gen("param",to_string(entry->size),"","");
                    gen("call","allocmem","1","");
                    gen("returnval","","",temp);
                    gen("",temp,"",$1.lexeme);
                }
            }

        }
        /* | Names DELIM_COLON List_Type { cout << "list_dec" << endl;} */
        ;


// Using atts .first, .type, .lexeme, .tempvar(indicated wheather it is class or not)
    Type_Declaration : /*Used in */
        Names DELIM_COLON Primitive_Type  {
            int uid = makenode(":");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;
            strcpy($$.lexeme, tree[$1.first].first.c_str());
            strcpy($$.type, $3.type);
            $$.line=yylineno;
            strcpy($$.tempvar, $3.tempvar);
        }
        /* | Names DELIM_COLON List_Type { cout << "list" << endl;} 
        |        */
        | RES_ID_SELF DELIM_DOT Type_Declaration { 
            // change .tempvar in this always
            int uid = makenode("Type Declaration");
            addChild(uid, makenode("self", "name"));
            int dot = makenode(".", "dot");
            addChild(uid, dot);
            addChild(dot, $3.first);
            $$.first = uid;
            // get offset of tempvar in $3, and sum it with self address in some other temp
            string temp = newtemp();
            if(inclass > 0){

                strcpy($$.lexeme, $3.lexeme);
                strcpy($$.type, $3.type);
                $$.line = $3.line;
                self =1;

            }
            else{
                cout << "NameError: name 'self' is not defined in line "<< yylineno << endl;
                exit(0);
            }
        }
        ;


/* LIST DECLARATION 

Translating Array References
Production Semantic Rules
S → id = E gen(symtop.get (id.lexeme)“ = ”E.addr)
S → L = E gen(L.array.base“[”L.addr“]”“ = ”E.addr)
E → E1 + E2 E.addr = new Temp();
gen(E.addr“ = ”E1.addr“ + ”E2.addr)
E → id E.addr = symtop.get (id.lexeme)
E → L E.addr = new Temp();
gen(E.addr“ = ”L.array.base“[”L.addr“]”)
L → id[E] L.array = symtop.get (id.lexeme); L.type = L.array.type.elem;
L.addr = new Temp(); gen(L.addr“ = ”E.addr“ ∗ ”L.type.width)
L → L1 [E] L.array = L1.array; L.type = L1.type.elem; t = new Temp(); L.addr = new Temp();
gen(t“ = ”E.addr“ ∗ ”L.type.width); gen(L.addr“ = ”L1.addr“ + ”t);
*/

    // List_Declatation_Catch : /*Used in C,C++ */
    //     List_Declatation_Catch DELIM_LBRACKET expression DELIM_RBRACKET { 
    //     }
    //     |
    //     Names DELIM_LBRACKET expression DELIM_RBRACKET { 
    //     }
    //     ;
        

// only 2 atts used .type and .first, .tempvar indicated it is a some object instance
    Primitive_Type : /* Used in */
        NumericType   { 
            if(debug == 1) cout << "numeric" << endl;
            $$ = $1;
            // $$.type = $1.type;
            strcpy ($$.type, $1.type);
        }
        | KEY_STR     { 
            if(debug == 1) cout << "string" << endl;
            $$.first = makenode("str", "type");
            // $$.type = "str";
            strcpy ($$.type, "str");
        }
        | KEY_BOOL    {
            if(debug == 1) cout << "bool" << endl;
            $$.first = makenode("bool", "type"); 
            // $$.type = "bool";
            strcpy ($$.type, "bool");

        }
        | List_Type   {
            if(debug == 1) cout << "list" << endl;
            $$ = $1;
            // $$.type = $1.type;

            strcpy ($$.type, $1.type);
        }
        | Names       {
            if(debug == 1) cout << "primitive" << endl;
            $$ = $1;
            // $$.type = tree[$1.first].first;
            strcpy ($$.type, tree[$1.first].first.c_str());
            int flag=0;

            Sym_Entry *entry = current_table->lookup($1.lexeme);    
            if(entry && entry->token != "class"){
                cout << "NameError: name '" << tree[$1.first].first << "' is not defined" << endl;
                exit(0);

            }
            strcpy($$.tempvar,"Class");
            // Indicating it is a class for type declaration
        }

        ; 
    
    NumericType : /**/
        KEY_INT       { 
            if(debug == 1) cout << "int" << endl;
            $$.first = makenode("int","type");
            // $$.type = "int";
            strcpy ($$.type, "int");
        }
        | KEY_FLOAT   {
            if(debug == 1) cout << "float" << endl;
            $$.first = makenode("float","type");
            // $$.type = "float";
            strcpy ($$.type, "float");
        }
        ;


    

    /* LIST DECLARATION */
    List_Type : /**/
        KEY_LIST DELIM_LBRACKET Primitive_Type DELIM_RBRACKET { 
            if(debug == 1) cout << "list_type" << endl;
            int uid = makenode("list");
            addChild(uid, makenode("list"));
            int child = makenode("[]");
            addChild(child, $3.first);
            addChild(uid, child);
            $$.first = uid;

            // $$.type = "list["+ $3.type + "]";

            // strcpy ($$.type, ("list[" + $3.type + "]"));
            // snprintf($$.type, sizeof($$.type), "list[%s]", $3.type);
            string s($3.type );
            string st= "list[" + s + "]"; 
            strcpy ($$.type, st.c_str());
        }
        ;

  
    List_expression : /**/
        List_expression DELIM_COMMA expression  { 
            if(debug == 1) cout << "list" << endl;
            int uid = makenode(",", "comma");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            // $$.cnt = $3.cnt + 1;

            if(strcmp($1.type, $3.type) != 0){
                if(!(strcmp($1.type, "int") == 0 && strcmp($3.type, "float") == 0) && !(strcmp($1.type, "float") == 0 && strcmp($3.type, "int") == 0)){
                    cout << "TypeError in line " << yylineno << ": unsupported list types: '" << $1.type << "' and '" << $3.type << "'" << endl;
                    exit(0);
                }
                  
            }

            strcpy($$.type, $3.type);
            storelist.push_back($3.tempvar);
        }
        | expression { 
            if(debug == 1) cout << "list" << endl;
            $$ = $1;

            strcpy($$.type, $1.type);

            storelist.push_back($1.tempvar);
        }
        | %empty {
            $$.first = -1;
        }
        

    
    /* EXPRESSIONS */
    /* TYPE CHECKING FUNCTION */
    expression : /**/
        logical_or_expression { 
        if(debug == 1) cout << "expression" << endl;
        $$ = $1;

        strcpy($$.type, $1.type);
        // cout << "expression:" << $$.type << endl;
        }
        ;

    logical_or_expression : /**/
        logical_and_expression    {
            if(debug == 1) cout << "logical or" << endl;
            $$ = $1;

            strcpy($$.type, $1.type);
        }
        | logical_or_expression OP_LOGICAL_OR logical_and_expression { 
            if(debug == 1) cout << "logical or" << endl;
            int uid = makenode("or", "or");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("or",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());

            strcpy($$.type, "bool");


        }
        ;

    logical_and_expression : /**/
        bitwise_or_expression  { 
            if(debug == 1) cout << "logical and" << endl;
            $$ = $1;

            strcpy($$.type, $1.type);
        }
        | logical_and_expression OP_LOGICAL_AND bitwise_or_expression { 
            if(debug == 1) cout << "logical and" << endl;
            int uid = makenode("and", "and");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;


            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("and",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());


            strcpy($$.type, "bool");
        }
        ;

    bitwise_or_expression : /**/
        bitwise_xor_expression   { 
            if(debug == 1) cout << "bitwise or" << endl;
            $$ = $1;

            strcpy($$.type, $1.type);
        }
        | bitwise_or_expression OP_BITWISE_OR bitwise_xor_expression { 
            if(debug == 1) cout << "bitwise or" << endl;
            int uid = makenode("|", "bitwise_or");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;


            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("|",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());


            strcpy($$.type, "int");


        }
        ;

    bitwise_xor_expression 
        : bitwise_and_expression   { 
            if(debug == 1) cout << "bitwise xor" << endl;
            $$ = $1;


            strcpy($$.type, $1.type);
        }
        | bitwise_xor_expression OP_BITWISE_XOR bitwise_and_expression { 
            if(debug == 1) cout << "bitwise xor" << endl;
            int uid = makenode("^", "bitwise_xor");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("^",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());


            strcpy($$.type, "int");
        }
        ;
    bitwise_and_expression 
        : equality_expression    { 
            if(debug == 1) cout << "bitwise and" << endl;
            $$ = $1;

            strcpy($$.type, $1.type);
        }
        | bitwise_and_expression OP_BITWISE_AND equality_expression { 
            if(debug == 1) cout << "bitwise and" << endl;
            int uid = makenode("&", "bitwise_and");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("&",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());

            strcpy($$.type, "int");


            
        }
        ;

    equality_expression : /**/
        relational_expression  { 
            if(debug == 1) cout << "equality expression" << endl;
            $$ = $1;

            strcpy($$.type, $1.type);
        }
        | equality_expression OP_EQ relational_expression {  
            if(debug == 1) cout << "equality expression" << endl;
            int uid = makenode("==", "eq");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("==",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());

            strcpy($$.type, "bool");
            
        }
        | equality_expression OP_NOT_EQ relational_expression {
            if(debug == 1) cout << "equality expression" << endl;
            int uid = makenode("!=", "neq");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("!=",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());

            strcpy($$.type, "bool");

            
        }
        | equality_expression OP_WALRUS relational_expression {
            if(debug == 1) cout << "equality expression" << endl;
            int uid = makenode(":=", "walrus");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen(":=",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());


            strcpy($$.type, $3.type);
        }
        | equality_expression KEY_IS relational_expression {
            if(debug == 1) cout << "equality expression" << endl;
            int uid = makenode("is", "is");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("is",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());

            strcpy($$.type, "bool");



        }
        | equality_expression KEY_IN Ids {
            if(debug == 1) cout << "equality expression" << endl;
            int uid = makenode("in", "in");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("in",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());

            strcpy($$.type, "bool");
        }
        | equality_expression OP_LOGICAL_NOT KEY_IN Ids {
            if(debug == 1) cout << "equality expression" << endl;
            int uid = makenode("not", "not");
            addChild(uid, $1.first);
            addChild(uid, makenode("in", "in"));
            addChild(uid, $4.first);
            $$.first = uid;

            string typ($4.type);
            if(typ.compare(0, 4, "list") !=0){
                cout << "TypeError: argument of type '" << typ << "' is not iterable" << endl;
                exit(0);
            }

            string temp1 = newtemp();
            gen("not in",$1.tempvar,$4.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());


            strcpy($$.type, "bool");




            
        }
        ;

    relational_expression : /**/
        shift_expression  { 
            if(debug == 1) cout << "relational expression" << endl;
            $$ = $1;

            strcpy($$.type, $1.type);
        }
        | relational_expression OP_LESS shift_expression { 
            if(debug == 1) cout << "relational expression" << endl;
            int uid = makenode("<", "lt");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("<",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());


            if(strcmp($1.type, "int") != 0 && strcmp($1.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unorderable types: " << $1.type << " >= " << $3.type << endl;
                exit(0);
            }
            if(strcmp($3.type, "int") != 0 && strcmp($3.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unorderable types: " << $1.type << " >= " << $3.type << endl;
                exit(0);
            }
            strcpy($$.type, "bool");
        }
        | relational_expression OP_GREATER shift_expression { 
            if(debug == 1) cout << "relational expression" << endl;
            int uid = makenode(">", "gt");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen(">",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());


            if(strcmp($1.type, "int") != 0 && strcmp($1.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unorderable types: " << $1.type << " >= " << $3.type << endl;
                exit(0);
            }
            if(strcmp($3.type, "int") != 0 && strcmp($3.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unorderable types: " << $1.type << " >= " << $3.type << endl;
                exit(0);
            }
            strcpy($$.type, "bool");
        }
        | relational_expression OP_LESS_EQ shift_expression {
            if(debug == 1) cout << "relational expression" << endl;
            int uid = makenode("<=", "leq");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("<=",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());



            if(strcmp($1.type, "int") != 0 && strcmp($1.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unorderable types: " << $1.type << " >= " << $3.type << endl;
                exit(0);
            }
            if(strcmp($3.type, "int") != 0 && strcmp($3.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unorderable types: " << $1.type << " >= " << $3.type << endl;
                exit(0);
            }
            strcpy($$.type, "bool");
         }
        | relational_expression OP_GREATER_EQ shift_expression {
            if(debug == 1) cout << "relational expression" << endl;
            int uid = makenode(">=", "geq");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen(">=",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());



            if(strcmp($1.type, "int") != 0 && strcmp($1.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unorderable types: " << $1.type << " >= " << $3.type << endl;
                exit(0);
            }
            if(strcmp($3.type, "int") != 0 && strcmp($3.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unorderable types: " << $1.type << " >= " << $3.type << endl;
                exit(0);
            }
            strcpy($$.type, "bool");
        }

        


        ;

    shift_expression : /**/
        additive_expression {
            $$=$1;
            strcpy($$.type, $1.type);
        }
        | shift_expression OP_LSHIFT additive_expression {
            if(debug == 1) cout << "shift expression" << endl;
            int uid = makenode("<<", "lshift");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("<<",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());

            if(strcmp($1.type, "int") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for <<: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }
            if(strcmp($3.type, "int") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for <<: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }

            strcpy($$.type, "int");

         }
        | shift_expression OP_RSHIFT additive_expression { 
            if(debug == 1) cout << "shift expression" << endl;
            int uid = makenode(">>", "rshift");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen(">>",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());

            if(strcmp($1.type, "int") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for >>: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }
            if(strcmp($3.type, "int") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for >>: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }

            strcpy($$.type, "int");
        }
        ;

    additive_expression : /**/
        multiplicative_expression  { 
            if(debug == 1) cout << "additive expression" << endl;
            $$ = $1;
            strcpy($$.type, $1.type);
        }
        | additive_expression OP_PLUS multiplicative_expression { 
            if(debug == 1) cout << "additive expression" << endl;
            int uid = makenode("+", "add");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;


            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            // int a = stoi($1.tempvar);
            // int b = stoi($3.tempvar);
            // string temp = to_string(a+b);
            // gen("",temp,"",temp1);
            gen("+",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());

            if(!(strcmp($1.type,"str")==0 && strcmp($3.type,"str")==0)){
                if(strcmp($1.type, "int") != 0 && strcmp($1.type, "float") != 0){
                    cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for +: '" << $1.type << "' and '" << $3.type << "'" << endl;
                    exit(0);
                }
                if(strcmp($3.type, "int") != 0 && strcmp($3.type, "float") != 0){
                    cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for +: '" << $1.type << "' and '" << $3.type << "'" << endl;
                    exit(0);
                }

                
                strcpy($$.type, "int");
                


            }
            else{
                strcpy($$.type, "str");
            }
        }
        | additive_expression OP_MINUS multiplicative_expression { 
            if(debug == 1) cout << "additive expression" << endl;
            int uid = makenode("-", "sub");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("-",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());


            if(strcmp($1.type, "int") != 0 && strcmp($1.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for -: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }
            if(strcmp($3.type, "int") != 0 && strcmp($3.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for -: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }

            strcpy($$.type, "int");
            
            
        }
        ;

    multiplicative_expression : /**/ 
        exponentiation_expression   { 
            if(debug == 1) cout << "multiplicative expression" << endl;
            $$ = $1;

            strcpy($$.type, $1.type);

        }
        | multiplicative_expression OP_TIMES exponentiation_expression { 
            if(debug == 1) cout << "multiplicative expression" << endl;
            int uid = makenode("*", "mul");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("*",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());


            if(strcmp($1.type, "int") != 0 && strcmp($1.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for *: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }
            if(strcmp($3.type, "int") != 0 && strcmp($3.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for *: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }

            
            strcpy($$.type, "int");
            
            
            
        }
        | multiplicative_expression OP_DIVIDE exponentiation_expression {
            if(debug == 1) cout << "multiplicative expression" << endl;
            int uid = makenode("/", "div");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("/",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());

            if(strcmp($1.type, "int") != 0 && strcmp($1.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for /: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }

            if(strcmp($3.type, "int") != 0 && strcmp($3.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for /: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }

            strcpy($$.type, "int");
         }
        | multiplicative_expression OP_FLOOR exponentiation_expression {
            if(debug == 1) cout << "multiplicative expression" << endl;
            int uid = makenode("//", "floor_div");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("//",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());

            if(strcmp($1.type, "int") != 0 && strcmp($1.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for //: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }
            if(strcmp($3.type, "int") != 0 && strcmp($3.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for //: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }

            strcpy($$.type, "int");
            
         }
        | multiplicative_expression OP_MOD exponentiation_expression { 
            if(debug == 1) cout << "multiplicative expression" << endl;
            int uid = makenode("%", "mod");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("%",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());

            if(strcmp($1.type, "int") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for %: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }
            if(strcmp($3.type, "int") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for %: '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }
        }
        ;

    exponentiation_expression : /**/
        negated_expression     {
            if(debug == 1) cout << "exponentiation expression" << endl;
            $$ = $1;

            strcpy($$.type, $1.type);
            
        
         }
        | negated_expression OP_EXP exponentiation_expression {
            if(debug == 1) cout << "exponentiation expression" << endl;
            int uid = makenode("**", "exp");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            strcpy($$.type, $1.type);

            string temp1 = newtemp();
            gen("**",$1.tempvar,$3.tempvar,temp1);
            strcpy($$.tempvar, temp1.c_str());

            if(strcmp($1.type, "int") != 0 && strcmp($1.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for ** or pow(): '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }
            if(strcmp($3.type, "int") != 0 && strcmp($3.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": unsupported operand type(s) for ** or pow(): '" << $1.type << "' and '" << $3.type << "'" << endl;
                exit(0);
            }

          
            strcpy($$.type, "int");
            

            
            
            
         }
        ;

    negated_expression : /**/
        primary_expression    {
            if(debug == 1) cout << "negated expression" << endl;
            $$ = $1;

            strcpy($$.type, $1.type);
            // cout << $1.type <<endl;
            strcpy($$.tempvar, $1.tempvar);
        }
        | OP_MINUS negated_expression {
            if(debug == 1) cout << "negated expression" << endl;
            int uid = makenode("-", "neg");
            addChild(uid, $2.first);
            $$.first = uid;

            strcpy($$.type, $2.type);

            string temp1 = newtemp();
            gen("-",$2.tempvar,"",temp1);
            strcpy($$.tempvar, temp1.c_str());

            if(strcmp($2.type, "int") != 0 && strcmp($2.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": bad operand type for unary -: '" << $2.type << "'" << endl;
                exit(0);
            }


         }
        | OP_LOGICAL_NOT negated_expression { 
            if(debug == 1) cout << "negated expression" << endl;
            int uid = makenode("not", "not");
            addChild(uid, $2.first);
            $$.first = uid;

            strcpy($$.type, $2.type);

            string temp1 = newtemp();
            gen("not",$2.tempvar,"",temp1);
            strcpy($$.tempvar, temp1.c_str());

            
        }
        | OP_BITWISE_NOT negated_expression {
            if(debug == 1) cout << "negated expression" << endl;
            int uid = makenode("~", "bitwise_not");
            addChild(uid, $2.first);
            $$.first = uid;

            strcpy($$.type, $2.type);

            string temp1 = newtemp();
            gen("~",$2.tempvar,"",temp1);
            strcpy($$.tempvar, temp1.c_str());
            
            if(strcmp($2.type, "int") != 0){
                cout << "TypeError in line " << yylineno << ": bad operand type for unary ~: '" << $2.type << "'" << endl;
                exit(0);
            }
         }
        | OP_PLUS negated_expression { 
            if(debug == 1) cout << "negated expression" << endl;
            int uid = makenode("+", "pos");
            addChild(uid, $2.first);
            $$.first = uid;

            strcpy($$.type, $2.type);

            string temp1 = newtemp();
            gen("+",$2.tempvar,"",temp1);
            strcpy($$.tempvar, temp1.c_str());

            if(strcmp($2.type, "int") != 0 && strcmp($2.type, "float") != 0){
                cout << "TypeError in line " << yylineno << ": bad operand type for unary +: '" << $2.type << "'" << endl;
                exit(0);
            }

        }
        ;

    primary_expression : /**/
        Ids {
            if(debug == 1) cout << "primary expression" << endl;
            $$ = $1;

            strcpy($$.type, $1.type);
            
            // if Ids is arrayaccess (it contain some "]" at last element) then use new temp var to store the value
            if($1.tempvar[strlen($1.tempvar)-1] == ']'){
                strcpy($$.tempvar, newtemp().c_str());
                string var($$.tempvar);
                gen("", $1.tempvar, "", var);
            }
            else{
                strcpy($$.tempvar, $1.tempvar);
            }
        }
        | LITERAL_INT { 
            if(debug == 1) cout << yylval.intNumber << endl; 
            $$.first = makenode(to_string(yylval.intNumber), "int_literal");

            strcpy($$.type, "int");

            // strcpy($$.tempvar, newtemp().c_str());
            // string var($$.tempvar);
            // gen("=", to_string($1), "Null",var);

            strcpy($$.tempvar, to_string($1).c_str());
            
        }
        | LITERAL_FLOAT {
            if(debug == 1) cout << yylval.fltNumber << endl;
            $$.first = makenode(to_string(yylval.fltNumber), "float_literal");

            strcpy($$.type, "float");

            // strcpy($$.tempvar, newtemp().c_str());
            // string var($$.tempvar);
            // gen("=", to_string($1), "Null",var);

            strcpy($$.tempvar, to_string($1).c_str());
         }
        | STRING { 
            if(debug == 1) cout << "string" << endl;
            // add \ to string start and end
            $$.first = makenode($1, "string_literal");

            strcpy($$.type, "str");

            // strcpy($$.tempvar, newtemp().c_str());
            // string var($$.tempvar);

            // gen("=", $1, "Null",var);

            // CHANGE: first store in temp
            string var(newtemp());
            gen("",$1,"",var); 
            strcpy($$.tempvar, var.c_str());

            
        }
        | BYTESTRING { 
            if(debug == 1) cout << "byte string" << endl;
            $$.first = makenode($1, "byte_string");

            strcpy($$.type, "bytes");

            // strcpy($$.tempvar, newtemp().c_str());
            // string var($$.tempvar);
            // gen("=", $1, "Null",var);

            strcpy($$.tempvar, $1);
        }
        | KEY_TRU {
            if(debug == 1) cout << "true" << endl;
            $$.first = makenode("True", "bool_literal");

            strcpy($$.type, "bool");

            // strcpy($$.tempvar, newtemp().c_str());
            // string var($$.tempvar);
            // gen("=", "True", "Null",var);

            strcpy($$.tempvar, "1");
         }
        | KEY_FALS {
            if(debug == 1) cout << "false" << endl;
            $$.first = makenode("False", "bool_literal");

            strcpy($$.type, "bool");

            // strcpy($$.tempvar, newtemp().c_str());
            // string var($$.tempvar);
            // gen("=", "False", "Null",var);

            strcpy($$.tempvar, "0");

         }
        | KEY_NONE { 
            if(debug == 1) cout << "none" << endl;
            $$.first = makenode("None", "none_literal");

            strcpy($$.type, "None");



        }
        | funccallParent { 
            if(debug == 1) cout << "function call" << endl;
            $$ = $1;


            strcpy($$.type, $1.type);
            strcpy($$.tempvar, $1.tempvar);

        }
        | DELIM_LPAR expression DELIM_RPAR { 
            int uid = makenode("()");
            addChild(uid, $2.first);
            $$.first = uid;

            strcpy($$.type, $2.type);
            strcpy($$.tempvar, $2.tempvar);

        }
        | DELIM_LBRACKET List_expression DELIM_RBRACKET {
            // seem incomplete
            int uid = makenode("[]");
            addChild(uid, $2.first);
            $$.first = uid;

            string s($2.type);
            string st= "list[" + s + "]";
            strcpy ($$.type, st.c_str());


            islistexp = 1;
        }
        ;

    funccallParent : /**/
        funccall{
            $$ = $1;

            Sym_Entry *entry = current_table->lookup($1.lexeme);

            if(entry){
                if(entry->token != "function" && entry->token != "class"){
                    cout << "NameError in line " << yylineno << ": name \'" << $1.lexeme<< "\' is not defined "<<endl;
                    exit(0);
                }
                if(entry->token == "class"){
                    // get class scope table
                    SymbolTable *class_table = current_table->findTable("class_"+entry->type);
                    
                    if(debug) cout << "class_" << entry->type << endl;
                    if(class_table){
                        string class_scope = class_table->scope_name;
                        Sym_Entry * class_entry = class_table->lookup(entry->type +".__init__");

                        if(class_entry && class_entry->token == "function" && class_scope == class_entry->scope){
                            
                            
                            if(class_entry->nargs != $1.nelem+1){

                                cout << "TypeError in line " << yylineno << ": __init__() takes " << class_entry->nargs <<  "positional argument but " << $1.nelem+1 << " were given" << endl;
                                exit(0);
                            }
                            else{

                                // Type checking
                                gen("param",to_string(entry->size),"","");
                                gen("call","allocmem","1","");
                                string var = newtemp();
                                gen("returnval","","",var);

                                // potential error here

                                // correct version----------


                                // ------------------

                                // MAJOR CHANGE 
                                int it = $1.nelem;
                                for (int i = funcargs.size()-1; i >= 0; i--){
                                    if(it>0){
                                        gen("param",funcargs[i],"","");
                                        it--;
                                        funcargs.pop_back();
                                    }
                                    else break;
                                }
                                gen("param",var,"","");
                                gen("call",entry->type + ".__init__" ,to_string($1.nelem),"");
                                funcargs.clear();

                                // if(strcmp(entry->type.c_str(), "None") != 0){
                                    string temp1 = newtemp();
                                    gen("returnval","","",temp1);
                                    strcpy($$.tempvar, var.c_str());
                                // }
                            }                          
                        }
                        else
                        {
                            // error for no init funtion
                            cout << "TypeError in line " << yylineno << ": __init__() is not defined" << endl;
                            exit(0);
                        }
                    }
                }
                else{
                    if($1.nelem != entry->nargs){
                        if(debug) cout << "----------func------" <<endl;
                        cout << "Argument Error in line " << yylineno << ": " << $1.lexeme << " takes exactly " << entry->nargs << " arguments (" << $1.nelem << " given)" << endl;
                        exit(0);
                    }
                    else{
                        // take parameters and call function
                        // for(int i=funcargs.size() - 1;i>=0;i--){
                        //     gen("param",funcargs[i],"","");                      
                        // }
                        // for(int i=$1.nelem-1;i>=0;i--){
                        //     cout << funcargs[i+funcargs.size()-1] << " " << $1.lexeme << endl;
                            
                        //     gen("param",funcargs[i+funcargs.size()-1],"","");
                        //     funcargs.pop_back();                      
                        // }
                        // MAJOR CHANGE
                        int it = $1.nelem;
                        for (int i = funcargs.size()-1; i >= 0; i--){
                            if(it>0){
                                gen("param",funcargs[i],"","");
                                it--;
                                funcargs.pop_back();
                            }
                            else break;
                        }
                        gen("call",$1.lexeme,to_string($1.nelem),"");
                        // funcargs.clear();

                        // if(entry->type != "None"){
                            string temp1 = newtemp();
                            gen("returnval","","",temp1);
                            strcpy($$.tempvar, temp1.c_str());
                        // }    
                    }
                }
                strcpy($$.type, entry->type.c_str());
            }
            else {

                if(strcmp($1.lexeme, "print")==0){

                    if($1.nelem == 0){
                        cout << "TypeError in line " << yylineno << ": print() takes at least 1 argument (0 given)" << endl;
                        exit(0);
                    }
                    strcpy($$.type, "None");

                    debugFun("funccallParent");
                    debugFun(to_string(funcargs.size()));
                    for(int i=funcargs.size() - 1;i>=0;i--){
                        gen("param",funcargs[i],"","");                      
                    }
                    if(funcargmap[funcargs[0]] == "str"){
                        gen("call","printstr",to_string($1.nelem),"");
                    }
                    else {
                        gen("call","printint",to_string($1.nelem),"");
                    }
                    

                

                    debugFun("funccallParent");

                    // gen("call",$1.lexeme,to_string($1.nelem),"");
                    funcargs.clear();
                    funcargmap.clear();

                    // if(strcmp($$.type, "None") != 0){
                        string temp1 = newtemp();
                        gen("returnval","","",temp1);
                        strcpy($$.tempvar, temp1.c_str());
                    // }

                }
                else if(strcmp($1.lexeme, "input")==0){
                    if($1.nelem != 0){
                        cout << "TypeError in line " << yylineno << ": input() takes exactly 0 arguments (" << $1.nelem << " given)" << endl;
                        exit(0);
                    }

                    for(int i=funcargs.size() - 1;i>=0;i--){
                        gen("param",funcargs[i],"","");                      
                    }
                    gen("call",$1.lexeme,to_string($1.nelem),"");
                    funcargs.clear();

                    // TO CHECK
                    strcpy($$.type, "str");

                    // if(strcmp($$.type, "None") != 0){
                        string temp1 = newtemp();
                        gen("returnval","","",temp1);
                        strcpy($$.tempvar, temp1.c_str());
                    // }
                    
                }
                else if(strcmp($1.lexeme,"type")==0){
                    if($1.nelem != 1){
                        cout << "TypeError in line " << yylineno << ": type() takes exactly 1 argument (" << $1.nelem << " given)" << endl;
                        exit(0);
                    }
                    for(int i=funcargs.size() - 1;i>=0;i--){
                        gen("param",funcargs[i],"","");                      
                    }
                    gen("call",$1.lexeme,to_string($1.nelem),"");
                    funcargs.clear();

                    strcpy($$.type, "str");

                    // if(strcmp($$.type, "None") != 0){
                        string temp1 = newtemp();
                        gen("returnval","","",temp1);
                        strcpy($$.tempvar, temp1.c_str());
                    // }

                }
                else if(strcmp($1.lexeme,"range")==0){
                    if($1.nelem != 1 && $1.nelem != 2 && $1.nelem != 3){
                        cout << "TypeError in line " << yylineno << ": range() takes 1 to 3 arguments (" << $1.nelem << " given)" << endl;
                        exit(0);
                    }
                    strcpy($$.type, "list[int]");

                    // for(int i=funcargs.size() - 1;i>=0;i--){
                    //     gen("param",funcargs[i],"","");                      
                    // }
                    // gen("call",$1.lexeme,to_string($1.nelem),"");
                    // funcargs.clear();

                    // if(strcmp($$.type, "None") != 0){
                    //     string temp1 = newtemp();
                    //     gen("returnval","","",temp1);
                    //     strcpy($$.tempvar, temp1.c_str());
                    // }

                    // CHANGE: directly storing the range values in tempvar
                    if($1.nelem == 1){
                        string temp1 = newtemp();
                        // gen("*",funcargs[0],"8",temp1);
                        gen("*",funcargs[funcargs.size()-1],"8",temp1);

                        gen("+",temp1,"8",temp1);

                        gen("param",temp1,"","");

                        gen("call","allocmem","1","");

                        string temp2 = newtemp();
                        gen("returnval","","",temp2);

                        // gen("",funcargs[0],"",temp2+"[0]");
                        gen("",funcargs[funcargs.size()-1],"",temp2+"[0]");

                        string temp3 = newtemp();
                        gen("","-1","",temp3);

                        string label = newlabel();
                        gen("label",label,":","");

                        gen("+",temp3,"1",temp3);

                        string temp4 = newtemp();
                        // gen("<",temp3,funcargs[0],temp4);
                        gen("<",temp3,funcargs[funcargs.size()-1],temp4);

                        string label1 = newlabel();
                        gen("goto",temp4,label1,"if");

                        string label2 = newlabel();
                        gen("goto","",label2,"");

                        gen("label",label1,":","");

                        string temp5 = newtemp();
                        gen("*",temp3,"8",temp5);

                        gen("+",temp5,"8",temp5);

                        gen("",temp3,"",temp2+"["+temp5+"]");

                        gen("goto","",label,"");

                        gen("label",label2,":","");

                        strcpy($$.tempvar, temp2.c_str());

                        funcargs.pop_back();
                    }

                    else if($1.nelem == 2){
                        string temp1 = newtemp();
                        // gen("-",funcargs[1],funcargs[0],temp1);
                        gen("-",funcargs[1],funcargs[0],temp1);

                        string temp2 = newtemp();
                        gen("*",temp1,"8",temp2);

                        gen("+",temp2,"8",temp2);

                        gen("param",temp2,"","");

                        gen("call","allocmem","1","");

                        string temp3 = newtemp();

                        gen("returnval","","",temp3);

                        gen("",temp1,"",temp3+"[0]");

                        string temp4 = newtemp();
                        // gen("-",funcargs[0],"1",temp4);
                        gen("-",funcargs[0],"1",temp4);

                        string temp5 = newtemp();
                        gen("","-1","",temp5);

                        string label = newlabel();
                        gen("label",label,":","");

                        gen("+",temp4,"1",temp4);
                        gen("+",temp5,"1",temp5);

                        string temp6 = newtemp();

                        // gen("<",temp4,funcargs[1],temp6);
                        gen("<",temp4,funcargs[1],temp6);

                        string label1 = newlabel();
                        gen("goto",temp6,label1,"if");

                        string label2 = newlabel();
                        gen("goto","",label2,"");

                        gen("label",label1,":","");

                        string temp7 = newtemp();

                        gen("*",temp5,"8",temp7);

                        gen("+",temp7,"8",temp7);

                        gen("",temp4,"",temp3+"["+temp7+"]");

                        gen("goto","",label,"");

                        gen("label",label2,":","");

                        strcpy($$.tempvar, temp3.c_str());

                        // funcargs.clear();
                        funcargs.pop_back();
                        funcargs.pop_back();


                    }



                }
                else if(strcmp($1.lexeme,"len")==0){
                    if($1.nelem != 1){
                        cout << "TypeError in line " << yylineno << ": len() takes exactly 1 argument (" << $1.nelem << " given)" << endl;
                        exit(0);
                    }
                    strcpy($$.type, "int");
                    
                    // for(int i=funcargs.size() - 1;i>=0;i--){
                    //     gen("param",funcargs[i],"","");                      
                    // }
                    // gen("call",$1.lexeme,to_string($1.nelem),"");

                    // CHANGE: accessing len directly without calling the func

                    string temp1 = newtemp();
                    // gen("",funcargs[0]+"[0]","",temp1);
                    gen("",funcargs[funcargs.size()-1]+"[0]","",temp1);
                    // funcargs.clear();
                    funcargs.pop_back();
                    strcpy($$.tempvar, temp1.c_str());

                    // if(strcmp($$.type, "None") != 0){
                    //     string temp1 = newtemp();
                    //     gen("returnval","","",temp1);
                    //     strcpy($$.tempvar, temp1.c_str());
                    // }
                }
                else if(strcmp($1.lexeme,"str")==0){
                    if($1.nelem != 1){
                        cout << "TypeError in line " << yylineno << ": str() takes exactly 1 argument (" << $1.nelem << " given)" << endl;
                        exit(0);
                    }
                    strcpy($$.type, "str");

                                for(int i=funcargs.size() - 1;i>=0;i--){
                                    gen("param",funcargs[i],"","");                      
                                }
                    gen("call",$1.lexeme,to_string($1.nelem),"");
                    funcargs.clear();

                    // if(strcmp($$.type, "None") != 0){
                        string temp1 = newtemp();
                        gen("returnval","","",temp1);
                        strcpy($$.tempvar, temp1.c_str());
                    // }
                }
                else if(strcmp($1.lexeme,"int")==0){
                    if($1.nelem != 1){
                        cout << "TypeError in line " << yylineno << ": int() takes exactly 1 argument (" << $1.nelem << " given)" << endl;
                        exit(0);
                    }
                    strcpy($$.type, "int");

                                for(int i=funcargs.size() - 1;i>=0;i--){
                                    gen("param",funcargs[i],"","");                      
                                }
                    gen("call",$1.lexeme,to_string($1.nelem),"");
                    funcargs.clear();

                    // if(strcmp($$.type, "None") != 0){
                        string temp1 = newtemp();
                        gen("returnval","","",temp1);
                        strcpy($$.tempvar, temp1.c_str());
                    // }
                }
                else if(strcmp($1.lexeme,"float")==0){
                    if($1.nelem != 1){
                        cout << "TypeError in line " << yylineno << ": float() takes exactly 1 argument (" << $1.nelem << " given)" << endl;
                        exit(0);
                    }
                    strcpy($$.type, "float");


                                for(int i=funcargs.size() - 1;i>=0;i--){
                                    gen("param",funcargs[i],"","");                      
                                }
                    gen("call",$1.lexeme,to_string($1.nelem),"");
                    funcargs.clear();

                    // if(strcmp($$.type, "None") != 0){
                        string temp1 = newtemp();
                        gen("returnval","","",temp1);
                        strcpy($$.tempvar, temp1.c_str());
                    // }

                }
                else if(strcmp($1.lexeme,"bool")==0){
                    if($1.nelem != 1){
                        cout << "TypeError in line " << yylineno << ": bool() takes exactly 1 argument (" << $1.nelem << " given)" << endl;
                        exit(0);
                    }
                    strcpy($$.type, "bool");

                                         for(int i=funcargs.size() - 1;i>=0;i--){
                                    gen("param",funcargs[i],"","");                      
                                }
                    gen("call",$1.lexeme,to_string($1.nelem),"");
                    funcargs.clear();

                    // if(strcmp($$.type, "None") != 0){
                        string temp1 = newtemp();
                        gen("returnval","","",temp1);
                        strcpy($$.tempvar, temp1.c_str());
                    // }
                }
                else if(strcmp($1.lexeme,"list")==0){
                    if($1.nelem != 1){
                        cout << "TypeError in line " << yylineno << ": list() takes exactly 1 argument (" << $1.nelem << " given)" << endl;
                        exit(0);
                    }

                                                  for(int i=funcargs.size() - 1;i>=0;i--){
                                    gen("param",funcargs[i],"","");                      
                                }
                    gen("call",$1.lexeme,to_string($1.nelem),"");
                    funcargs.clear();

                    // if(strcmp($$.type, "None") != 0){
                        string temp1 = newtemp();
                        gen("returnval","","",temp1);
                        strcpy($$.tempvar, temp1.c_str());
                    // }

                }
                else if(strcmp($1.lexeme,"bytes")==0){
                    if($1.nelem != 1){
                        cout << "TypeError in line " << yylineno << ": bytes() takes exactly 1 argument (" << $1.nelem << " given)" << endl;
                        exit(0);
                    }
                    strcpy($$.type, "bytes");

                                        for(int i=funcargs.size() - 1;i>=0;i--){
                                    gen("param",funcargs[i],"","");                      
                                }
                    gen("call",$1.lexeme,to_string($1.nelem),"");
                    funcargs.clear();


                    // if(strcmp($$.type, "None") != 0){
                        string temp1 = newtemp();
                        gen("returnval","","",temp1);
                        strcpy($$.tempvar, temp1.c_str());
                    // }
                }
                else if(strcmp($1.lexeme,"ord")==0){
                    if($1.nelem != 1){
                        cout << "TypeError in line " << yylineno << ": ord() takes exactly 1 argument (" << $1.nelem << " given)" <<endl;
                        exit(0);
                    }
                    strcpy($$.type, "int");

                                            for(int i=funcargs.size() - 1;i>=0;i--){
                                    gen("param",funcargs[i],"","");                      
                                }
                    gen("call",$1.lexeme,to_string($1.nelem),"");
                    funcargs.clear();

                    // if(strcmp($$.type, "None") != 0){
                        string temp1 = newtemp();
                        gen("returnval","","",temp1);
                        strcpy($$.tempvar, temp1.c_str());
                    // }
                }
                else{
                    cout << "NameError in line " << yylineno << ": name \'" << $1.lexeme << "\' is not defined "<<endl;
                    exit(0);
                }
            }
        }
        |

        IDENTIFIER DELIM_DOT funccall{
            int uid = makenode("atomic_expr");
            addChild(uid, makenode($1, "name"));
            int dot = makenode(".", "dot");
            addChild(uid, dot);
            addChild(dot, $3.first);
            $$.first = uid;

            Sym_Entry *entry = current_table->lookup($1);
            // ye kisi class object ka funccall hai
            int flag=0;
            if(entry){
                for(const auto &pair : classlist){
                    if(pair.first == entry->type ){
                        // cout << pair.first << " " << pair.second << endl;
                        flag=1;
                        break;
                    }

                }
                if(debug) cout << " flag                           "  << $1 <<"  " << flag << " " << entry->type << endl;
                if(flag==1){
                    // cout << "class" << endl;
                    // get class scope table
                    SymbolTable *class_table = current_table->findTable("class_"+entry->type);

                    if(class_table){
                        string class_scope = class_table->scope_name;
                        Sym_Entry * class_entry = class_table->lookup(entry->type + "."+$3.lexeme);

                        if(debug) cout << "class_" << entry->type << " "<< $3.lexeme << endl;


                        if(class_entry && class_entry->token == "function" && class_scope == class_entry->scope){
                            
                            
                            if( inclass > 0 && class_entry->nargs != $3.nelem){
                                cout << "TypeError in line " << yylineno << ": " << entry->type<< "."<<$3.lexeme << " takes "<< class_entry->nargs << " positional argument but " << $3.nelem << " were given" << endl;
                                exit(0);
                            }
                            else if(inclass == 0 && class_entry->nargs != $3.nelem+1){
                                cout << "TypeError in line " << yylineno << ": " << entry->type<< "."<<$3.lexeme << " takes "<< class_entry->nargs << " positional argument but " << $3.nelem+1 << " were given" << endl;
                                exit(0);
                            }
                            else{

                                // Type checking
                                // gen("param",)
                                // string temp1 = newtemp();
                                // gen("",getSize($1.type),"",temp1);
                                // gen("param",temp1,"","");
                                // gen("call","allocmem","1","");
                                // string var = newtemp();
                                // gen("popparam",var,"","");



                                for(int i=funcargs.size() - 1;i>=0;i--){
                                    gen("param",funcargs[i],"","");                      
                                }
                                gen("param",$1,"","");
                                gen("call",entry->type + "." + $3.lexeme,to_string($3.nelem+1),"");
                                funcargs.clear();

                                // if(strcmp($3.type, "None") != 0){
                                    string temp1 = newtemp();
                                    gen("returnval","","",temp1);
                                    strcpy($$.tempvar, temp1.c_str());
                                // }
                            }
                        }
                        else if(class_entry && class_entry->token == "function" && class_scope != class_entry->scope){
                            cout << "AttributeError in line " << yylineno << ": \'" << entry->type << "\' object has no attribute \'" << $3.lexeme << "\'" << endl;
                            exit(0);
                        }
                        strcpy($$.type, class_entry->type.c_str());
                    }
                }
            }
            if(flag == 0 && entry->type.compare(0, 4, "list")==0){
                if(strcmp($3.lexeme, "append")==0){
                    if($3.nelem != 1){
                        cout << "TypeError in line " << yylineno << ": append() takes exactly 1 argument (" << $3.nelem << " given)" << endl;
                        exit(0);
                    }
                    strcpy($$.type, "None");




                                for(int i=funcargs.size() - 1;i>=0;i--){
                                    gen("param",funcargs[i],"","");                      
                                }
                    gen("param",$1,"","");
                    gen("call",entry->type + "." + $3.lexeme,to_string($3.nelem+1),"");
                    funcargs.clear();

                    // if(strcmp($3.type, "None") != 0){
                        string temp1 = newtemp();
                        gen("returnval","","",temp1);
                        strcpy($$.tempvar, temp1.c_str());
                    // }
                }
                else if(strcmp($3.lexeme, "pop")==0){
                    if($3.nelem != 0 && $3.nelem != 1){
                        cout << "TypeError in line " << yylineno << ": pop() takes 0 or 1 argument (" << $3.nelem << " given)" << endl;
                        exit(0);
                    }

                                 for(int i=funcargs.size() - 1;i>=0;i--){
                                    gen("param",funcargs[i],"","");                      
                                }
                    strcpy($$.type, "None");
                    gen("call",entry->type + "." + $3.lexeme,to_string($3.nelem+1),"");
                    funcargs.clear();

                    // if(strcmp($$.type, "None") != 0){
                        string temp1 = newtemp();
                        gen("returnval","","",temp1);
                        strcpy($$.tempvar, temp1.c_str());
                    // }
                }
                else if(strcmp($3.lexeme, "insert")==0){
                    if($3.nelem != 2){
                        cout << "TypeError in line " << yylineno << ": insert() takes exactly 2 arguments (" << $3.nelem << " given)" << endl;
                        exit(0);
                    }
                    strcpy($$.type, "None");


                                        for(int i=funcargs.size() - 1;i>=0;i--){
                                    gen("param",funcargs[i],"","");                      
                                }
                    gen("call",entry->type + "." + $3.lexeme,to_string($3.nelem+1),"");
                    funcargs.clear();

                    // if(strcmp($$.type, "None") != 0){
                        string temp1 = newtemp();
                        gen("returnval","","",temp1);
                        strcpy($$.tempvar, temp1.c_str());
                    // }
                }
                else if(strcmp($3.lexeme, "remove")==0){
                    if($3.nelem != 1){
                        cout << "TypeError in line " << yylineno << ": remove() takes exactly 1 argument (" << $3.nelem << " given)" << endl;
                        exit(0);
                    }
                    strcpy($$.type, "None");


                                for(int i=funcargs.size() - 1;i>=0;i--){
                                    gen("param",funcargs[i],"","");                      
                                }
                    gen("call",entry->type + "." + $3.lexeme,to_string($3.nelem+1),"");
                    funcargs.clear();

                    // if(strcmp($$.type, "None") != 0){
                        string temp1 = newtemp();
                        gen("returnval","","",temp1);
                        strcpy($$.tempvar, temp1.c_str());
                    // }
                }
                else if(strcmp($3.lexeme, "reverse")==0){
                    if($3.nelem != 0){
                        cout << "TypeError in line " << yylineno << ": reverse() takes exactly 0 argument (" << $3.nelem << " given)" << endl;
                        exit(0);
                    }
                    strcpy($$.type, "None");


                                for(int i=funcargs.size() - 1;i>=0;i--){
                                    gen("param",funcargs[i],"","");                      
                                }
                    gen("call",entry->type + "." + $3.lexeme,to_string($3.nelem+1),"");
                    funcargs.clear();

                    // if(strcmp($$.type, "None") != 0){
                        string temp1 = newtemp();
                        gen("returnval","","",temp1);
                        strcpy($$.tempvar, temp1.c_str());
                    // }
                }
                else if(strcmp($3.lexeme, "sort")==0){
                    if($3.nelem != 0 && $3.nelem != 1){
                        cout << "TypeError in line " << yylineno << ": sort() takes 0 or 1 argument (" << $3.nelem << " given)" << endl;
                        exit(0);
                    }
                    strcpy($$.type, "None");


                                for(int i=funcargs.size() - 1;i>=0;i--){
                                    gen("param",funcargs[i],"","");                      
                                }
                    gen("call",entry->type + "." + $3.lexeme,to_string($3.nelem+1),"");
                    funcargs.clear();

                    // if(strcmp($$.type, "None") != 0){
                        string temp1 = newtemp();
                        gen("returnval","","",temp1);
                        strcpy($$.tempvar, temp1.c_str());
                    // }
                }
                else{
                    cout << "NameError in line " << yylineno << ": name \'" << $3.lexeme << "\' is not defined "<<endl;
                    exit(0);
                }
            }
            else if(flag == 0){
                cout << "NameError in line " << yylineno << ": name \'" << $1 << "\' is not defined "<<endl;
                exit(0);            
            }

            
        }
        |
        RES_ID_SELF DELIM_DOT funccall{
            // This seems like incomplete
            int uid = makenode("atomic_expr");
            addChild(uid, makenode("self", "name"));
            int dot = makenode(".", "dot");
            addChild(uid, dot);
            addChild(dot, $3.first);
            $$.first = uid;


            Sym_Entry *entry = current_table->lookup("self");

            // khudke function ka funccall hai ye

            if(entry){
                for(auto it: classlist){
                    if(it.first == entry->type){
                        SymbolTable *class_table = current_table->findTable("class_"+it.first);
                        Sym_Entry *identry = class_table->lookup($3.lexeme);
                        if(identry){
                            strcpy($$.type, $3.type);
                            strcpy($$.lexeme, $3.lexeme);
                        }
                        else{
                            cout << "NameError: name \'" << $3.lexeme << "\' is not defined in line "<< yylineno << endl;
                            exit(0);
                        }
                    }
                }

            }
            else{
                if(inclass >0 ){
                    SymbolTable *class_table = current_table->findTable(scopes.top());
                    Sym_Entry *identry = class_table->lookup($3.lexeme);
                    if(identry){
                        strcpy($$.type, $3.type);
                        strcpy($$.lexeme, $3.lexeme);
                    }
                    else{
                        cout << "NameError: name \'" << $3.lexeme << "\' is not defined in line "<< yylineno << endl;
                        exit(0);
                    }

                    // strcpy($$.type, class_entry->type.c_str());
                }
                else{
                    cout << "NameError: name 'self' is not defined in line "<< yylineno << endl;
                    exit(0);
                }
            }
        }

    /* Function Call */
    funccall : /**/
        Names DELIM_LPAR arguments DELIM_RPAR {
            int uid = makenode("atomic_expr");
            addChild(uid, $1.first);
            int child = makenode("()");
            addChild(uid, child);
            addChild(child, $3.first);
            $$.first = uid;
            $$.nelem = $3.nelem;
            strcpy($$.lexeme, tree[$1.first].first.c_str());
            nelem=0;
            debugFun("funccall");
        }
     
        ;
    
    arguments : /* used in */
        expression { 
            if(debug == 1) cout << "arguments" << endl;
            $$ = $1;
            $$.nelem = 1;

            funcargs.push_back($1.tempvar);
            funcargmap[$1.tempvar] = $1.type;
        }
        | arguments DELIM_COMMA expression {
            if(debug == 1) cout << "arguments" << endl;
            int uid = makenode(",", "comma");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;

            $$.nelem = $1.nelem + 1;

            funcargs.push_back($3.tempvar);
            funcargmap[$3.tempvar] = $3.type;
        }
        | %empty  {
            $$.first = -1;
            $$.nelem = 0;
        }
        ;
    /* COMPOUND STATEMENT */

    compoundstatement : /**/
        ifstatement  {
            if(debug == 1) cout << "compound statement" << endl;
            $$=$1;
        }
        | whilestatement  { 
            if(debug == 1) cout << "compound statement" << endl;
            $$ = $1;
        }
        | forstatement  { 
            if(debug == 1) cout << "compound statement" << endl;
            $$ = $1;
        }
        | funcdef  { 
            if(debug == 1) cout << "compound statement" << endl;
            debugFun("In cmpd statement, Offset is " + to_string(offset));
            $$ = $1;
        }
        | classdef  { 
            if(debug == 1) cout << "compound statement" << endl;
            $$ = $1;
        }
        ;

    /* If Statement */
    
    ifstatement : /**/
        ifstatement1 elifblocks elseblock {
            if(debug == 1) cout << "if statement" << endl;
            $$ = $1;
            addChild($$.first, $2.first);
            addChild($$.first, $3.first);

            backpatch();
            labels.pop_back();

            debugFun("Top ----- 888 of label is " + labels[labels.size()-1].first + "Size of labels is " + to_string(labels.size()));

        }
        | ifstatement1 elifblocks { 
            if(debug == 1) cout << "if statement" << endl;
            $$ = $1;
            addChild($$.first, $2.first);

            backpatch();
            labels.pop_back();

            debugFun("Top of label is " + labels[labels.size()-1].first + "Size of labels is " + to_string(labels.size()));

        }
        | ifstatement1 elseblock { 
            if(debug == 1) cout << "if statement" << endl;
            $$ = $1;
            addChild($$.first, $2.first);

            backpatch();
            labels.pop_back();

            debugFun("Top of label is " + labels[labels.size()-1].first + "Size of labels is " + to_string(labels.size()));

        }
        | ifstatement1 { 
            if(debug == 1) cout << "if statement4" << endl;
            $$ = $1;

            backpatch();
            labels.pop_back();

            debugFun("Top of label is " + labels[labels.size()-1].first + "Size of labels is " + to_string(labels.size()));

        }
        ;

    ifstatement1 : /**/
        ifstart Suite {
            $$ = $1;
            addChild($$.first, $2.first);
            merge_top_vec_quad();
            
            gen("goto","","","");
            gen("label",labels[labels.size()-1].first,":","");

        };
    

    ifstart : /**/
        KEY_IF expression DELIM_COLON {
            int uid = makenode("if", "if");
            addChild(uid, $2.first);
            addChild(uid, makenode(":"));
            $$.first = uid;

            // this label is for suit of if
            string label = newlabel();
            gen("goto",$2.tempvar,label,"if");
            string label1 = newlabel();
            gen("goto","",label1,"");
            debugFun(label1 + "-------------------");
            debugFun("Top of label is " + labels[labels.size()-1].first);

            labels.push_back(make_pair(label1,"if.false"));

            // for its suite
            gen("label",label,":","");

            new_quad_array();
        }

    elifblocks : /**/
        elifblock  { 
            if(debug == 1) cout << "elifblocks" << endl;
            $$ = $1;
        }
        | elifblocks elifblock   {
            if(debug == 1) cout << "elifblocks" << endl;
            int uid = makenode("elif");
            addChild(uid, $1.first);
            addChild(uid, $2.first);
            $$.first = uid;
        }
        ;

    elifblock : /**/
        elifstart Suite  {
            if(debug == 1) cout << "elifblock" << endl;
            $$ = $1;
            addChild($$.first, $2.first);
            merge_top_vec_quad();

            gen("goto","","","");
            gen("label",labels[labels.size()-1].first,":","");


         }
        ;

    elifstart : /**/
        KEY_ELIF expression DELIM_COLON {
            if(debug == 1) cout << "elif start" << endl;
            int uid = makenode("elif", "elif");
            addChild(uid, $2.first);
            addChild(uid, makenode(":"));
            $$.first = uid;

            // label for its suite
            string label = newlabel();
            gen("goto",$2.tempvar,label,"if");

            // label of previous elseif block is not of any use
            labels.pop_back();

            // for next elif/next code
            string label1 = newlabel();
            gen("goto","",label1,"");

            labels.push_back(make_pair(label1,"elif.false"));


            // declaration for its suite
            gen("label",label,":","");


            new_quad_array();
        }
        ;

    elseblock : /**/
        elsestart Suite  { 
            if(debug == 1) cout << "elseblock" << endl;
            $$ = $1;
            addChild($$.first, $2.first);
            merge_top_vec_quad();


            gen("label",labels[labels.size()-1].first,":","");

        }
        ;

    elsestart : /**/
        KEY_ELSE DELIM_COLON {

            if(debug == 1) cout << "else start" << endl;
            int uid = makenode("else", "else");
            addChild(uid, makenode(":"));
            $$.first = uid;

            // label of previous elseif block is not of any use
            labels.pop_back();

            // it's suite will continue in same label, so its for next
            string label = newlabel();
            labels.push_back(make_pair(label,"else.false"));


            new_quad_array();
        }
        ;


    /* While Statement */
    whilestatement : /**/
        whilestatement1 elseblock  {
            if(debug == 1) cout << "while statement" << endl;
            // int uid = makenode("while", "while");
            // addChild(uid, $2);
            // addChild(uid, makenode(":"));
            // addChild(uid, $4);
            // addChild(uid, $5);
            $$ = $1;
            addChild($$.first, $2.first);

            backpatch();
            labels.pop_back();


         }
        | whilestatement1  { 
            if(debug == 1) cout << "while statement" << endl;
            // int uid = makenode("while", "while");
            // addChild(uid, $2);
            // addChild(uid, makenode(":"));
            // addChild(uid, $4);
            $$ = $1;

            // auto it = quad.rbegin();
            // it++;
            // it++;
            // quad.erase(it.base());
            backpatch();
            labels.pop_back();



        }
        ;

    
    whilestatement1 : /**/
        whilestart Suite {
            if(debug == 1) cout << "while statement" << endl;
            // int uid = makenode("while", "while");
            // addChild(uid, $1);
            // addChild(uid, makenode(":"));
            // addChild(uid, $2);
            $$ = $1;
            addChild($$.first, $2.first);
            // current_table= table_stack.top();
            // table_stack.pop();
            // current_scope = scopes.top();
            // scopes.pop();
            // offset = offsets.top();
            // offsets.pop();

            merge_top_vec_quad();


            gen("goto","","","");
            gen("label",labels[labels.size()-1].first,":","");
            labels.pop_back();

        }

    whilestart : /**/
        while expression DELIM_COLON {
            if(debug == 1) cout << "while start" << endl;
            int uid = makenode("while", "while");
            addChild(uid, $2.first);
            addChild(uid, makenode(":"));
            $$.first = uid;
            // table_stack.push(current_table);
            // current_table = new SymbolTable(current_table);
            // list_of_tables.push_back(current_table);
            // scopes.push(current_scope);
            // string new_scope = "while_";
            // current_scope = new_scope;
            // offsets.push(offset);
            // int new_offset = 0;
            // offset = new_offset;

            // string label = newlabel();
            // gen("label",label,":","");

            // gen("",$2.tempvar,"","");
            string label = newlabel();
            gen("goto",$2.tempvar,label,"if");
            // labels.push_back(label);
            string label1 = newlabel();

            // will be used to create next label
            gen("goto","",label1,"");
            labels.push_back(make_pair(label1,"while.false"));

            // for its suite
            gen("label",label,":","");


            new_quad_array();
        }
        ;

    while: 
        KEY_WHILE {
            string label = newlabel();
            gen("label",label,":","");
            labels.push_back(make_pair(label,"while.next"));
        }


    /* For Statement */

    forstatement : /**/
        forstatement1 elseblock  {
            if(debug == 1) cout << "for statement" << endl;
            // int uid = makenode("for", "for");
            // addChild(uid, $2);
            // addChild(uid, makenode(":"));
            // addChild(uid, $4);
            // addChild(uid, $5);
            $$ = $1;
            addChild($$.first, $2.first);

            backpatch();
            labels.pop_back();
         }
        | forstatement1  {
            if(debug == 1) cout << "for statement" << endl;
            // int uid = makenode("for", "for");
            // addChild(uid, $2);
            // addChild(uid, makenode(":"));
            // addChild(uid, $4);
            $$ = $1;
            // addChild($$, $2);

            backpatch();
            labels.pop_back();
         }
        ;

    forstatement1 : /**/
        forstart Suite {
            if(debug == 1) cout << "for statement" << endl;
            // int uid = makenode("while", "while");
            // addChild(uid, $1);
            // addChild(uid, makenode(":"));
            // addChild(uid, $2);
            $$ = $1;
            addChild($$.first, $2.first);
            // current_table= table_stack.top();
            // table_stack.pop();
            // current_scope = scopes.top();
            // scopes.pop();
            // offset = offsets.top();
            // offsets.pop();
            merge_top_vec_quad();
        
            gen("goto","","","");
            gen("label",labels[labels.size()-1].first,":","");
            labels.pop_back();


        }
    forstart : /**/
        for for_expression DELIM_COLON {
            if(debug == 1) cout << "for start" << endl;
            int uid = makenode("for", "for");
            addChild(uid, $2.first);
            addChild(uid, makenode(":"));
            $$.first = uid;
            // table_stack.push(current_table);
            // current_table = new SymbolTable(current_table);
            // list_of_tables.push_back(current_table);
            // scopes.push(current_scope);
            // string new_scope = "while_";
            // current_scope = new_scope;
            // offsets.push(offset);
            // int new_offset = 0;
            // offset = new_offset;

            // string label = newlabel();
            // gen("label",label,":","");

            // gen("",$2.tempvar,"","");
            // string label = newlabel();
            // gen("goto",$2.tempvar,label,"if");
            // // labels.push_back(label);
            // string label1 = newlabel();
            // gen("goto","",label1,"");
            // labels.push_back(make_pair(label1,"for.false"));
            // gen("label",label,":","");

            new_quad_array();
        }

    for : /**/
        KEY_FOR {
            if(debug == 1) cout << "for start" << endl;
        }
        ;
    
    /* forstatement2 : 
        for_expression DELIM_COLON{

        }  */

    for_expression : /**/
        Names KEY_IN Assignable_List     { 
            if(debug == 1) cout << "for expression" << endl;
            int uid = makenode("in");
            addChild(uid, $1.first);
            addChild(uid, $3.first);


            $$.first = uid; 

            Sym_Entry *entry = current_table->lookup(tree[$1.first].first);


            // if(entry && entry->scope == current_scope){

            //     cout << "Variable Redeclaration Error: " << tree[$1.first].first << endl;
            //     exit(0);
            // }
            // else{

                int k=0;
                char ty[100];
                for(int i=5 ;i<strlen($3.type)-1;i++){
                    ty[k++]= $3.type[i];
                }
                ty[k]='\0';
                // strcpy($$.type,ty);

                string s(ty);


                // tasktodo : CAN BE PROBLEMATIC 

            
                if(entry && current_scope == entry->scope){
                    entry->type = s;
                    entry->size = getSize(s);
                    entry->offset = offset;
                    offset += getSize(s);
                    //it is basically a redeclaration
                }
                else{

                    current_table->entry(tree[$1.first].first, "variable",s , getSize(s), offset, current_scope, yylineno, nelem);
                    offset += getSize(s);

                }

                // string temp1 = newtemp();
                // gen("in",$1.lexeme,$3.tempvar,temp1);
                // strcpy($$.tempvar, temp1.c_str());
                
                string temp = newtemp();
                gen("","-1","",temp);

                string ForNext = newlabel();
                string ForFalse = newlabel();
                string ForTrue = newlabel();

                // gen("param", $3.tempvar, "", "");
                // gen("call", "len", "1", "");
                string temp1 = newtemp();
                // gen("returnval", "", "", temp1);
                string var($3.tempvar);
                gen("",var+"[0]","",temp1);

                gen("label",ForNext,":","");
                gen("+", temp, "1", temp);


                // call procedure for getting length of list $3.tempvar

                // generate conditional goto for for.true
                string temp2 = newtemp();
                gen("<", temp, temp1, temp2);
                gen("goto", temp2, ForTrue, "if");
                gen("goto", "", ForFalse, "");

                // generate label for for.true
                gen("label", ForTrue, ":", "");

                
                // generate code for assignment of $1.lexeme = $3.tempvar[temp]

                // using elevated array acceses
                string temp3 = newtemp();
                gen("*", temp, to_string(getSize(s)), temp3);

                gen("+", temp3,to_string(getSize(s)), temp3);
                string arracc = $3.tempvar;
                arracc +=  "[" + temp3 + "]";
                gen("",arracc ,"",  $1.lexeme);

                // labels.push_back(make_pair(label,"for.next"));

                // Pushing required labels
                labels.push_back(make_pair(ForNext,"for.next"));
                labels.push_back(make_pair(ForFalse,"for.false"));


            // }
        }
        ;

    Assignable_List : /* used in for expression */
        funccallParent   {
            if(debug == 1) cout << "for list" << endl;
            $$ = $1;

            string typ($1.type);

            if(typ.compare(0, 4, "list") != 0){
                cout << "TypeError in line " << yylineno << ": \'" << typ <<"\' object is not iterable"<<   endl;
                exit(0);
            }
         }
        | Ids  {
            if(debug == 1) cout << "for list" << endl;
            $$ = $1;
            // Sym_Entry *entry = current_table->lookup(tree[$1.first].first);
            // if(entry && entry->scope == current_scope){
                string typ($1.type);
                if(typ.compare(0, 4, "list") != 0){
                    // cout<< "Error : " << tree[$1.first].first << " in line number " <<yylineno << endl;
                    cout << "TypeError in line " << yylineno << ": \'" << typ <<"\' object is not iterable"<<   endl;
                    exit(0);
                }


         }
        | DELIM_LBRACKET List_expression DELIM_RBRACKET {
            // is case me memory allocate nahi hui hai
            // incomplete
            if(debug == 1) cout << "for list" << endl;
            int uid = makenode("[]");
            addChild(uid, $2.first);
            $$.first = uid;

            string s($2.type);
            string st= "list[" + s + "]";
            strcpy ($$.type, st.c_str());
        }
    


    /* Function Definition */


    funcdef : /**/
        funcstart Suite  { 
            if(debug == 1) cout << "function definition" << endl;
            int uid = $1.first;
            // int PARs = makenode("()");
            // addChild(PARs, $2.first);
            // addChild(PARs, $4);
            // addChild(uid, PARs);
            // addChild(uid, $3.first);
            // addChild(uid, makenode(":"));
            addChild(uid, $2.first);
            $$ = $1;

            current_table = table_stack.top();
            table_stack.pop();
            current_scope = scopes.top();
            scopes.pop();
            offset = offsets.top();
            offsets.pop();

            infunction = 0;
            // if(quad[quad.size()-1].op != "goto")gen("goto", "", "", "ra");
            gen("endfunc", "","","");
        }
        ;

    funcstart : /**/
        KEY_DEF Names DELIM_LPAR params DELIM_RPAR DELIM_ARROW Return_Type DELIM_COLON {
            if(debug == 1) cout << "function start" << endl;
            int uid = makenode("def");
            addChild(uid, $2.first);
            int PARs = makenode("()");
            addChild(uid, PARs);
            addChild(PARs, $4.first);
            addChild(uid, $7.first);
            addChild(uid, makenode(":"));
            $$.first = uid;

            infunction = 1;
            funclist.push_back({tree[$2.first].first,current_scope});

            nelem = $4.nelem;

            int func_stack_size  = 0;
            if(!inclass){
                current_table->entry(tree[$2.first].first, "function", $7.type, func_stack_size, offset, current_scope, yylineno, $4.nelem);
            }
            else {
                current_table->entry(current_scope.substr(6,current_scope.size()) + "." + tree[$2.first].first, "function", $7.type, func_stack_size, offset, current_scope, yylineno, $4.nelem);    
            }
            // offset += getSize("function");
            offset += 0;
            debugFun("In function offset is " + to_string(offset) + " and size is " + to_string(func_stack_size) + " and scope is " + current_scope);

            table_stack.push(current_table);
            if(!inclass){
                current_table = new SymbolTable(current_table,"func_" + tree[$2.first].first);
                list_of_tables.push_back(current_table);
                scopes.push(current_scope);
                string new_scope = "func_" + tree[$2.first].first;
                current_scope = new_scope;
            }
            else{
                current_table = new SymbolTable(current_table,"func_" + current_scope.substr(6,current_scope.size()) + "." + tree[$2.first].first);
                list_of_tables.push_back(current_table);
                scopes.push(current_scope);
                string new_scope = "func_" + scopes.top().substr(6,scopes.top().size()) + "." + tree[$2.first].first;
                current_scope = new_scope;
            }
            
            // current_scope = new_scope;
            offsets.push(offset);
            int new_offset = 0;
            offset = new_offset;


            strcpy(curr_rtype, $7.type);
            nelem = 0;


            // gen("LABEL", tree[$2.first].first);


            if(inclass > 0){
                gen("beginfunc",scopes.top().substr(6,scopes.top().size()) + "." + $2.lexeme,":", "");
             
            }
            else{
                gen("beginfunc",$2.lexeme,":", "");
            }
            

            // gen("popparam","","","ra");

            

            // if(funcparams.size()){
            for(int i=0; i< funcparams.size();i++){
                current_table->entry(funcparams[i].first.first, "parameter", funcparams[i].second.first, getSize(funcparams[i].second.first), offset, current_scope, funcparams[i].first.second, funcparams[i].second.second); 
                offset += getSize(funcparams[i].second.first);
                gen("popparam","", "",funcparams[i].first.first);

                debugFun("param " + funcparams[i].first.first + " " + funcparams[i].second.first + " " + to_string(funcparams[i].second.second));


            }

            // }

            funcargno = -1;
            funcparams.clear();



        
        }
        | KEY_DEF Names DELIM_LPAR params DELIM_RPAR DELIM_COLON {
            if(debug == 1) cout << "function start" << endl;
            int uid = makenode("def");
            addChild(uid, $2.first);
            int PARs = makenode("()");
            addChild(uid, PARs);
            addChild(PARs, $4.first);
            addChild(uid, makenode(":"));
            $$.first = uid;

            infunction = 1;
            funclist.push_back({tree[$2.first].first,current_scope});

            nelem = $4.nelem;

            int func_stack_size  = 0;
            // cout << "Current Scope is " << current_scope << endl;

            if(!inclass){
                current_table->entry(tree[$2.first].first, "function", "None", func_stack_size, offset, current_scope, yylineno, $4.nelem);
            }
            else {
                current_table->entry(current_scope.substr(6,current_scope.size()) + "." + tree[$2.first].first, "function", "None", func_stack_size, offset, current_scope, yylineno, $4.nelem);    
            }
            // offset += getSize("function");
            offset += 0;
            debugFun("In function offset is " + to_string(offset) + " and size is " + to_string(func_stack_size) + " and scope is " + current_scope);

            table_stack.push(current_table);
            if(!inclass){
                current_table = new SymbolTable(current_table,"func_" + tree[$2.first].first);
                list_of_tables.push_back(current_table);
                scopes.push(current_scope);
                string new_scope = "func_" + tree[$2.first].first;
                current_scope = new_scope;
            }
            else{
                current_table = new SymbolTable(current_table,"func_" + current_scope.substr(6,current_scope.size()) + "." + tree[$2.first].first);
                list_of_tables.push_back(current_table);
                scopes.push(current_scope);
                string new_scope = "func_" + scopes.top().substr(6,scopes.top().size()) + "." + tree[$2.first].first;
                current_scope = new_scope;
            }
            offsets.push(offset);
            int new_offset = 0;
            offset = new_offset;
            nelem = 0;

            if(inclass > 0){
                gen("beginfunc",scopes.top().substr(6,scopes.top().size()) + "." + $2.lexeme,":","");
                
            }
            else{
                // gen($2.lexeme,":", "","");
                gen("beginfunc", $2.lexeme,":","");
            }

            

            // gen("popparam","","","ra");



            if(funcparams.size()){
                for(int i=0; i< funcparams.size();i++){
                    current_table->entry(funcparams[i].first.first, "parameter", funcparams[i].second.first, getSize(funcparams[i].second.first), offset, current_scope, funcparams[i].first.second, funcparams[i].second.second); 
                    offset += getSize(funcparams[i].second.first);

                    if(debug) cout << funcparams[i].first.first << "----------- " << funcparams[i].second.first << " " << funcparams[i].second.second << endl;

                    gen("popparam","","",funcparams[i].first.first);
                }

            }

            funcargno = -1;
            funcparams.clear();

        }

    
    params : /**/
        Variable_Declaration  {
            if(debug == 1) cout << "params" << endl;
            $$ = $1;
            $$.nelem = 1;

            if(funcargno == -1){
                funcargno = 1;
            }
            else{
                funcargno++;
            }

            funcparams.push_back({{$1.lexeme,yylineno},{$1.type,funcargno}});

        }
        | params DELIM_COMMA Variable_Declaration {
            if(debug == 1) cout << "params" << endl;
            int uid = makenode(",", "comma");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;
            $$.nelem = $1.nelem + 1;

            funcargno++;

            funcparams.push_back({{$3.lexeme,yylineno},{$3.type,funcargno}});
        }
        | RES_ID_SELF {
            if(debug == 1) cout << "params" << endl;
            $$.first = makenode("self","name");
            $$.nelem = 1;
            if(funcargno == -1){
                funcargno = 1;
            }
            else{
                funcargno++;
            }
            funcparams.push_back({{$1,yylineno},{"object",funcargno}});
        }
        | %empty {
            if(debug == 1) cout << "params" << endl;
            $$.first = -1;
            $$.nelem = 0;
        }
        ;  
    Return_Type : /**/
        Primitive_Type { 
            if(debug == 1) cout << "return type" << endl;
            $$ = $1;

        
        }
        /* | List_Type { cout << "return type" << endl;} */
        | KEY_NONE { 
            if(debug == 1) cout << "return type" << endl;
            $$.first = makenode("None", "none_literal");
            strcpy($$.type ,"None");
        }

    Suite : /**/
        simplestatement NEWLINE { 
            debugFun("Offset is " + to_string(offset));
            if(debug == 1) cout << "suite" << endl;
            $$ = $1;
        }
        | NEWLINE INDENT statements DEDENT { 
            debugFun("Offset-- is " + to_string(offset));
            if(debug == 1) cout << "--------------" << endl;
            $$ = $3;
        }
        ; 



    // Pending 3AC
    //  will include inheritance in declaration
    classdef : /**/
        classstart DELIM_COLON Suite    { 
            debugFun("Class Definition");
            debugFun("offset is " + to_string(offset));

            int uid = $1.first;
            // addChild(uid, $2);
            addChild(uid, makenode(":"));
            addChild(uid, $3.first);
            $$.first = uid;

            $$=$1;
            current_table = table_stack.top();

            // here update the offset of the class in its class entry in current table
            Sym_Entry *entry = current_table->lookup($$.lexeme);
            if(entry){
                entry->size = offset;
                debugFun("Class Entry found and offset updated to " + to_string(offset));
            }
            else{
                cout << "Internal Error: Class Entry not found" << endl;
                exit(0);
            }

            table_stack.pop();
            current_scope = scopes.top();
            scopes.pop();
            offset = offsets.top();
            offsets.pop();
            inclass --;

        }
        | classstart DELIM_LPAR classarguments DELIM_RPAR DELIM_COLON Suite  { 
            debugFun("Class Definition, Inherited");
            debugFun("offset is " + to_string(offset));

            int uid = $1.first;
            int PARs = makenode("()");
            addChild(PARs, $3.first);
            addChild(uid, PARs);
            addChild(uid, makenode(":"));
            addChild(uid, $6.first);
            $$.first = uid;
            current_table = table_stack.top();

            // here update the offset of the class in its class entry in current table
            Sym_Entry *entry = current_table->lookup($$.lexeme);
            if(entry){
                entry->size = offset;
                debugFun("Class Entry found and offset updated to " + to_string(offset));
            }
            else{
                cout << "Internal Error: Class Entry not found" << endl;
                exit(0);
            }

            table_stack.pop();
            current_scope = scopes.top();
            scopes.pop();
            offset = offsets.top();
            offsets.pop();
            inclass --;
        }
        ;

    // pending 3AC
    classstart : /*used in classdef*/
        KEY_CLASS Names {
            debugFun("Class Start");

            int uid = makenode("class", "class");
            addChild(uid, $2.first);
            $$.first = uid;

            // give name of class to current table
            strcpy($$.lexeme, tree[$2.first].first.c_str());

            inclass++;
            classlist.push_back({tree[$2.first].first,current_scope});
            current_table->entry(tree[$2.first].first, "class",tree[$2.first].first , getSize("class"), offset, current_scope, yylineno, nelem);
            offset += 0;
            // it is zero because it is just in symbol table, not in any memory


            // size is only reliable in class entry in this current table
            // we need this table entry continuously later so need to give it in atts somehow
            table_stack.push(current_table);
            current_table = new SymbolTable(current_table,"class_" + tree[$2.first].first);
            list_of_tables.push_back(current_table);
            scopes.push(current_scope);
            string new_scope = "class_" + tree[$2.first].first;
            current_scope = new_scope;
            offsets.push(offset);
            int new_offset = 0;
            offset = new_offset;
            nelem = 0;
        }

    // Pending 3AC
    classarguments : /*used in classdef*/
        Names { 
            debugFun("Class Args");

            $$ = $1;
            Sym_Entry *entry = current_table->lookup($1.lexeme);    

            if(!entry){
                debugFun($1.lexeme);
                Err_Handler(tree[$1.first].first, "NameError");
            }
            else if(entry->token != "class"){
                Err_Handler(tree[$1.first].first, "NameError");
            }
            else{
                SymbolTable *class_table = current_table->findTable("class_"+entry->type);
                debugFun("Entry type: " + entry->type);

                if(class_table){
                    for(auto it : class_table->table){

                        current_table->entry(it.first, it.second.token, it.second.type, it.second.size, it.second.offset, it.second.scope, it.second.line, it.second.nargs);
                        offset += 8 ;
                        // code for 3AC here.....
                    }
                }
                else{
                    debugFun("Scope name " + current_table->scope_name);
                    Err_Handler("ClassTable Not found", "Uncaught");
                }
            }
        }
        | classarguments DELIM_COMMA Names { 
            debugFun("Class Args");

            int uid = makenode(",", "comma");
            addChild(uid, $1.first);
            addChild(uid, $3.first);
            $$.first = uid;
            $$.nelem = $1.nelem + 1;
            Sym_Entry *entry = current_table->lookup(tree[$3.first].first);

            if(!entry){
                debugFun($1.lexeme);
                Err_Handler(tree[$3.first].first, "NameError");
            }
            else if(entry->token != "class"){
                Err_Handler(tree[$3.first].first, "NameError");
            }
            else{
                SymbolTable *class_table = current_table->findTable("class_"+entry->type);
                debugFun("Entry type: " + entry->type);

                if(class_table){
                    for(auto it : class_table->table){
                        current_table->entry(it.first, it.second.token, it.second.type, it.second.size, it.second.offset, it.second.scope, it.second.line, it.second.nargs);
                        // code for 3AC here.....
                    }
                }
                else{
                    debugFun("Scope name " + current_table->scope_name);
                    Err_Handler("ClassTable Not found", "Uncaught");
                }
            }
        }
        | %empty {
            debugFun("Class Arguments");
            $$.first = -1;
            $$.nelem = 0;
        }


 
    // No 3AC code generation for this
    Names : /* Used in classarguments, classstart,  */
        IDENTIFIER { 
            $$.first = makenode($1, "name");
            strcpy($$.lexeme, $1);
        }
        | RES_ID_SELF { 
            $$.first = makenode("self", "name");
            strcpy($$.lexeme, "self");
        }
        | RES_ID_INIT { 
            $$.first = makenode("__init__", "name");
            strcpy($$.lexeme, "__init__");
        }
        | RES_ID_MAIN { 
            $$.first = makenode("main", "name");
            strcpy($$.lexeme, "main");
        }
        | RES_ID_NAME{
            $$.first = makenode("__name__", "name");
            strcpy($$.lexeme, "__name__");

            current_table->entry("__name__", "variable", "str", getSize("str"), offset, current_scope, yylineno, nelem);
        }
        ;   
%%


// Your implementation must accept input file(s) and other options as command
// line parameters. Support the options –input, –output, –help, and –verbose at a minimum. The
// purpose and usage of the parameters should be obvious

int main(int argc, char **argv){
    allquadsarray.push_back(vector<quadruple>());
    labels.push_back(make_pair("",""));
    int inputArg = 0;
    int PrintTAC = 0;
    int PrintAST = 0;
    int PrintSymbolTable = 0;
    int PrintX86 = 1;
    string TACFilename = "output.tac";
    string ASTFilename = "output.dot";
    string SymbolTableFilename = "output.csv";
    string X86Filename = "../outputs/output.s";
    FILE *fp;
    if(argc > 1){
        /* printf("File name: %s\n", argv[1]); */
        // FILE *fp = fopen(argv[1], "r");
        // if(fp){
        //     yyin = fp;
        //     yyparse();
        //     fclose(fp);
        // }
        // else{

        //     printf("Error: File not found\n");
        // }


        for(int i=1; i<argc; i++){
            if(strcmp(argv[i], "--input") == 0){
                fp = fopen(argv[++i], "r");
                inputArg = 1;
                yyin = fp;
                if(!fp){
                    cout << "Error: File not found" <<endl;
                    exit(0);
                }
            }
            else if(strcmp(argv[i], "--AST") == 0){
                PrintAST = 1;
                // getting filename
                ASTFilename = argv[++i];                
            }
            else if(strcmp(argv[i], "--TAC") == 0){
                PrintTAC = 1;
                // getting filename
                TACFilename = argv[++i];
            }
            else if(strcmp(argv[i], "--symboltable") == 0){
                PrintSymbolTable = 1;
                // getting filename
                SymbolTableFilename = argv[++i];
            }
            else if(strcmp(argv[i], "--x86") == 0){
                PrintX86 = 1;
                // getting filename
                X86Filename = argv[++i];
            }
            else if(strcmp(argv[i], "--help") == 0){
                cout << "Usage: ./parser --input <filename> --AST <filename> --TAC <filename> --symboltable <filename> --x86 <filename>" << endl;
                cout << "Options:" << endl;
                cout << "--input <filename> : Input file name" << endl;
                cout << "--AST <filename> : Output file name for AST" << endl;
                cout << "--TAC <filename> : Output file name for TAC" << endl;
                cout << "--symboltable <filename> : Output file name for Symbol Table" << endl;
                cout << "--x86 <filename> : Output file name for x86 code" << endl;
                cout << "--help : Display help" << endl;
                cout << "--verbose : Display debug information" << endl;
                exit(0);
            }
            else if(strcmp(argv[i], "--verbose") == 0){
                debug = 1;
            }
            else{
                // error
                cout << "Error: Invalid option" << endl;
                exit(0);
            }
        }
    }
    if(inputArg == 0)   {
        
         fp = fopen("input.py", "r");
         if(fp) {
                yyin = fp;
         }
         else{
            cout << "Error: File not found" <<endl;
            exit(0);
         }
    }
    yyparse();
    fclose(fp);
    cout << "Convert Success" << endl;

    if(PrintSymbolTable){
        ofstream myfile;
        myfile.open(SymbolTableFilename);
        myfile << "\tLexeme,Token,Type,Size,Offset,Scope,Line\n\n";

        myfile << "Global Scope:\n";
        current_table->print_table(&myfile);
        myfile.close();
    }

    if(PrintAST){
        writeDotFile(tree, ASTFilename);
    }

    /* call print quad*/
    
    if(PrintTAC)
    {
        print_quads(TACFilename);
    }

    gen_text();
    print_x86(X86Filename);

    return 0;
}

void yyerror(const char *message)
{
    std::cerr << "Error at line " << yylineno << ": " << message << std::endl;
    std::cerr << "Token: " << yytext << std::endl;
    if(debug) cout << "anything" << endl;
    exit(EXIT_FAILURE); // Terminate the program after encountering an error
}