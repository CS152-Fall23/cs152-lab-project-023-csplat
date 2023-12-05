# Team Members
**Steven Truong** struo025@ucr.edu Steven-Eon

**Ivan Ao** hao003@ucr.edu fhzzzs

**Niklas Zimmermann** nzimm012@ucr.edu nzimm012

**Nolan Fuliar-Abanes** nfuli001@uc.edu Nabanes06

**Mohamed Abuelreich** mabue004@ucr.edu mohamedalr

# Compilation instructions:

Create an `input.txt` file and run the compilation script by typing `sh compile.sh` in the command line. The source code in `input.txt` gets compiled and saved into `output.txt`. The output gets executed immediately.

The compilation can also be done step-by-step by executing the following commands in the terminal:

```
flex csplat.lex
bison -v -d --file-prefix=y csplat.y
gcc -O3 lex.yy.c -o parser.elf
./parser.elf input.txt > output.txt
./mil_run output.txt
```


# C Splot (.csp): 
<table>
    <tr>
        <td><b>Integer scalar variables:</b></td>
        <td>int [variableName] (int abc)</td>
    </tr>
    <tr>
        <td><b>One-dimensional arrays of integers:</b></td> 
        <td>int [variableName][] (int abc[10])</td>
    </tr>
    <tr>
        <td><b>Assignment statements:</b></td>
        <td>“:=” (abc := 123)</td>
    </tr>
    <tr>
        <td><b>Arithmetic operators:</b></td>
        <td>“+”, “-”, “*”, “/” (a+b, a-b, a*b, a/b)</td>
    </tr>
    <tr>
        <td><b>Relational operators:</b></td>
        <td>“>”, “=”, “<”, “!=” (a > b, a = b, a < b, a != b)"</td>
    </tr>
    <tr>
        <td><b>While or Do-While loops:</b></td>
        <td>whilst(cond): <b>whilst(a > b)</b> 
        <br>
        do {stmts} whilst(cond): <b>do {abc := abc + 1} whilst(abc < 10)</b></td>
    </tr>
    <tr>
        <td><b>Break statement:</b></td>
        <td>stop</td>
    </tr>
    <tr>
        <td><b>If-then-else statements</b></td>
        <td>If: when(cond) {stmts}: when(i < 5) {i := 0}
        <br>
        Else:  else {stmts}: else {i := 6}
    </tr>
    <tr>
        <td><b>Read and write statements</b></td>
        <td>Read: read(var);
        <br>
        Write: write(var);
    </tr>
    <tr>
        <td><b>Comments</b></td>
        <td>
        Single Line: #	(#This is a comment)
        <br>
        Multi Line: @#   
        <br>
        (@# this is a multiline comment
        <br>
	    [Example Text]
        <br>
	    @#)
    </tr>
    <tr>
	    <td><b>Functions (that can take multiple scalar arguments and return a single scalar result)</b></td>
	    <td>[return Data Type] [FunctionName] ?[Arg, arg2, (...)]?
	<br>
	    Function calls: [func-name] ? [params] ?;
	    </td>
    </tr>
</table>
