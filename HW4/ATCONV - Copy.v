`timescale 1ns/10ps
module  ATCONV(
	input		clk,
	input		reset,
	output	reg	busy,	
	input		ready,			
	output reg	[11:0]	iaddr,
	input signed [12:0]	idata,
	output	reg 	cwr,
	output  reg	[11:0]	caddr_wr,
	output reg 	[12:0] 	cdata_wr,
	output	reg 	crd,
	output reg	[11:0] 	caddr_rd,
	input 	[12:0] 	cdata_rd,
	output reg 	csel
	);

    integer i;
    parameter cold = 4'd0, read_img_padding = 4'd1, conv_relu = 4'd2, outl0=4'd3, re_init=4'd4, read_mem=4'd5;
    reg[3:0] state, nextstate;
    reg[3:0] counter;
    reg[12:0] buffer1 [0:8];
    reg[12:0] data_buffer0;
    reg[11:0] row, col, temp; //temp is the value of 2-dim addr to 1 dim
    always@(*)begin 
        case(state)
            cold:begin
                if(reset) nextstate=cold;
				else if(ready) nextstate=read_img_padding;
				else nextstate=cold;
            end
            read_img_padding:begin
                if(counter==4'd10) nextstate=conv_relu;
                else nextstate=read_img_padding;
            end
            conv_relu:begin
                nextstate=outl0;             
            end
            outl0:begin
                nextstate=re_init;
            end
            re_init:begin
                if(caddr_wr==12'd4095) nextstate=read_mem;
                else nextstate=read_img_padding;
            end
            read_mem:nextstate=cold;
            default: nextstate=cold;
        endcase
    end

    always@(posedge clk or posedge reset)begin
        if(reset)begin
            data_buffer0<=13'd0;
            temp<=4'd0;
            row<=12'd0;
            col<=12'd0;
            counter<=4'd0;
            state<=cold;
            nextstate<=cold;
            busy<=1'd0;
			iaddr<=12'd0;
			crd<=1'd0;
			cwr<=1'd0;
			csel<=1'd0;
			caddr_wr<=12'd0;
			cdata_wr<=13'd0;
			caddr_rd<=12'd0;
            for(i=0;i<9;i=i+1) buffer1[i]<=13'd0;
        end
        else begin
            state<=nextstate;
            case(state)
                cold:begin
                    if(ready) busy<=1'd1;
					else busy<=busy;
                end
                read_img_padding:begin
                    counter<=counter+4'd1; //buffer-addr
                    temp<=(row<<6)+col;
                    if(counter==4'd10)begin 
                        if((col==12'd63)&(row<12'd64))begin //buffer batch center mem addr
							row<=row+12'd1;
							col<=12'd2;
						end else col<=col+12'd1;
                    end else begin
                        case(counter)
                            4'd0:begin 
                                if((row<2)&(col<2)) iaddr<=12'd0; //top-left corner
                                else if((row<2)&(col>=2)) iaddr<=(row<<6)+(col-12'd2); // top side                                  
                                else if((row>=2)&(col<2)) iaddr<=((row-12'd2)<<6)+col; //buttom left side
                                else iaddr<=((row-12'd2)<<6)+(col-12'd2);
                            end
                            4'd1:begin
                                buffer1[counter-4'd1]<=idata;
                                if((row<2)) iaddr<=(row<<6)+col;  //top side                                                                   
                                else iaddr<=((row-12'd2)<<6)+col;                                                                    
                            end
                            4'd2:begin
                                buffer1[counter-4'd1]<=idata;
                                if((row<2)&(col>=62)) iaddr<=(row<<6)+col; //top-right corner  
                                else if((row<2)&(col<62)) iaddr<=(row<<6)+(col+12'd2); //top side
                                else if((row>=2)&(col>=62)) iaddr<=((row-12'd2)<<6)+col; //buttom right                                   
                                else iaddr<=((row-12'd2)<<6)+(col+12'd2);                               
                            end
                            4'd3:begin
                                buffer1[counter-4'd1]<=idata;
                                if((col<2)) iaddr<=(row<<6)+col;                                                                  
                                else iaddr<=(row<<6)+(col-12'd2);                                           
                            end
                            4'd4:begin
                                buffer1[counter-4'd1]<=idata;
                                iaddr<=(row<<6)+col;                                
                            end
                            4'd5:begin
                                buffer1[counter-4'd1]<=idata;
                                if((col>=62)) iaddr<=(row<<6)+col;                                   
                                else iaddr<=(row<<6)+(col+12'd2);                               
                            end
                            4'd6:begin
                                buffer1[counter-4'd1]<=idata;
                                if((row>=62)&(col<2)) iaddr<=(row<<6)+col;//buttom-left corner   
                                else if((row>=62)&(col>=2)) iaddr<=(row<<6)+(col-12'd2);//buttom side
                                else if((row<62)&(col<2)) iaddr<=((row+12'd2)<<6)+col;                                                                     
                                else iaddr<=((row+12'd2)<<6)+(col-12'd2);                                   
                            end
                            4'd7:begin 
                                buffer1[counter-4'd1]<=idata;
                                if((row>=62)) iaddr<=(row<<6)+col;  
                                else iaddr<=((row+12'd2)<<6)+col;                                                                   
                            end
                            4'd8:begin
                                buffer1[counter-4'd1]<=idata;
                                if((row>=62)&(col>=62)) iaddr<=(row<<6)+col;//buttom right corner          
                                else if((row>=62)&(col<62)) iaddr<=(row<<6)+(col+12'd2);//buttom side                                   
                                else if((row<62)&(col>=62)) iaddr<=((row+12'd2)<<6)+col;//right side                                   
                                else iaddr<=((row+12'd2)<<6)+(col+12'd2); 
                            end
                            4'd9:buffer1[counter-4'd1]<=idata; 
                            default:iaddr<=iaddr;
                        endcase
                    end                  
                end
                conv_relu:begin
                    counter<=4'd0;
                    data_buffer0<=(buffer1[4]-
                    (buffer1[0]>>4)-(buffer1[1]>>3)-(buffer1[2]>>4)-
                    (buffer1[3]>>2)-(buffer1[5]>>2)-
                    (buffer1[6]>>4)-(buffer1[7]>>3)-(buffer1[8]>>4)-
                    13'b0000000001100);  
                end
                outl0:begin
                    csel<=1'd0;
                    cwr<=1'd1;
                    if(data_buffer0<13'b0111111111111) cdata_wr<=data_buffer0;
                    else cdata_wr<=13'd0;    
                end
                re_init:begin
                    cwr<=1'd0;
                    caddr_wr<=caddr_wr+1'd1;
                end
                read_mem:begin
                    busy<=1'd0;
                end
            endcase
        end
    end
endmodule