module demosaic(clk, reset, in_en, data_in, wr_r, addr_r, wdata_r, rdata_r, wr_g, addr_g, wdata_g, rdata_g, wr_b, addr_b, wdata_b, rdata_b, done);
input clk;
input reset;
input in_en;
input [7:0] data_in;
output wr_r;
output [13:0] addr_r;
output [7:0] wdata_r;
input [7:0] rdata_r;
output wr_g;
output [13:0] addr_g;
output [7:0] wdata_g;
input [7:0] rdata_g;
output wr_b;
output [13:0] addr_b;
output [7:0] wdata_b;
input [7:0] rdata_b;
output done;
reg [3:0] state;
reg [7:0] row;
reg [7:0] col;
reg [3:0] nextState;
reg [13:0] imgcount;

reg wr_r;
reg wr_g;
reg wr_b;
reg done;

reg [13:0] addr_r;
reg [13:0] addr_g;
reg [13:0] addr_b;
reg [7:0] wdata_r;
reg [7:0] wdata_g;
reg [7:0] wdata_b;
reg [9:0] rn[4:0];
reg [9:0] bn[4:0];
reg [9:0] gn[8:0];
reg [9:0] temp1;
reg [9:0] temp;

reg [12:0] temp3;
reg [12:0] temp4;
initial begin
    done=1'b0;
	imgcount=14'd0;
    addr_r=14'd0;
    addr_g=14'd0;
    addr_b=14'd0;
    wdata_b=8'd0;
    wdata_g=8'd0;
    wdata_r=8'd0;
    wr_r=1'b0;
    wr_g=1'b0;
    wr_b=1'b0;
    row=8'd0;
    temp1=10'd1023;
    temp=10'd1023;
end
always @(posedge clk or posedge reset ) begin
	
	if(reset)begin
        state<=4'd0;
        row<=8'd0;
        col<=8'd0;
	end else
	begin
		state<=nextState;
		case(state)
			4'd0: begin
                if(in_en)begin
                    imgcount<=(imgcount+14'd1);
                    wr_r<=1'b1;
                    wr_b<=1'b1;
                    wr_g<=1'b1;
                    wdata_r<=data_in;
                    addr_r<=imgcount;
                    wdata_g<=data_in;
                    addr_g<=imgcount;
                    wdata_b<=data_in;
                    addr_b<=imgcount;
                    temp1<=10'd1023;
                    temp<=10'd1023;
                end else begin
                    if(row==8'b1111111||temp3==13'd4095||temp4==13'd4095)begin
                        wr_r<=1'b0;
                        wr_b<=1'b0;
                        wr_g<=1'b0;
                    end else begin
                    end


                end
            end
            4'd2: begin
                wr_r<=1'b0;
                wr_b<=1'b0;
                wr_g<=1'b0;
                imgcount<=14'd129;
                row<=8'd1;
                col<=8'd1;
                if(temp1==10'd1023) begin
                    temp1<=10'd0;
                end else begin

                end
                if(temp==10'd1023) begin
                    temp<=10'd0;
                end else begin

                end


            end

            4'd3:begin
                wr_r<=1'b0;
                wr_b<=1'b0;
                wr_g<=1'b0;
                temp1<=10'd0;
                temp<=10'd0;
                temp4<=13'd0;
                temp3<=13'd0;
                if(row[0]==1'b1 && col[0]==1'b1)begin //(a)
                            addr_r<=(imgcount-14'd128);
                            addr_b<=(imgcount-14'd1); 
                            addr_g<=(imgcount-14'd256);                 
                end else if(row[0]==1'b1 && col[0]==1'b0) begin //(b)
                            addr_b<=(imgcount-14'd256); 
                            addr_r<=(imgcount-14'd129);     
                            addr_g<=(imgcount-14'd128);              
                end else if(row[0]==1'b0 && col[0]==1'b1) begin //(c)           
                            addr_r<=(imgcount-14'd256); 
                            addr_b<=(imgcount-14'd129);     
                            addr_g<=(imgcount-14'd128);
                end else if  (row[0]==1'b0 && col[0]==1'b0)begin //(d)
                            addr_b<=(imgcount-14'd128);
                            addr_r<=(imgcount-14'd1); 
                            addr_g<=(imgcount-14'd256); 
                end
            end
            4'd4:begin
                if(row[0]==1'b1 && col[0]==1'b1)begin //(a)
                            rn[0]<=rdata_r;
                            bn[0]<=rdata_b;
                            gn[0]<=rdata_g;
                            addr_r<=(imgcount+14'd128);
                            addr_b<=(imgcount+14'd1);  
                            addr_g<=(imgcount-14'd129);              
                end else if(row[0]==1'b1 && col[0]==1'b0) begin //(b)
                            rn[0]<=rdata_r;
                            bn[0]<=rdata_b;
                            gn[0]<=rdata_g;
                            addr_b<=(imgcount-14'd2); 
                            addr_r<=(imgcount-14'd127);     
                            addr_g<=(imgcount-14'd1);             
                end else if(row[0]==1'b0 && col[0]==1'b1) begin //(c)           
                            rn[0]<=rdata_r;
                            bn[0]<=rdata_b;
                            gn[0]<=rdata_g;
                            addr_r<=(imgcount-14'd2); 
                            addr_b<=(imgcount-14'd127);     
                            addr_g<=(imgcount-14'd1); 
                end else if  (row[0]==1'b0 && col[0]==1'b0)begin //(d)
                            rn[0]<=rdata_r;
                            bn[0]<=rdata_b;
                            gn[0]<=rdata_g;
                            addr_b<=(imgcount+14'd128);
                            addr_r<=(imgcount+14'd1);  
                            addr_g<=(imgcount-14'd129); 
                end
            end
            4'd5:begin
                if(row[0]==1'b1 && col[0]==1'b1)begin //(a)
                            rn[1]<=rdata_r;
                            bn[1]<=rdata_b;
                            gn[1]<=rdata_g;
                            addr_r<=(imgcount);
                            addr_b<=(imgcount+14'd2);  
                            addr_g<=(imgcount-14'd127);               
                end else if(row[0]==1'b1 && col[0]==1'b0) begin //(b)
                            rn[1]<=rdata_r;
                            bn[1]<=rdata_b;
                            gn[1]<=rdata_g;
                            addr_b<=(imgcount); 
                            addr_r<=(imgcount+14'd127);     
                            addr_g<=(imgcount+14'd1);              
                end else if(row[0]==1'b0 && col[0]==1'b1) begin //(c)           
                            rn[1]<=rdata_r;
                            bn[1]<=rdata_b;
                            gn[1]<=rdata_g;
                            addr_r<=(imgcount); 
                            addr_b<=(imgcount+14'd127);     
                            addr_g<=(imgcount+14'd1);
                end else if  (row[0]==1'b0 && col[0]==1'b0)begin //(d)
                            rn[1]<=rdata_r;
                            bn[1]<=rdata_b;
                            gn[1]<=rdata_g;
                            addr_r<=(imgcount);
                            addr_b<=(imgcount+14'd2);  
                            addr_g<=(imgcount-14'd127); 
                end
            end
            4'd6:begin
                if(row[0]==1'b1 && col[0]==1'b1)begin //(a)
                            gn[4]<=rdata_r;
                            gn[5]<=rdata_b;
                            gn[2]<=rdata_g;
                            addr_r<=(imgcount+14'd127);
                            addr_b<=(imgcount+14'd129);  
                            addr_g<=(imgcount-14'd2);               
                end else if(row[0]==1'b1 && col[0]==1'b0) begin //(b)
                            rn[2]<=rdata_r;
                            bn[2]<=rdata_b;
                            gn[2]<=rdata_g;
                            addr_b<=(imgcount+14'd2); 
                            addr_r<=(imgcount+14'd129);     
                            addr_g<=(imgcount+14'd128);             
                end else if(row[0]==1'b0 && col[0]==1'b1) begin //(c)           
                            rn[2]<=rdata_r;
                            bn[2]<=rdata_b;
                            gn[2]<=rdata_g;
                            addr_r<=(imgcount+14'd2); 
                            addr_b<=(imgcount+14'd129);     
                            addr_g<=(imgcount+14'd128); 
                end else if  (row[0]==1'b0 && col[0]==1'b0)begin //(d)
                            gn[4]<=rdata_r;
                            gn[5]<=rdata_b;
                            gn[2]<=rdata_g;
                            addr_r<=(imgcount+14'd127);
                            addr_b<=(imgcount+14'd129);  
                            addr_g<=(imgcount-14'd2);  
                end
            end
            4'd7:begin
                if(row[0]==1'b1 && col[0]==1'b1)begin //(a)
                            gn[6]<=rdata_r;
                            gn[7]<=rdata_b;
                            gn[3]<=rdata_g; 
                            addr_g<=(imgcount+14'd256);               
                end else if(row[0]==1'b1 && col[0]==1'b0) begin //(b)
                            rn[3]<=rdata_r;
                            bn[3]<=rdata_b;
                            gn[3]<=rdata_g;
                            addr_b<=(imgcount+14'd256);               
                end else if(row[0]==1'b0 && col[0]==1'b1) begin //(c)           
                            rn[3]<=rdata_r;
                            bn[3]<=rdata_b;
                            gn[3]<=rdata_g;
                            addr_r<=(imgcount+14'd256); 
                end else if  (row[0]==1'b0 && col[0]==1'b0)begin //(d)
                            gn[6]<=rdata_r;
                            gn[7]<=rdata_b;
                            gn[3]<=rdata_g; 
                            addr_g<=(imgcount+14'd256);   
                end
            end
            4'd8:begin
                if(row[0]==1'b1 && col[0]==1'b1)begin //(a)
                            gn[8]<=rdata_g;            
                end else if(row[0]==1'b1 && col[0]==1'b0) begin //(b)
                            bn[4]<=rdata_b;            
                end else if(row[0]==1'b0 && col[0]==1'b1) begin //(c)           
                            rn[4]<=rdata_r;  
                end else if  (row[0]==1'b0 && col[0]==1'b0)begin //(d)
                            gn[8]<=rdata_g; 
                end
            end
            4'd9:begin
                if(row[0]==1'b1 && col[0]==1'b1)begin //(a)
                            if(row>1&&col>1) begin
                                temp3<=((gn[4]*13'd5)+(rn[0]*13'd4)+(rn[1]*13'd4)+(gn[3]>>1)+(gn[5]>>1)-(gn[3]+gn[1])-(gn[2]+gn[6])-(gn[7]+gn[5]));//r
                                temp4<=((gn[4]*13'd5)+(bn[0]*13'd4)+(bn[1]*13'd4)+(gn[0]>>1)+(gn[8]>>1)-(gn[0]+gn[1])-(gn[2]+gn[6])-(gn[7]+gn[8]));//b
                                temp<=(rn[0]+rn[1]);
                                temp1<=(bn[0]+bn[1]);
                            end else
                            begin
                                temp<=(rn[0]+rn[1]);
                                temp1<=(bn[0]+bn[1]);
                            end
                                
                end else if(row[0]==1'b1 && col[0]==1'b0) begin //(b)
                            if(row>1&&col<126) begin
                                temp3<=((bn[2]*13'd6)+(rn[0]*13'd2)+(rn[1]*13'd2)+(rn[3]*13'd2)+(rn[2]*13'd2)-((bn[0]+(bn[0]>>1))+(bn[1]+(bn[1]>>1)))-((bn[3]+(bn[3]>>1))+(bn[4]+(bn[4]>>1)))); //r
                                temp4<=((bn[2]*13'd4)+(gn[0]*13'd2)+(gn[1]*13'd2)+(gn[2]*13'd2)+(gn[3]*13'd2)-(bn[0]+bn[1])-(bn[3]+bn[4])); //g
                                temp<=(rn[0]+rn[1]+rn[2]+rn[3]);
                                temp1<=(gn[0]+gn[1]+gn[2]+gn[3]);
                            end else
                            begin
                                temp<=((rn[0]+rn[1])+(rn[2]+rn[3]));
                                temp1<=((gn[0]+gn[1])+(gn[2]+gn[3]));
                            end      
                end else if(row[0]==1'b0 && col[0]==1'b1) begin //(c)           
                            if(col>1&&row<126) begin
                                temp3<=((rn[2]*13'd6)+(bn[0]*13'd2)+(bn[1]*13'd2)+(bn[3]*13'd2)+(bn[2]*13'd2)-((rn[0]+(rn[0]>>1))+(rn[1]+(rn[1]>>1)))-((rn[3]+(rn[3]>>1))+(rn[4]+(rn[4]>>1)))); //b
                                temp4<=((rn[2]*13'd4)+(gn[0]*13'd2)+(gn[1]*13'd2)+(gn[2]*13'd2)+(gn[3]*13'd2)-(rn[0]+rn[1])-(rn[3]+rn[4])); //g
                                temp<=(bn[0]+bn[1]+bn[2]+bn[3]);
                                temp1<=(gn[0]+gn[1]+gn[2]+gn[3]);
                            end else
                            begin
                                temp<=((bn[0]+bn[1])+(bn[2]+bn[3]));
                                temp1<=((gn[0]+gn[1])+(gn[2]+gn[3]));
                            end
                end else if  (row[0]==1'b0 && col[0]==1'b0)begin //(d)
                            if(row<126 && col<126) begin
                                temp3<=((gn[4]*13'd5)+(rn[0]*13'd4)+(rn[1]*13'd4)+(gn[0]>>1)+((gn[8]>>1)-(gn[3]+gn[1]))-((gn[2]+gn[6])+(gn[7]+gn[5])));//r
                                temp4<=((gn[4]*13'd5)+(bn[0]*13'd4)+(bn[1]*13'd4)+(gn[3]>>1)+((gn[5]>>1)-(gn[0]+gn[1]))-((gn[2]+gn[6])+(gn[7]+gn[8])));//b
                                temp<=(rn[0]+rn[1]);
                                temp1<=(bn[0]+bn[1]);
                            end else
                            begin
                                temp<=(rn[0]+rn[1]);
                                temp1<=(bn[0]+bn[1]);
                            end   
                end
                
            end
            4'd10:begin
                if(row[0]==1'b1 && col[0]==1'b1)begin //(a)
                            wr_r<=1'b1;
                            wr_b<=1'b1;
                            addr_r<=imgcount;
                            addr_b<=imgcount;
                            if(row>1&&col>1) begin                             
                                if(temp3>2047 || temp4 >2047)begin
                                    wdata_r<=temp[8:1];
                                    wdata_b<=temp1[8:1];                             
                                    
                                end else begin
                                    wdata_r<=temp3[10:3];
                                    wdata_b<=temp4[10:3];
                                end
                                
                            end
                            else begin
                                wdata_r<=temp[8:1];
                                wdata_b<=temp1[8:1];
                            end             
                end else if(row[0]==1'b1 && col[0]==1'b0) begin //(b)
                            wr_r<=1'b1;
                            wr_g<=1'b1;
                            addr_r<=imgcount;
                            addr_g<=imgcount;
                            if(row>1&&col<126) begin
                                if(temp3>2047 || temp4 >2047)begin
                                    wdata_r<=temp[9:2];
                                    wdata_g<=temp1[9:2];                           
                                    
                                end else begin
                                    wdata_r<=temp3[10:3];
                                    wdata_g<=temp4[10:3];
                                end
                            end
                            else begin
                                wdata_r<=temp[9:2];
                                wdata_g<=temp1[9:2];
                            end  
                end else if(row[0]==1'b0 && col[0]==1'b1) begin //(c)           
                            wr_b<=1'b1;
                            wr_g<=1'b1;
                            addr_b<=imgcount;
                            addr_g<=imgcount;
                            if(col>1&&row<126) begin                             
                                if(temp3>2047 || temp4 >2047)begin
                                    wdata_b<=temp[9:2];
                                    wdata_g<=temp1[9:2];                           
                                end else begin
                                    wdata_b<=temp3[10:3];
                                    wdata_g<=temp4[10:3];
                                end
                            end
                            else begin
                                wdata_b<=temp[9:2];
                                wdata_g<=temp1[9:2];
                            end
                            
                end else if  (row[0]==1'b0 && col[0]==1'b0)begin //(d)
                            wr_r<=1'b1;
                            wr_b<=1'b1;
                            addr_r<=imgcount;
                            addr_b<=imgcount;
                            if(row<126&&col<126) begin                             
                                if(temp3>2047 || temp4 >2047)begin
                                    wdata_r<=temp[8:1];
                                    wdata_b<=temp1[8:1];                             
                                end else begin
                                    wdata_r<=temp3[10:3];
                                    wdata_b<=temp4[10:3];
                                end
                                
                            end
                            else begin
                                wdata_r<=temp[8:1];
                                wdata_b<=temp1[8:1];
                            end
                end
                if(col>8'd125)begin
                    row<=row+8'd1;
                    col<=8'd1;
                    imgcount<=(imgcount+14'd3);
                end else begin 
                    col<=col+8'd1;
                    imgcount<=(imgcount+14'd1);
                end    
            end
            4'd11:begin
                done<=1'b1;
            end
            default:begin
			
            end

		endcase
	end
end
always @(*) begin
    case(state)
		4'd0:begin
			nextState = (imgcount==14'd16383)? 4'd2: 4'd0;
		end

        4'd2:begin
            nextState = 4'd3;
        end
        4'd3:begin
            nextState = (imgcount>14'd16254)? 4'd11 : 4'd4;
        end
        4'd4:begin
            nextState = 4'd5;
        end
        4'd5:begin
            nextState = 4'd6;
        end
        4'd6:begin
            nextState =4'd7;
        end
        4'd7:begin
            nextState = 4'd8;
        end
        4'd8:begin
            nextState = 4'd9;
        end
        4'd9:begin
            nextState = 4'd10;
        end
        4'd10:begin
            nextState = 4'd3;
        end
        4'd11:begin
            nextState = 4'd11;
        end
		default:begin
			nextState=4'd0;
			
		end
	endcase
end

endmodule
