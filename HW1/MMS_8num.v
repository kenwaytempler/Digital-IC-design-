`include "MMS_4num.v"
module MMS_8num(result, select, number0, number1, number2, number3, number4,
 number5, number6, number7);

input        select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
input  [7:0] number4;
input  [7:0] number5;
input  [7:0] number6;
input  [7:0] number7;
output [7:0] result; 

/*
	Write Your Design Here ~
*/
wire [7:0] out1, out2;
MMS_4num m1(out1, select, number0, number1, number2, number3); 
MMS_4num m2(out2, select, number4, number5, number6, number7);
assign result = ((out1 < out2) ^ select) ? out2 : out1; 

endmodule