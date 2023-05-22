module AEC(clk, rst, ascii_in, ready, valid, result);

// Input signal
input clk;
input rst;
input ready;
input [7:0] ascii_in;
integer i=3'b000;

// Output signal
output reg valid;
output reg [6:0] result;
reg trash;
reg ptmode; //set to 1 if encounter ")", for pop looping operation
reg primode; //set to 1 if stack[top] has higher or equal priority
reg dataempty;
reg [3:0] state, nextstate;
reg [3:0] datacount; // "=" won`t be counted, phase 1 as token of infix, phase 2 as token of postfix
reg [3:0] top; //stack pointer, top == 0 means stack empty
reg [3:0] pt1; //datareg pointer
reg [3:0] pt2; //datareg pointer
reg [7:0] datareg [0:15]; // start from datareg[0]
reg [7:0] stack [0:15];


parameter cold = 4'd0, in = 4'd1, push1 = 4'd2, pop1 = 4'd3,  
         reinit = 4'd4, push2 = 4'd5, pop2 = 4'd6, finish = 4'd7, out = 4'd8;  

always@(*)begin
    case(state)
        cold:   nextstate = in;
        in:     nextstate = (ascii_in == 8'd61)? push1 : in; // stop when encounter "="
        push1: begin           
                if(dataempty)       nextstate = pop1;
                else if(ptmode)     nextstate = pop1;                   
                else if(primode)    nextstate = pop1;
                else                nextstate = push1;
            end
        pop1: begin           
                if(ptmode || primode) nextstate = pop1;                
                else if (dataempty & (top!=4'd0))   nextstate = pop1;   
                else if (dataempty & (top==4'd0))   nextstate = reinit;                    
                else if (!ptmode & !primode)  nextstate = push1;                        
                else    nextstate = cold; //default
            end
        reinit:
            nextstate = push2;
        push2: begin
            if (!(datareg[pt1] >= 8'd0 && datareg[pt1] <= 8'd15))  nextstate = pop2;
            else if(pt1 == datacount) nextstate = finish;
            else nextstate = push2;  
        end
        pop2: begin
            if(pt1 != datacount) nextstate = push2;
            else nextstate = finish;
        end
        finish:     nextstate = out;
        out:        nextstate = in; 
        default:    nextstate = cold;
    endcase
end


always@(posedge clk, posedge ready, posedge rst)begin //rst 好像沒寫滿
    if(ready | rst | clk)begin
        if(rst)begin
            state <= cold; 
            datacount <= 4'd0;
		    for(i=0;i<16;i=i+1) datareg[i] <= 8'b0;			    
		    for(i=0;i<16;i=i+1) stack[i] <= 8'b0;
            top <= 4'd0;
            pt1 <= 4'd0; 
            pt2 <= 4'd0;
            ptmode <= 1'd0;
            primode <= 1'd0; 
            dataempty <= 1'd0;
            trash <= 1'd0;
            valid <= 1'd0;
            result <= 7'd0; 
        end
        else state <= nextstate;           
        end
    else trash <= 1'd0;
        
    if(clk) begin
        case(state)
            cold:begin
                state <= cold; 
                datacount <= 4'd0;
		        for(i=0;i<16;i=i+1) datareg[i] <= 8'b0;			    
		        for(i=0;i<16;i=i+1) stack[i] <= 8'b0;
                top <= 4'd0;
                pt1 <= 4'd0; 
                pt2 <= 4'd0;
                ptmode <= 1'd0;
                primode <= 1'd0; 
                dataempty <= 1'd0;
                trash <= 1'd0;
                valid <= 1'd0;
                result <= 7'd0; 
            end
            in:begin           
                if(ascii_in != 8'd61)begin
                    datacount <= datacount + 1'd1;
                    if(ascii_in >= 8'd48 && ascii_in <= 8'd57)// 0 - 9
                        datareg[datacount] <= ascii_in - 8'd48;
                    else if (ascii_in >= 8'd97 && ascii_in <= 8'd102)// 10 - 15
                        datareg[datacount] <= ascii_in - 8'd87;
                    else if (ascii_in >= 8'd40 && ascii_in <= 8'd45)//()*+-
                        datareg[datacount] <= ascii_in - 8'd24;
                    else trash <= 1'd0;
                    // ( 16 ) 17 * 18 + 19 - 21       
                end     
            end
            push1:begin
                if(pt1 == datacount)
                    dataempty <= 1'd1;
                else if (datareg[pt1] >= 8'd0 && datareg[pt1] <= 8'd15) begin //case number 
                    pt1 <= pt1+4'd1;
                    pt2 <= pt2+4'd1;
                    datareg[pt2] <= datareg[pt1];
                end
                else if (datareg[pt1] == 8'd16) begin // case "("
                    top <= top+4'd1; //postion of next element 
                    pt1 <= pt1+4'd1; //postion of next element
                    stack[top] <= 8'd16;
                end
                else if(datareg[pt1] == 8'd17)//case ")" 
                    ptmode <= 1'd1;
                else if(datareg[pt1] == 8'd18) begin //case "*"
                    if(stack[top-4'd1] == 8'd18) 
                        primode <= 1'd1;
                    else begin
                        top <= top + 4'd1; 
                        pt1 <= pt1 + 4'd1;
                        stack[top] <= 8'd18;
                    end
                end
                else if(datareg[pt1] == 8'd19) begin //case "+"
                    if(stack[top-4'd1] == 8'd18 || stack[top-4'd1] == 8'd19 || stack[top-4'd1] == 8'd21) 
                        primode <= 1'd1;
                    else begin
                        top <= top + 4'd1; 
                        pt1 <= pt1 + 4'd1;
                        stack[top] <= 8'd19;
                    end
                end
                else if(datareg[pt1] == 8'd21) begin //case "-"
                    if(stack[top-4'd1] == 8'd18 || stack[top-4'd1] == 8'd19 || stack[top-4'd1] == 8'd21) 
                        primode <= 1'd1;
                    else begin
                        top <= top + 4'd1; 
                        pt1 <= pt1 + 4'd1;
                        stack[top] <= 8'd21;
                    end
                end
                else trash <= 1'd0;
            end
            pop1:begin
                if(ptmode) begin
                    if(stack[top-4'd1] != 8'd16) begin // case ")"
                        pt2 <= pt2+4'd1; //postion of next element
                        top <= top-4'd1;
                        datareg[pt2] <= stack[top-4'd1]; 
                    end
                    else begin //等於"(", "("捨棄
                        top <= top-4'd1;
                        pt1 <= pt1+4'd1; // discard ")"
                        ptmode <= 1'd0; // the following combinational circuit will take ptmode as 0
                    end
                end
                if(primode) begin
                    if(datareg[pt1] == 8'd18) begin //case "*"
                        if(stack[top-4'd1] == 8'd18) begin
                            pt2 <= pt2+4'd1;
                            top <= top-4'd1;
                            datareg[pt2] <= stack[top-4'd1];
                        end
                        else primode <= 1'd0;                           
                    end  
                    else if(datareg[pt1] == 8'd19 || datareg[pt1] == 8'd21) begin // case "+" "-"
                        if(stack[top-4'd1] == 8'd18 || stack[top-14'd1] == 8'd19 || stack[top-4'd1] == 8'd21) begin
                            pt2 <= pt2+4'd1;
                            top <= top-4'd1;
                            datareg[pt2] <= stack[top-4'd1];
                        end  
                        else primode <= 1'd0;  
                    end
                end
                else if(dataempty) begin // 沒input資料後把stack pop到完
                    if(top!=0) begin 
                        if(stack[top-4'd1]!=8'd16)begin
                            pt2 <= pt2+4'd1;
                            top <= top-4'd1;
                            datareg[pt2] <= stack[top-4'd1];
                        end
                        else top <= top-4'd1;       
                    end
                    else trash <= 1'd0;
                end
                else trash <= 1'd0;
            end
            reinit: begin 
                pt1 <= 4'd0;
                top <= 4'd0;
                datacount <= pt2;
                dataempty <= 1'd0;
            end
            push2: begin
                if(datareg[pt1] >= 8'd0 && datareg[pt1] <= 8'd15) begin
                    pt1 <= pt1+4'd1; //next token                
                    top <= top+4'd1;
                    stack[top] <= datareg[pt1]; 
                end
                else trash <= 1'd0;      
            end
            pop2: begin
                if(datareg[pt1] == 8'd18) begin //case * 
                    pt1 <= pt1+4'd1;              
                    top <= top-4'd1;
                    stack[top-4'd2] <= stack[top-4'd2] * stack[top-4'd1];
                end
                else if(datareg[pt1] == 8'd19) begin //case +
                    pt1 <= pt1+4'd1; 
                    top <= top-4'd1;
                    stack[top-4'd2] <= stack[top-4'd2] + stack[top-4'd1];
                end
                else if(datareg[pt1] == 8'd21) begin //case -
                    pt1 <= pt1+4'd1; 
                    top <= top-4'd1;
                    stack[top-4'd2] <= stack[top-4'd2] - stack[top-4'd1];
                end
                else trash <= 1'd0;
            end
            finish: begin
                valid <= 1'd1;
                result <= stack[0][6:0];
            end
            out: begin
                datacount <= 4'd0;
		        for(i=0;i<16;i=i+1) datareg[i] <= 8'b0;
		        for(i=0;i<16;i=i+1) stack[i] <= 8'b0;		    
                top <= 4'd0;
                pt1 <= 4'd0; 
                pt2 <= 4'd0;
                ptmode <= 1'd0;
                primode <= 1'd0; 
                dataempty <= 1'd0;
                valid <= 1'd0;
                trash <= 1'd0;
                result <= 7'd0;
            end
            default:begin
                state <= cold; 
                datacount <= 4'd0;
		        for(i=0;i<16;i=i+1) datareg[i] <= 8'b0;   
		        for(i=0;i<16;i=i+1) stack[i] <= 8'b0;		    	
                top <= 4'd0;
                pt1 <= 4'd0; 
                pt2 <= 4'd0;
                ptmode <= 1'd0;
                primode <= 1'd0; 
                dataempty <= 1'd0;
                trash <= 1'd0;
                valid <= 1'd0;
                result <= 7'd0;
            end
        endcase
    end
    else trash <= 1'd0;      
end



endmodule