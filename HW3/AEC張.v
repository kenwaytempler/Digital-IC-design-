module AEC(clk, rst, ascii_in, ready, valid, result);

// Input signal
input clk;
input rst;
input ready;
input [7:0] ascii_in;

// Output signal
output valid;
output [6:0] result;

reg [7:0] stack [15:0];

reg [7:0] inp [15:0];
// reg [3:0] items;
reg [3:0] arrpx;
reg [3:0] out1px;
reg [2:0] state;
reg [3:0] stackpx;
reg [7:0] res;
reg val;
assign result=res[6:0];
assign valid=val;

always @(posedge clk) begin
    val=1'b0;
    if(rst)begin
        state<=3'd0;
        arrpx<=4'd0;
        stackpx<=4'd0;
        out1px<=4'd0;
    end else begin
        if(state == 3'd0) begin //data input ini
            if(ready)begin
                if(ascii_in<=8'd57  && ascii_in>=8'd48)begin
                    inp[arrpx]<=ascii_in-8'd48;
                    arrpx<=arrpx+4'd1;
                end else if(ascii_in>=8'd97)begin
                    inp[arrpx]<=ascii_in-8'd87;
                    arrpx<=arrpx+4'd1;
                end
                else
                begin
                    inp[arrpx]<=ascii_in;
                    arrpx<=arrpx+4'd1;
                end
                state=3'd1;
            end
            else begin
                state=3'd0;
            end
        end
        else if(state == 3'd1)begin //data input 
            if(ascii_in==8'd61)begin
                inp[arrpx]<=ascii_in;
                arrpx<=4'd0;
                state<=state+3'd1;

            end
            else begin
                if(ascii_in<=8'd57  && ascii_in>=8'd48)begin
                    inp[arrpx]<=ascii_in-8'd48;
                    arrpx<=arrpx+4'd1;
                end else if(ascii_in>=8'd97)
                begin
                    inp[arrpx]<=ascii_in-8'd87;
                    arrpx<=arrpx+4'd1;
                end else if(inp[arrpx]<=8'd45  )begin
                    inp[arrpx]<=ascii_in;
                    arrpx<=arrpx+4'd1;
                end else begin
                    inp[arrpx]<=ascii_in;
                    arrpx<=arrpx+4'd1;
                end
            end
        end
        else if(state==3'd2)begin//postfix
            case (inp[arrpx])
                8'd40: begin   // (
                    stack[stackpx]<=inp[arrpx];
                    stackpx<=stackpx+4'd1;
                    arrpx<=arrpx+4'd1;
                end
                8'd41: begin   // ) 
                    if(stack[stackpx-4'd1]!=8'd40)begin //if top of stack is not  ( =>pop
                        inp[out1px]<=stack[stackpx-4'd1];
                        out1px<=out1px+4'd1;
                        stackpx<=stackpx-4'd1;
                    end else begin
                        arrpx=arrpx+4'd1;
                        stackpx<=stackpx-4'd1;
                    end
                end
                8'd42: begin   // *
                    if(stackpx == 4'd0)begin
                        stack[stackpx]<=inp[arrpx];
                        stackpx<=stackpx+4'd1;
                        arrpx<=arrpx+4'd1;
                    end
                    else begin
                        if(stack[stackpx-4'd1]==8'd42)begin //if top of stack is * =>pop * and push *
                            inp[out1px]<=stack[stackpx-4'd1];
                            out1px<=out1px+4'd1;
                            arrpx<=arrpx+4'd1;
                        end else begin
                            stack[stackpx]<=inp[arrpx];
                            stackpx<=stackpx+4'd1;
                            arrpx<=arrpx+4'd1;
                        end
                    end
                end
                8'd43, 8'd45:  begin   // -
                    if(stackpx == 4'd0)begin
                        stack[stackpx]<=inp[arrpx];
                        stackpx<=stackpx+4'd1;
                        arrpx<=arrpx+4'd1;
                    end
                    else begin
                        if(stack[stackpx-4'd1]==8'd42)begin //if top of stack is *  =>pop * and push +
                            inp[out1px]<=stack[stackpx-4'd1];
                            out1px<=out1px+4'd1;
                            stackpx<=stackpx-4'd1;
                        end else if(stack[stackpx-4'd1]==8'd43 ||stack[stackpx-4'd1]==8'd45)begin//if top of stack is +  or -=>pop + and push +
                            inp[out1px]<=stack[stackpx-4'd1];
                            out1px<=out1px+4'd1;
                            stackpx<=stackpx-4'd1;
                        end else begin
                            stack[stackpx]<=inp[arrpx];
                            stackpx<=stackpx+4'd1;
                            arrpx<=arrpx+4'd1;
                        end
                    end
                end
                8'd61: begin   // =
                    if(stackpx==4'd0)begin
                        state<=state+3'd1;
                        inp[out1px]<=inp[arrpx];
                        arrpx<=4'd0;
                        stackpx<=4'd0;
                    end else begin
                        inp[out1px]<=stack[stackpx-4'd1];
                        stackpx<=stackpx-4'd1;
                        out1px<=out1px+4'd1;
                    end
                    
                end
                default: begin //number
                    inp[out1px]<=inp[arrpx];
                    arrpx<=arrpx+4'd1;
                    out1px<=out1px+4'd1;
                end
            endcase
        end
        else if(state==3'd3)begin
            case (inp[arrpx])
            8'd42: begin   // *
                    stack[stackpx-4'd2]<=stack[stackpx-4'd1]*stack[stackpx-4'd2];
                    stackpx<=stackpx-4'd1;
                    arrpx<=arrpx+4'd1;
                end
                8'd43: begin   // +
                    stack[stackpx-4'd2]<=stack[stackpx-4'd1]+stack[stackpx-4'd2];
                    stackpx<=stackpx-4'd1;
                    arrpx<=arrpx+4'd1;
                end
                8'd45:  begin   // -
                    stack[stackpx-4'd2]<=stack[stackpx-4'd2]-stack[stackpx-4'd1];
                    stackpx<=stackpx-4'd1;
                    arrpx<=arrpx+4'd1;
                end
                8'd61: begin   // =
                    res<=stack[stackpx-1];
                    val<=1'b1;
                    arrpx<=4'd0;
                    out1px<=4'd0;
                    state<=3'd0;
                    stackpx<=4'd0;
                end
                default: begin //number
                    stack[stackpx]<=inp[arrpx];
                    arrpx<=arrpx+4'd1;
                    stackpx<=stackpx+4'd1;
                end
            endcase
        end
        else
        begin
            state<=3'd0;
            arrpx<=4'd0;
            stackpx<=4'd0;
            out1px<=4'd0;
        end
        
    end
end



endmodule