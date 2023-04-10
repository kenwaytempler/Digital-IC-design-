module MMS_4num(result, select, number0, number1, number2, number3);

input        select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
output [7:0] result; 

/*
	Write Your Design Here ~
*/
wire [7:0] temp1, temp2;  
assign temp1 = ((number0 < number1) ^ select) ? number1 : number0;
assign temp2 = ((number2 < number3) ^ select) ? number3 : number2;
assign result = ((temp1 < temp2) ^ select) ? temp2 : temp1;


endmodule