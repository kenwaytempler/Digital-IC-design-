module demosaic(clk, reset, in_en, data_in, wr_r, addr_r, wdata_r, rdata_r, wr_g, addr_g, wdata_g, rdata_g, wr_b, addr_b, wdata_b, rdata_b, done);
input clk;
input reset;
input in_en;
input [7:0] data_in;
output reg wr_r;
output reg [13:0] addr_r;
output reg [7:0] wdata_r;
input [7:0] rdata_r;
output reg wr_g;
output reg [13:0] addr_g;
output reg [7:0] wdata_g;
input [7:0] rdata_g;
output reg wr_b;
output reg [13:0] addr_b;
output reg [7:0] wdata_b;
input [7:0] rdata_b;
output reg done;


integer i;
parameter readdata=4'd0, readcolor=4'd1, compute=4'd2, finish=4'd3, terminate=4'd4;
reg[12:0] rp [0:4];
reg[12:0] bp [0:4];
reg[12:0] gp [0:8];
reg[12:0] tempb, tempr, tempg;
reg[3:0] state, nextstate;
reg[13:0] center;
reg[2:0] counter;


always@(*)begin
    case(state)
        readdata: nextstate=(center==14'd16383)? readcolor:readdata;
        readcolor: nextstate=(counter==3'd5)? compute:readcolor;
        compute: nextstate=(counter==3'd2)? finish:compute;
        finish: nextstate=(center==14'b11111011111101)?terminate:readcolor;
        terminate: nextstate=terminate;
        default: nextstate=readdata;
    endcase
end

always@(posedge clk or posedge reset)begin
    if(reset)begin
        wr_r<=1'd1;
        wr_g<=1'd1;
        wr_b<=1'd1;
        addr_r<=14'd0;
        addr_g<=14'd0;
        addr_b<=14'd0;
        wdata_r<=8'd0;
        wdata_g<=8'd0;
        wdata_b<=8'd0;
        done<=1'd0;
          
        for(i=0;i<5;i=i+1) begin
            bp[i]<=13'd0;
            rp[i]<=13'd0;
        end 
        for(i=0;i<9;i=i+1) gp[i]<=13'd0;
        center<=14'd0;
        state<=4'd0;
        counter<=3'd0;
        tempb<=12'd0;
        tempr<=12'd0;
        tempg<=12'd0;
    end
    else begin
        state<=nextstate;
        case(state)
            readdata:begin
                if (nextstate == readcolor)begin
                    wr_b<=1'd0; wr_r<=1'd0; wr_g<=1'd0;
                    center<=14'b00000100000010;
                end
                else center <= center + 14'd1;
                addr_b<=center;
                addr_r<=center;
                addr_g<=center;
                wdata_b<=data_in;
                wdata_r<=data_in;
                wdata_g<=data_in;
            end
            readcolor:begin 
                counter<=counter+3'd1;
                if((~center[0])&(~center[7]))begin //case g1
                    case(counter)
                        3'd0:begin
                            addr_b[13:7]<=center[13:7]-7'd1; addr_b[6:0]<=center[6:0];
                            addr_r[13:7]<=center[13:7];      addr_r[6:0]<=center[6:0]-7'd1;
                            addr_g[13:7]<=center[13:7]-7'd2; addr_g[6:0]<=center[6:0];
                        end
                        3'd1:begin
                            addr_b[13:7]<=center[13:7]+7'd1; addr_b[6:0]<=center[6:0];
                            addr_r[13:7]<=center[13:7];      addr_r[6:0]<=center[6:0]+7'd1;
                            addr_g[13:7]<=center[13:7]-7'd1; addr_g[6:0]<=center[6:0]-7'd1;
                            bp[0]<=rdata_b;
                            rp[0]<=rdata_r;
                            gp[0]<=rdata_g;
                        end
                        3'd2:begin
                            addr_b[13:7]<=center[13:7]-7'd1; addr_b[6:0]<=center[6:0]+7'd1;
                            addr_r[13:7]<=center[13:7];      addr_r[6:0]<=center[6:0]-7'd2;
                            addr_g[13:7]<=center[13:7];      addr_g[6:0]<=center[6:0]+7'd2;
                            bp[1]<=rdata_b;
                            rp[1]<=rdata_r;
                            gp[1]<=rdata_g;
                        end
                        3'd3:begin
                            addr_b[13:7]<=center[13:7]+7'd1; addr_b[6:0]<=center[6:0]-7'd1;
                            addr_r[13:7]<=center[13:7]+7'd1; addr_r[6:0]<=center[6:0]+7'd1;
                            addr_g[13:7]<=center[13:7]+7'd2; addr_g[6:0]<=center[6:0];
                            gp[2]<=rdata_b;
                            gp[3]<=rdata_r;
                            gp[4]<=rdata_g;
                        end
                        3'd4:begin
                            addr_g<=center;
                            gp[5]<=rdata_b;
                            gp[6]<=rdata_r;
                            gp[7]<=rdata_g;
                        end
                        3'd5:begin
                            counter<=3'd0;
                            gp[8]<=rdata_g;
                        end
                        default: counter<=counter;
                    endcase
                end
                else if((center[0])&(center[7]))begin //case g2
                    case(counter)
                        3'd0:begin
                            addr_b[13:7]<=center[13:7];      addr_b[6:0]<=center[6:0]-7'd1;
                            addr_r[13:7]<=center[13:7]-7'd1; addr_r[6:0]<=center[6:0];
                            addr_g[13:7]<=center[13:7]-7'd2; addr_g[6:0]<=center[6:0];
                        end
                        3'd1:begin
                            addr_b[13:7]<=center[13:7];      addr_b[6:0]<=center[6:0]+7'd1;                           
                            addr_r[13:7]<=center[13:7]+7'd1; addr_r[6:0]<=center[6:0];
                            addr_g[13:7]<=center[13:7]-7'd1; addr_g[6:0]<=center[6:0]-7'd1;
                            bp[0]<=rdata_b;
                            rp[0]<=rdata_r;
                            gp[0]<=rdata_g;
                        end
                        3'd2:begin
                            addr_b[13:7]<=center[13:7]-7'd1; addr_b[6:0]<=center[6:0]+7'd1;
                            addr_r[13:7]<=center[13:7];      addr_r[6:0]<=center[6:0]-7'd2;
                            addr_g[13:7]<=center[13:7];      addr_g[6:0]<=center[6:0]+7'd2;
                            bp[1]<=rdata_b;
                            rp[1]<=rdata_r;
                            gp[1]<=rdata_g;
                        end
                        3'd3:begin
                            addr_b[13:7]<=center[13:7]+7'd1; addr_b[6:0]<=center[6:0]-7'd1;
                            addr_r[13:7]<=center[13:7]+7'd1; addr_r[6:0]<=center[6:0]+7'd1;
                            addr_g[13:7]<=center[13:7]+7'd2; addr_g[6:0]<=center[6:0];
                            gp[2]<=rdata_b;
                            gp[3]<=rdata_r;
                            gp[4]<=rdata_g;
                        end
                        3'd4:begin
                            addr_g<=center;
                            gp[5]<=rdata_b;
                            gp[6]<=rdata_r;
                            gp[7]<=rdata_g;
                        end
                        3'd5:begin
                            counter<=3'd0;
                            gp[8]<=rdata_g;
                        end
                        default: counter<=counter;
                    endcase
                end
                else if((center[0])&(~center[7])) begin //case r 
                    case(counter)
                        3'd0:begin
                            addr_b[13:7]<=center[13:7]-7'd1; addr_b[6:0]<=center[6:0]-7'd1;
                            addr_r[13:7]<=center[13:7]-7'd2; addr_r[6:0]<=center[6:0];
                            addr_g[13:7]<=center[13:7]-7'd1; addr_g[6:0]<=center[6:0];
                        end
                        3'd1:begin
                            addr_b[13:7]<=center[13:7]-7'd1; addr_b[6:0]<=center[6:0]+7'd1;                           
                            addr_r[13:7]<=center[13:7];      addr_r[6:0]<=center[6:0]-7'd2;
                            addr_g[13:7]<=center[13:7];      addr_g[6:0]<=center[6:0]-7'd1;
                            bp[0]<=rdata_b;
                            rp[0]<=rdata_r;
                            gp[0]<=rdata_g;
                        end
                        3'd2:begin
                            addr_b[13:7]<=center[13:7]+7'd1; addr_b[6:0]<=center[6:0]-7'd1;
                            addr_r[13:7]<=center[13:7];      addr_r[6:0]<=center[6:0]+7'd2;
                            addr_g[13:7]<=center[13:7];      addr_g[6:0]<=center[6:0]+7'd1;
                            bp[1]<=rdata_b;
                            rp[1]<=rdata_r;
                            gp[1]<=rdata_g;
                        end
                        3'd3:begin
                            addr_b[13:7]<=center[13:7]+7'd1; addr_b[6:0]<=center[6:0]+7'd1;
                            addr_r[13:7]<=center[13:7]+7'd2; addr_r[6:0]<=center[6:0];
                            addr_g[13:7]<=center[13:7]+7'd1; addr_g[6:0]<=center[6:0];
                            bp[2]<=rdata_b;
                            rp[2]<=rdata_r;
                            gp[2]<=rdata_g;
                        end
                        3'd4:begin
                            addr_r<=center;
                            bp[3]<=rdata_b;
                            rp[3]<=rdata_r;
                            gp[3]<=rdata_g;
                        end
                        3'd5:begin
                            counter<=3'd0;
                            rp[4]<=rdata_r;
                        end
                        default: counter<=counter;
                    endcase
                end
                else begin //case b
                    case(counter)
                        3'd0:begin
                            addr_r[13:7]<=center[13:7]-7'd1; addr_r[6:0]<=center[6:0]-7'd1;
                            addr_b[13:7]<=center[13:7]-7'd2; addr_b[6:0]<=center[6:0];
                            addr_g[13:7]<=center[13:7]-7'd1; addr_g[6:0]<=center[6:0];
                        end
                        3'd1:begin
                            addr_r[13:7]<=center[13:7]-7'd1; addr_r[6:0]<=center[6:0]+7'd1;                           
                            addr_b[13:7]<=center[13:7];      addr_b[6:0]<=center[6:0]-7'd2;
                            addr_g[13:7]<=center[13:7];      addr_g[6:0]<=center[6:0]-7'd1;
                            bp[0]<=rdata_b;
                            rp[0]<=rdata_r;
                            gp[0]<=rdata_g;
                        end
                        3'd2:begin
                            addr_r[13:7]<=center[13:7]+7'd1; addr_r[6:0]<=center[6:0]-7'd1;
                            addr_b[13:7]<=center[13:7];      addr_b[6:0]<=center[6:0]+7'd2;
                            addr_g[13:7]<=center[13:7];      addr_g[6:0]<=center[6:0]+7'd1;
                            bp[1]<=rdata_b;
                            rp[1]<=rdata_r;
                            gp[1]<=rdata_g;
                        end
                        3'd3:begin
                            addr_r[13:7]<=center[13:7]+7'd1; addr_r[6:0]<=center[6:0]+7'd1;
                            addr_b[13:7]<=center[13:7]+7'd2; addr_b[6:0]<=center[6:0];
                            addr_g[13:7]<=center[13:7]+7'd1; addr_g[6:0]<=center[6:0];
                            bp[2]<=rdata_b;
                            rp[2]<=rdata_r;
                            gp[2]<=rdata_g;
                        end
                        3'd4:begin
                            addr_b<=center;
                            bp[3]<=rdata_b;
                            rp[3]<=rdata_r;
                            gp[3]<=rdata_g;
                        end
                        3'd5:begin
                            counter<=3'd0;
                            bp[4]<=rdata_b;
                        end
                        default: counter<=counter;
                    endcase
                end
            end
            compute:begin
                counter<=counter+3'd1;
                if((~center[0])&(~center[7]))begin //case g1
                    if(counter==3'd0)begin
                        tempr<=((gp[8]<<2)+gp[8])+(gp[0]>>1)+(gp[7]>>1)+
                            (rp[0]<<2)+(rp[0]<<2)-
                            gp[1]-gp[2]-gp[3]-gp[4]-gp[5]-gp[6];
                        
                        tempb<=((gp[8]<<2)+gp[8])+(gp[3]>>1)+(gp[4]>>1)+
                            (bp[0]<<2)+(bp[1]<<2)-
                            gp[0]-gp[1]-gp[2]-gp[5]-gp[6]-gp[7];
                    end 
                    else if(counter==3'd1) begin
                        wr_b<=1'd1; wr_r<=1'd1; addr_b<=center; addr_r<=center;
                        if((tempr[12]==1'd1) || (tempr[11]==1'd1)) wdata_r<=((rp[0]+rp[1])>>1); //switch to baseline method
                        else wdata_r<=(tempr>>3);
                        if((tempb[12]==1'd1) || (tempb[11]==1'd1)) wdata_b<=((bp[0]+bp[1])>>1);
                        else wdata_b<=(tempb>>3);    
                        // if(tempr[13]==1'd1) wdata_r<=((rp[0]+rp[1])>>1); //switch to baseline method
                        // else wdata_r<=((rp[0]+rp[1])>>1);
                        // if(tempb[13]==1'd1) wdata_b<=((bp[0]+bp[1])>>1);
                        // else wdata_b<=((bp[0]+bp[1])>>1);    
                    end
                    else begin
                        counter<=3'd0;
                        wr_b<=1'd0; wr_r<=1'd0;
                    end
                end
                else if((center[0])&(center[7]))begin//case g2
                    if(counter==3'd0)begin                      
                        tempr<=((gp[8]<<2)+gp[8])+(gp[3]>>1)+(gp[4]>>1)+
                            (rp[0]<<2)+(rp[1]<<2)-
                            gp[0]-gp[1]-gp[2]-gp[5]-gp[6]-gp[7];

                        tempb<=((gp[8]<<2)+gp[8])+(gp[0]>>1)+(gp[7]>>1)+
                            (bp[0]<<2)+(bp[0]<<2)-
                            gp[1]-gp[2]-gp[3]-gp[4]-gp[5]-gp[6];
                    end 
                    else if(counter==3'd1) begin
                        wr_b<=1'd1; wr_r<=1'd1; addr_b<=center; addr_r<=center;
                        if((tempr[12]==1'd1) || (tempr[11]==1'd1)) wdata_r<=((rp[0]+rp[1])>>1); 
                        else wdata_r<=(tempr>>3);
                        if((tempb[12]==1'd1) || (tempb[11]==1'd1)) wdata_b<=((bp[0]+bp[1])>>1); 
                        else wdata_b<=(tempb>>3);
                        // if(tempr[13]==1'd1) wdata_r<=((rp[0]+rp[1])>>1); 
                        // else wdata_r<=((rp[0]+rp[1])>>1);
                        // if(tempb[13]==1'd1) wdata_b<=((bp[0]+bp[1])>>1); 
                        // else wdata_b<=((bp[0]+bp[1])>>1);        
                    end
                    else begin
                        counter<=3'd0;
                        wr_b<=1'd0; wr_r<=1'd0;
                    end
                end
                else if((center[0])&(~center[7]))begin //case r
                    if(counter==3'd0)begin
                        tempg<=(rp[4]<<2)+(gp[0]<<1)+(gp[1]<<1)+(gp[2]<<1)+(gp[3]<<1)-
                            rp[0]-rp[1]-rp[2]-rp[3];
                        tempb<=((rp[4]<<2)+(rp[4]<<1))+(bp[0]<<1)+(bp[1]<<1)+(bp[2]<<1)+(bp[3]<<1)-
                            ((rp[0]>>1)+rp[0])-((rp[1]>>1)+rp[1])-((rp[2]>>1)+rp[2])-((rp[3]>>1)+rp[3]);
                    end
                    else if(counter==3'd1)begin
                        wr_g<=1'd1; wr_b<=1'd1;  addr_g<=center; addr_b<=center;
                        if((tempg[12]==1'd1) || (tempg[11]==1'd1)) wdata_g<=((gp[0]+gp[1]+gp[2]+gp[3])>>2); 
                        else wdata_g<=(tempg>>3);
                        if((tempb[12]==1'd1) || (tempg[11]==1'd1)) wdata_b<=((bp[0]+bp[1]+bp[2]+bp[3])>>2); 
                        else wdata_b<=(tempb>>3); 
                        // if(tempg[13]==1'd1) wdata_g<=((gp[0]+gp[1]+gp[2]+gp[3])>>2); 
                        // else wdata_g<=((gp[0]+gp[1]+gp[2]+gp[3])>>2);
                        // if(tempb[13]==1'd1) wdata_b<=((bp[0]+bp[1]+bp[2]+bp[3])>>2); 
                        // else wdata_b<=((bp[0]+bp[1]+bp[2]+bp[3])>>2);       
                    end
                    else begin
                        counter<=3'd0;
                        wr_g<=1'd0; wr_b<=1'd0;
                    end
                end
                else begin //case b
                    if(counter==3'd0)begin
                        tempg<=(bp[4]<<2)+(gp[0]<<1)+(gp[1]<<1)+(gp[2]<<1)+(gp[3]<<1)-
                            bp[0]-bp[1]-bp[2]-bp[3];
                        tempr<=((bp[4]<<2)+(bp[4]<<1))+(rp[0]<<1)+(rp[1]<<1)+(rp[2]<<1)+(rp[3]<<1)-
                            ((bp[0]>>1)+bp[0])-((bp[1]>>1)+bp[1])-((bp[2]>>1)+bp[2])-((bp[3]>>1)+bp[3]);
                    end
                    else if(counter==3'd1)begin
                        wr_g<=1'd1; wr_r<=1'd1; addr_g<=center; addr_r<=center;
                        if((tempg[12]==1'd1) || (tempg[11]==1'd1)) wdata_g<=((gp[0]+gp[1]+gp[2]+gp[3])>>2); 
                        else wdata_g<=(tempg>>3);
                        if((tempr[12]==1'd1) || (tempr[11]==1'd1)) wdata_r<=((rp[0]+rp[1]+rp[2]+rp[3])>>2); 
                        else wdata_r<=(tempr>>3);    
                        // if(tempg[13]==1'd1) wdata_g<=((gp[0]+gp[1]+gp[2]+gp[3])>>2); 
                        // else wdata_g<=((gp[0]+gp[1]+gp[2]+gp[3])>>2);
                        // if(tempr[13]==1'd1) wdata_r<=((rp[0]+rp[1]+rp[2]+rp[3])>>2); 
                        // else wdata_r<=((rp[0]+rp[1]+rp[2]+rp[3])>>2);    
                    end
                    else begin
                        counter<=3'd0;
                        wr_g<=1'd0; wr_r<=1'd0;
                    end
                end
            end
            finish:begin
                if(center[6:0]==7'd125) center<=center+7'd5;
                else center<=center+7'd1;
            end
            terminate: done<=1'd1;
        endcase
    end
end
endmodule
