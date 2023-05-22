module AEC(clk, rst, ascii_in, ready, valid, result);

// Input signal
input clk;
input rst;
input ready;
input [7:0] ascii_in;

// Output signal
output reg valid;
output reg [6:0] result;
reg [2:0] state;
reg [3:0] top;
reg [3:0] pt1;
reg [3:0] pt2;
reg [7:0] datareg [0:15];
reg [7:0] stack [0:15];

always(*)begin
    
end

always@(posedge clk, posedge rst)begin
    if(rst)begin
        top<=4'd0;
        pt1<=4'd0;
        pt2<=4'd0;
        state<=3'd0;
    end
    else begin
        if(state == 3'd0)begin
            valid<=1'd0;
            if(ready)begin
                if(ascii_in >= 8'd48 && ascii_in <= 8'd57)begin// 0 - 9
                        pt1<=pt1+4'd1;
                        datareg[pt1]<=ascii_in-8'd48;
                end
                else if(ascii_in >= 8'd97 && ascii_in <= 8'd102)begin // 10 - 15
                    pt1<=pt1+4'd1;
                    datareg[pt1]<=ascii_in-8'd87; 
                end
                else begin // + - * 
                    pt1<=pt1+4'd1;
                    datareg[pt1]<=ascii_in;
                end
                state<=state+3'd1;
            end
            else
                state<=3'd0;
        end
        else if(state == 3'd1)begin
            if(ascii_in == 8'd61)begin
                state<=state+3'd1;
                pt1<=4'd0;
                datareg[pt1]<=ascii_in;
            end
            else begin
                if(ascii_in >= 8'd48 && ascii_in <= 8'd57)begin// 0 - 9
                        pt1<=pt1+1'd1;
                        datareg[pt1]<=ascii_in-8'd48;
                end
                else if(ascii_in >= 8'd97 && ascii_in <= 8'd102)begin // 10 - 15
                    pt1<=pt1+1'd1;
                    datareg[pt1]<=ascii_in-8'd87;
                end
                else begin // + - * 
                    pt1<=pt1+1'd1;
                    datareg[pt1]<=ascii_in;
                end
            end
        end
        else if(state == 3'd2) begin
            if(datareg[pt1]==8'd40)begin // (
                top<=top+4'd1;
                pt1<=pt1+4'd1;
                stack[top]<=datareg[pt1];
            end
            else if(datareg[pt1]==8'd41)begin // )
                if(stack[top-4'd1]!=8'd40)begin
                    top<=top-4'd1;
                    pt2<=pt2+4'd1;
                    datareg[pt2]<=stack[top-4'd1];
                end
                else begin
                    top<=top-4'd1;
                    pt1<=pt1+4'd1;
                end
            end
            else if(datareg[pt1]==8'd42)begin // case *
                if(stack[top-4'd1]==8'd42)begin
                    top<=top-4'd1;
                    pt2<=pt2+4'd1;
                    datareg[pt2]<=stack[top-4'd1];
                end
                else begin
                    top<=top+4'd1;
                    pt1<=pt1+4'd1;
                    stack[top]<=datareg[pt1];
                end
            end
            else if(datareg[pt1]==8'd43)begin //case +
                if(stack[top-4'd1]==8'd42 || stack[top-4'd1]==8'd43 || stack[top-4'd1]==8'd45)begin
                    top<=top-4'd1;
                    pt2<=pt2+4'd1;
                    datareg[pt2]<=stack[top-4'd1];
                end
                else begin
                    top<=top+4'd1;
                    pt1<=pt1+4'd1;
                    stack[top]<=datareg[pt1];
                end
            end
            else if(datareg[pt1]==8'd45)begin //case -
                if(stack[top-4'd1]==8'd42 || stack[top-4'd1]==8'd43 || stack[top-4'd1]==8'd45)begin
                    top<=top-4'd1;
                    pt2<=pt2+4'd1;
                    datareg[pt2]<=stack[top-4'd1];
                end
                else begin
                    top<=top+4'd1;
                    pt1<=pt1+4'd1;
                    stack[top]<=datareg[pt1];
                end
            end
            else if(datareg[pt1]==8'd61)begin// case =
                if(top==4'd0)begin
                    state<=state+3'd1;
                    pt1<=0;
                    pt2<=0;
                    datareg[pt2]<=datareg[pt1];// reserve =
                end
                else begin
                    top<=top-4'd1;
                    pt2<=pt2+4'd1;
                    datareg[pt2]<=stack[top-4'd1];
                end
            end
            else begin //case number
                pt1<=pt1+4'd1;
                pt2<=pt2+4'd1;
                datareg[pt2]<=datareg[pt1];
            end
        end 
        else if(state==3'd3)begin
            if(datareg[pt1]==8'd42)begin //case *
                top<=top-4'd1;
                pt1<=pt1+4'd1;
                stack[top-4'd2] <= stack[top-4'd2] * stack[top-4'd1];
            end
            else if(datareg[pt1]==8'd43)begin //case +
                top<=top-4'd1;
                pt1<=pt1+4'd1;
                stack[top-4'd2] <= stack[top-4'd2] + stack[top-4'd1];
            end
            else if(datareg[pt1]==8'd45)begin //case +
                top<=top-4'd1;
                pt1<=pt1+4'd1;
                stack[top-4'd2] <= stack[top-4'd2] - stack[top-4'd1];
            end
            else if(datareg[pt1]==8'd61)begin // case =
                result<=stack[top-4'd1];
                state<=3'd0;
                valid<=1'd1;
                pt1<=4'd0;
                pt2<=4'd0;
                top<=4'd0;
            end
            else begin //case number
                top<=top+4'd1;
                pt1<=pt1+4'd1;
                stack[top]<=datareg[pt1];
            end
        end
        else begin
            state<=3'd0;
            pt1<=4'd0;
            pt2<=4'd0;
            top<=4'd0;
        end       
    end
end
endmodule