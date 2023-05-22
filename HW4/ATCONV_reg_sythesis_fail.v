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
	parameter cold=4'd0, read_image=4'd1, padding_init=4'd2, padding=4'd3,	
				conv_init=4'd4, conv=4'd5, relu_init=4'd6, relu=4'd7, wr1_init=4'd8,
				wr1=4'd9;
	reg[15:0] row, col, temp;//save 2-dim address into temp
	reg[13:0] temp2;//for relu operation
	reg[12:0] counter; //for padding address
	reg[11:0] counter2; //for convenience of debug operation
	reg[12:0] layer1_reg [0:4623];
	reg[12:0] layer1_reg_2 [0:4095];
	reg[3:0] state, nextstate;
	 

	always@(*)begin 
		case(state)
			cold:begin
				if(reset) nextstate=cold;
				else if(ready) nextstate=read_image;
				else nextstate=cold;
			end
			read_image:begin
				if(counter==13'd4097) nextstate=padding_init;
				else nextstate=read_image;
			end
			padding_init: nextstate=padding;
			padding:begin
				if(counter==14'd4623) nextstate=conv_init;
				else nextstate=padding;
			end
			conv_init: nextstate=conv;
			conv:begin
				if(counter2==12'd4095) nextstate=relu_init;
				else nextstate = conv;
			end
			relu_init: nextstate=relu;
			relu:begin 
				if(counter2==12'd4095) nextstate=wr1_init;
				else nextstate = relu;
			end
			wr1_init: nextstate=wr1;
			wr1:begin
				if(caddr_wr==12'd4095) nextstate=cold;
				else nextstate=wr1;
			end
			default: nextstate=cold;
		endcase	
	end


	always@(posedge clk or negedge clk or posedge reset)begin 
		if(reset) begin
			state<=cold;
			busy<=1'd0;
			iaddr<=12'd0;
			row<=16'd2;
			col<=16'd2;
			temp<=16'd138;
			temp2<=13'd0;
			counter<=13'd0;
			counter2<=12'd0;
			crd<=1'd0;
			cwr<=1'd0;
			csel<=1'd0;
			caddr_wr<=12'd0;
			cdata_wr<=13'd0;
			caddr_rd<=12'd0;
		end
		else begin
			if(clk) state<=nextstate;
			else state<=state;
			case(state)
				cold:begin
					if(clk)begin
						if(ready) busy<=1'd1;
						else busy<=busy;
					end
					else busy<=busy;
				end
				read_image:begin
					if(clk) iaddr<=iaddr+12'd1;
					else begin
						counter <= counter+13'd1;
						temp<=(row<<6)+(row<<2)+col;		
						if((col==16'd65)&(row<16'd67))begin
							row<=row+16'd1;
							col<=16'd2;
						end
						else col<=col+16'd1;		
						layer1_reg[temp]<=idata;
					end
				end
				padding_init:begin
					if(clk)begin
						counter<=13'd0;
						row<=16'd0;
						col<=16'd0;
						temp<=16'd0;
					end
					else counter<=counter;
				end
				padding:begin
					if(clk) begin
						counter<=counter+13'd1;
						if(col==16'd67)begin
							col<=16'd0;
							row<=row+16'd1;
						end
						else col<=col+16'd1;
						if((row<2)&(col<2)) layer1_reg[counter]<=layer1_reg[138];// left-top corner
						else if((row>=66)&(col<2)) layer1_reg[counter]<=layer1_reg[4422];// left-buttom corner
						else if((row<2)&(col>=66)) layer1_reg[counter]<=layer1_reg[201];//right-top corner
						else if((row>=66)&(col>=66)) layer1_reg[counter]<=layer1_reg[4485];//right-buttom corner
						else if((row<2)&((col>=2)&(col<66))) layer1_reg[counter]<=layer1_reg[136+col];//top side
						else if((row>=66)&((col>=2)&(col<66))) layer1_reg[counter]<=layer1_reg[4420+col];//buttom side
						else if(((row>=2)&(row<66))&(col<2)) layer1_reg[counter]<=layer1_reg[(row<<6)+(row<<2)+2];//left side
						else if(((row>=2)&(row<66))&(col>=66)) layer1_reg[counter]<=layer1_reg[(row<<6)+(row<<2)+65];//right side
						else state<=state;
					end
					else counter<=counter;
				end
				conv_init:begin
					if(clk)begin
						row<=16'd2;
						col<=16'd2;
					end
					else counter<=counter;
				end
				conv:begin
					if(clk)begin
						counter2<=counter2+12'd1;
						temp<=(row<<6)+(row<<2)+col;		
						if((col==16'd65)&(row<16'd67))begin
							row<=row+16'd1;
							col<=16'd2;
						end
						else col<=col+16'd1;
						layer1_reg_2[counter2]<=(
						layer1_reg[(row<<6)+(row<<2)+col]-//middle
						(layer1_reg[((row-16'd2)<<6)+((row-16'd2)<<2)+(col-16'd2)]>>4)-//[0 0]
						(layer1_reg[((row-16'd2)<<6)+((row-16'd2)<<2)+(col)]>>3)-//[0 1]
						(layer1_reg[((row-16'd2)<<6)+((row-16'd2)<<2)+(col+16'd2)]>>4)-//[0 2]
						(layer1_reg[((row)<<6)+((row)<<2)+(col-16'd2)]>>2)-//[1 0]
						(layer1_reg[((row)<<6)+((row)<<2)+(col+16'd2)]>>2)-//[1 2]
						(layer1_reg[((row+16'd2)<<6)+((row+16'd2)<<2)+(col-16'd2)]>>4)-//[2 0]
						(layer1_reg[((row+16'd2)<<6)+((row+16'd2)<<2)+(col)]>>3)-//[2 1]
						(layer1_reg[((row+16'd2)<<6)+((row+16'd2)<<2)+(col+16'd2)]>>4)-//[2 2]
						13'b0000000001100
						);
					end
					else counter<=counter;
				end
				relu_init:begin
					if(clk)
						counter2<=12'd0;
					else counter<=counter;
				end
				relu:begin
					if(clk)begin
						counter2<=counter2+12'd1;
						if(layer1_reg_2[counter2]<13'b0111111111111) layer1_reg_2[counter2]<=layer1_reg_2[counter2];
						else layer1_reg_2[counter2]<=13'd0;							
					end
					else counter<=counter;
				end
				wr1_init:begin
					if(clk) cwr<=1'd1;
					else counter<=counter;
				end
				wr1:begin
					if(clk) begin
						caddr_wr<=caddr_wr+12'd1;
						cdata_wr<=layer1_reg_2[caddr_wr];
					end
					else counter<=counter;
				end
				default:;
			endcase
		end
	end



endmodule