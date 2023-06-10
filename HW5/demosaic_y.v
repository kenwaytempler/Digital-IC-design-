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
parameter A=5'd0,B=5'd1,C=5'd2,D=5'd3,E=5'd4,F=5'd5,G=5'd6,H=5'd7,I=5'd8;
reg [4:0] state,next_state;

reg [13:0] center; // Coordinate (row, column) = (center[13:7], center[6:0])
reg [3:0] counter;

reg [9:0] sum_r;
reg [9:0] sum_g;
reg [9:0] sum_b;

always@(posedge clk,posedge reset)
	if(reset) state <= A;
	else state <= next_state;

always@(*)
    case(state)
        A:next_state = (center == 14'd16383)? B : A;
        B:next_state = (counter == 4'd9)? C : B;
        C:next_state = (center >= 14'd16254)? D : B;
        D:next_state = E;
        E:next_state = E;
        default:next_state = A;
    endcase

always @(posedge clk,posedge reset)
	if(reset)begin
        wr_r <= 1'd1;
        wr_g <= 1'd1;
        wr_b <= 1'd1;
        addr_r <= 14'd0;
        addr_g <= 14'd0;
        addr_b <= 14'd0;
        wdata_r <= 8'd0;
        wdata_g <= 8'd0;
        wdata_b <= 8'd0;
        done <= 1'd0;

        center <= 14'd0;
        counter <= 4'd0;
        
        sum_r <= 10'd0;
        sum_g <= 10'd0;
        sum_b <= 10'd0;
	end
	else
		case (state)
            A:begin
                wdata_r <= center[0]&~center[7]   ? data_in : 8'd0;//red
                wdata_g <= ~(center[0]^center[7]) ? data_in : 8'd0;//green
                wdata_b <= ~center[0]&center[7]   ? data_in : 8'd0;//blue

                addr_r <= center;
                addr_g <= center;
                addr_b <= center;

                if(next_state == B)begin
                    center <= 14'b00000010000001;
                end
                else begin
                    center <= center + 1'd1;
                end
            end
            B:begin
                wr_r <= 1'd0;
                wr_g <= 1'd0;
                wr_b <= 1'd0;

                if(center[0]&~center[7])begin
                    //red
                    case (counter)
                        1,3,7,9: sum_b <= sum_b + rdata_b;
                        2,4,6,8: sum_g <= sum_g + rdata_g;
                        default: sum_r <= sum_r;
                    endcase
                end
                else if(~center[0]&center[7])begin
                    //blue
                    case (counter)
                        1,3,7,9: sum_r <= sum_r + rdata_r;
                        2,4,6,8: sum_g <= sum_g + rdata_g;
                        default: sum_b <= sum_b;
                    endcase
                end
                else if(~center[7])begin
                    //green
                    case (counter)
                        2,8: sum_b <= sum_b + rdata_b;
                        4,6: sum_r <= sum_r + rdata_r;
                        default: sum_g <= sum_g;
                    endcase
                end
                else begin
                    //green
                    case (counter)
                        2,8: sum_r <= sum_r + rdata_r;
                        4,6: sum_b <= sum_b + rdata_b;
                        default: sum_g <= sum_g;
                    endcase
                end

                counter <= counter + 1'd1;

                case (counter) // -> for y axis	(row)
					0,1,2: begin
                        addr_r[13:7] <= center[13:7] - 7'd1;
                        addr_g[13:7] <= center[13:7] - 7'd1;
                        addr_b[13:7] <= center[13:7] - 7'd1;
                    end
					3,4,5: begin
                        addr_r[13:7] <= center[13:7];
                        addr_g[13:7] <= center[13:7];
                        addr_b[13:7] <= center[13:7];
                    end
					6,7,8: begin
                        addr_r[13:7] <= center[13:7] + 7'd1;
                        addr_g[13:7] <= center[13:7] + 7'd1;
                        addr_b[13:7] <= center[13:7] + 7'd1;
                    end
				endcase

				case (counter) // -> for x axis	(column)									
					0,3,6: begin
                        addr_r[6:0] <= center[6:0] - 7'd1;
                        addr_g[6:0] <= center[6:0] - 7'd1;
                        addr_b[6:0] <= center[6:0] - 7'd1;
                    end
					1,4,7: begin
                        addr_r[6:0] <= center[6:0];
                        addr_g[6:0] <= center[6:0];
                        addr_b[6:0] <= center[6:0];
                    end
					2,5,8: begin
                        addr_r[6:0] <= center[6:0] + 7'd1;
                        addr_g[6:0] <= center[6:0] + 7'd1;
                        addr_b[6:0] <= center[6:0] + 7'd1;
                    end
				endcase
            end
            C:begin
                wr_r <= ~(center[0]&~center[7]);
                addr_r <= center;
                wdata_r <= ~center[0]&center[7] ? sum_r>>2 : sum_r>>1;

                wr_g <= center[0]^center[7];
                addr_g <= center;
                wdata_g <= sum_g>>2;

                wr_b <= ~(~center[0]&center[7]);
                addr_b <= center;
                wdata_b <= center[0]&~center[7] ? sum_b>>2 : sum_b>>1;

                if(center[6:0]==7'd126)center <= center + 3'd3;
                else center <= center + 1'd1;

                counter <= 0;
                sum_r <= 0;
                sum_g <= 0;
                sum_b <= 0;
            end
            default:begin
                done <= 1'd1;
            end
        endcase

endmodule
