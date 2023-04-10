module rails(clk, reset, data, valid, result);

input        clk;
input        reset;
input  [3:0] data;
output  reg  valid;
output  reg  result; 

integer i = 32'd0;
reg [2:0] state, next_state;
reg [3:0] numoftrain;
reg [3:0] validation[0:15];
reg [3:0] stack[0:15];
reg [3:0] counter; // for inputing data and stack push operations
reg [3:0] top; // top == 0 means empty , and stack[0] is always empty 
reg [3:0] next_element;

parameter cold = 4'd0, in1 = 4'd1, in2 = 4'd2, reinit = 4'd3, push=4'd4, pop=4'd5, finish = 4'd6, out = 4'd7; 

always@(*)begin //next state
	case(state)
		cold:
			next_state = in1;
		in1:
			next_state = in2;
		in2: begin
			if(numoftrain != counter)
				next_state = in2;
			else 
				next_state = reinit;
		end
		reinit:
			next_state = push; 
		push: begin
			if(numoftrain == counter)
				next_state = pop;    	
			else if((top!=0) & (validation[next_element] == stack[top]) )
				next_state = pop;
			else
				next_state = push; 
		end
		pop: begin
			if((numoftrain == counter) & ((top==0) | (validation[next_element] != stack[top])))
				next_state = finish;
			else if((top==0) | (validation[next_element] != stack[top])) 
				next_state = push;
			else 
			    next_state = pop;
		end
		finish:
			next_state = out;
		out:
			next_state = in1;
		default:
			next_state = in1;
	endcase
end

always@(posedge clk or posedge reset)begin //curent state
	if(reset)begin
		state = cold;
		for(i=0;i<16;i=i+1) 
			validation[i] <= 4'b0;
		for(i=0;i<16;i=i+1)
			stack[i] <= 4'b0;
		i = 0;
		counter = 0;
		top = 0;
		next_element = 0;
		numoftrain = 0;
	end
	else
		state = next_state;
end

always@(posedge clk) begin 	//output and data flow
		case(state)
			cold:;
			in1:
				numoftrain = data;
			in2: begin
				validation[counter] = data;
				counter = counter + 1;
			end
			reinit:
				counter = 0;
			push: begin
				top = top + 1;
				counter = counter + 1;
				stack[top] = counter; 				
			end
			pop: begin
				next_element = next_element + 1;
				top = top - 1;
			end	
			finish: begin 
				if(top == 0)
					result = 1'd1;
				else 
					result = 1'd0;
				valid = 1'd1;
			end	
			out:begin
				for(i=0;i<16;i=i+1) 
					validation[i] <= 4'b0;
				for(i=0;i<16;i=i+1)
					stack[i] <= 4'b0;
				i = 0;	
				counter = 0;
				top = 0;
				next_element = 0;
				result = 1'd0;
				valid = 1'd0;
			end
			default:;
		endcase
	end

endmodule