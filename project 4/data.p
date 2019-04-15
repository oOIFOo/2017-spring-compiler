//&T-
data;

// scaler type
var a,b,c : integer;
var c : boolean;
var d : string;
var r : real;

//array type
var e,ee : array 1 to 10 of integer;
var f : array 5 to 1 of array 1 to 5 of array 100 to 101 of integer;

//Constant
var g,gg : 10;
var h : "Gimme Gimme Gimme!!";
var i : true;
var j : 2.56;
var k : 111.111E-3;
var l : 0777;    // note octal

fun();
begin
c := (d > c) and (b > c);
c := 12;
a := a mod d;
c := a > b;
r := a;
d := h+h;
r := 1.2*3.4;
print r[1];
read a;

while r do
end do

for z:= 1 to 1 do
z := 1;
for z:= 2 to 1 do
end do
end do
aa := BB;
end
end fun

fun2( a,b:integer; c:string ): integer;
begin
return f[1][1][5];
end
end fun


fun3( a:array 1 to 10 of boolean ) : array 11 to 20 of real;
begin
fun();
fun(b, c, c);
fun2(b, c, c);
fun2(b, 1+2, d+h);
return r;
end
end fun3

foo(): integer;
begin
var a: array 1 to 3 of array 1 to 3 of integer;
var b: array 1 to 5 of array 1 to 3 of integer;
var i, j: integer;
a[1][1] := i; // legal
i := a[1][1] + j; // legal
a[1][1] := b[1][2]; // legal
a := b; // illegal: array arithmetic
a[1] := b[2]; // illegal: array arithmetic
return a[1][1]; // legal: `a[1][1]' is a scalar type, but `a' is an array type.
end
end foo
//&D-
begin
    var noDump: string;
end
//&D+
end error
