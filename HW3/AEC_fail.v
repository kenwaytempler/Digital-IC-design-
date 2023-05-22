module AEC(clk, rst, ascii_in, ready, valid, result);

// Input signal
input clk;
input rst;
input ready;
input [7:0] ascii_in;

// Output signal
output reg valid;
output reg [6:0] result;

parameter cold = 3'd0, in = 3'd1, push = 3'd2, pop = 3'd3,  
         reinit = 3'd4, reinit2 = 3'd7, fin = 3'd5, out = 3'd6;  
integer i=3'b000;
reg mode;
reg ptmode; //set to 1 if encounter ")", for pop looping operation
reg primode; //set to 1 if stack[top] has higher or equal priority
reg dataempty;
reg [2:0] state, nextstate;
reg [3:0] datacount; // "=" won`t be counted, phase 1 as token of infix, phase 2 as token of postfix
reg [3:0] top; //stack pointer, top == 0 means stack empty
reg [3:0] pt1; //datareg pointer
reg [3:0] pt2; //datareg pointer
reg [4:0] datareg [0:15]; // start from datareg[0]
reg [4:0] stack [0:15];

always@(*)begin
    case(state)
        cold:   nextstate <= in;
        in:     nextstate <= (ascii_in == 6'd61)? push : in; // stop when encounter "="
        push: begin
            if(!mode)begin
                if(dataempty)       nextstate <= pop;
                else if(ptmode)     nextstate <= pop;                   
                else if(primode)    nextstate <= pop;
                else                nextstate <= push;
            end
            else begin
                if (!(datareg[pt1] >= 5'd0 && datareg[pt1] <= 5'd15))  nextstate = pop;   
                else nextstate <= push; //default   
            end
        end
        pop: begin
            if(!mode)begin
                if(ptmode || primode) nextstate <= pop;                
                else if (dataempty & (top!=0))   nextstate <= pop;   
                else if (dataempty & (top==0))    nextstate <= reinit;                    
                else if (!ptmode & !primode)  nextstate <= push;                        
                else    nextstate <= cold; //default
            end
            else begin
                if( pt1 != datacount - 1 )  nextstate <= push;
                else    nextstate <= fin;   
            end   
        end
        reinit: nextstate <= reinit2;
        reinit2 : nextstate <= push;
        fin: nextstate <= out;
        out: nextstate <= in;
   
    endcase
end

always@(posedge clk, posedge rst, posedge ready)begin
    if(rst)begin
        state <= cold; datacount <= 0;
		for(i=0;i<16;i=i+1) 
			datareg[i] <= 4'b0;
		for(i=0;i<16;i=i+1)
			stack[i] <= 4'b0;
        i <= 0; top <= 0;
        pt1 = 0; pt2 <= 0;
        mode <= 0; ptmode <= 0;
        primode <= 0; dataempty <= 0;
    end
    else
        state <= nextstate;
end

always@(posedge clk, posedge ready)begin
    case(state)
        cold:;
        in: begin
            if(ascii_in != 8'd61)begin
                datacount <= datacount + 1;
                if(ascii_in >= 8'd48 && ascii_in <= 8'd57)// 0 - 9
                    datareg[datacount] <= ascii_in - 8'd48;
                else if (ascii_in >= 8'd97 && ascii_in <= 8'd102)// 10 - 15
                    datareg[datacount] <= ascii_in - 8'd87;
                else if (ascii_in >= 8'd40 && ascii_in <= 8'd45)//()*+-
                    datareg[datacount] <= ascii_in - 8'd24;
                // ( 16 ) 17 * 18 + 19 - 21       
            end
            else;
        end
        push:begin  
            if(!mode)begin // phase 1
                if(pt1 == datacount) 
                    dataempty <= 1;
                else if(datareg[pt1] >= 5'd0 && datareg[pt1] <= 5'd15)begin//case number 
                    datareg[pt2] <= datareg[pt1]; pt2 <= pt2 + 1; pt1 <= pt1+1;
                end
                else if(datareg[pt1] == 5'd16) begin//case "("
                    top <= top + 1; stack[top] <= 5'd16; pt1 <= pt1+1;
                end
                else if(datareg[pt1] == 5'd17) begin//case ")" 
                    ptmode <= 1; pt1 <= pt1+1;
                end
                else if(datareg[pt1] == 5'd18)begin// case "*"
                    if(stack[top-1] == 5'd18)
                        primode <= 1;
                    else begin
                        top <= top + 1; stack[top] <= 5'd18; pt1 <= pt1+1;
                    end
                end
                else if(datareg[pt1] == 5'd19)begin// case "+"
                    if(stack[top-1] == 5'd21 | stack[top-1] == 5'd18) // stack[top] has higher or equal priority
                        primode <= 1;
                    else begin// case "(" or empty
                        top <= top + 1; stack[top] <= 5'd19; pt1 <= pt1+1;
                    end
                end
                else if(datareg[pt1] == 5'd21)begin // case "-"
                     if(stack[top-1] == 5'd19 | stack[top-1] == 5'd18) // stack[top] has higher or equal priority
                        primode <= 1;
                    else begin // case "(" or empty
                        top <= top + 1; stack[top] <= 5'd21; pt1 <= pt1+1;
                    end
                end
                else;
                
            end
            else begin
                if(datareg[pt1] >= 5'd0 && datareg[pt1] <= 5'd15) begin
                    top <= top + 1; stack[top] <= datareg[pt1]; pt1 <= pt1+1;
                end
                else; 
            end      
        end
        pop: begin
            if(!mode)begin // phase1
                if(ptmode)begin
                    if(stack[top-1] != 5'd16)begin //pop until "("
                        datareg[pt2] <= stack[top-1]; pt2 <= pt2+1; top <= top-1;
                    end
                    else begin
                        ptmode <= 0; top <= top - 1; //等於"(", "("捨棄
                    end
                end
                else if(primode)begin //
                    if(datareg[pt1-1] == 5'd18) begin //case *
                        if(stack[top-1] == 5'd18) begin
                            datareg[pt2] <= stack[top-1]; pt2 <= pt2+1; top <= top-1;
                        end
                        else
                            primode <=0;
                    end
                    else if (datareg[pt1-1] == 5'd19 || datareg[pt1-1] == 5'd21)begin //case "+" "-"
                        if(stack[top-1] == 5'd19 || stack[top-1] == 5'd21) begin
                            datareg[pt2] <= stack[top]; pt2 <= pt2+1; top <= top-1;
                        end
                        else 
                            primode <= 0;
                    end
                end
                else begin // 沒input資料後把stack pop到完
                    if(top!=0) begin 
                        datareg[pt2] <= stack[top-1]; pt2 <= pt2+1; top <= top-1;
                    end
                    else;
                end      
            end
            else begin
                if(datareg[pt1] == 5'd18) begin //case *
                    stack[top-2] <= stack[top-1] * stack[top-2]; top <= top - 1;
                end
                else if(datareg[pt1] == 5'd19) begin //case +
                    stack[top-2] <= stack[top-1] + stack[top-2]; top <= top - 1;
                end
                else if(datareg[pt1] == 5'd21) begin //case -
                    stack[top-2] <= stack[top-1] - stack[top-2]; top <= top - 1;  
                end   
            end
        end
        reinit:begin
            mode <= 1; top <= 0; pt1 <= 0; datacount <= pt2; dataempty <= 0;
        end
        reinit2:;
        fin:begin
            valid <= 1; result <= stack[0];
        end
        out:begin
            state <= cold; datacount <= 0;
		    for(i=0;i<16;i=i+1) 
			    datareg[i] <= 4'b0;
		    for(i=0;i<16;i=i+1)
			    stack[i] <= 4'b0;
            i <= 0; top <= 0;
            pt1 <= 0; pt2 <= 0;
            mode <= 0; ptmode <= 0;
            primode <= 0; dataempty <= 0;
            valid <= 0;
        end 
    endcase
end
endmodule