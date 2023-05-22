// 在這個Verilog代碼中，輸入數據和卷積核值被分別存儲在兩個內存中，
// 並使用計數器（addr_cnt）來訪問每次卷積操作的適當內存位置。
// 卷積核被定義為一個常量數組 kernel，
// 卷積運算本身則是在 always @(*) 塊中使用兩個嵌套的 for 循環進行。
// 卷積輸出值存儲在 conv_out 中。


module conv_3x3(
    input clk,
    input rst_n,
    input signed [7:0] data_in,
    input signed [7:0] kernel_in,
    output reg signed [15:0] conv_out
);

// Define the memory locations for input data and kernel
localparam INPUT_ADDR = 8'h00;
localparam KERNEL_ADDR = 8'h10;

reg signed [7:0] input_mem [63:0];
reg signed [7:0] kernel_mem [8:0];

// Memory write enable signal
reg mem_wr_en = 1'b0;

// Counter for tracking input data and kernel memory addresses
reg [5:0] addr_cnt = 6'b0;

// Define the convolution kernel
reg signed [7:0] kernel [2:0][2:0] = { {0, -1, 0},
                                         {-1, 5, -1},
                                         {0, -1, 0} };

// Combinational logic for the convolution operation
always @(*) begin
    conv_out = 16'd0;
    for (int i = -1; i <= 1; i = i+1) begin
        for (int j = -1; j <= 1; j = j+1) begin
            conv_out = conv_out + input_mem[addr_cnt+i][addr_cnt+j] * kernel[i+1][j+1];
        end
    end
end

// Sequential logic for loading input data and kernel values from memory
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        // Reset state
        mem_wr_en <= 1'b0;
        addr_cnt <= 6'b0;
        conv_out <= 16'd0;
    end else begin
        // Memory write state
        if (mem_wr_en) begin
            input_mem[addr_cnt] <= data_in;
            kernel_mem[addr_cnt] <= kernel_in;
            addr_cnt <= addr_cnt + 1;
        end
        // Memory read state
        else begin
            data_in <= input_mem[addr_cnt];
            kernel_in <= kernel_mem[addr_cnt];
            addr_cnt <= addr_cnt + 1;
        end
    end
end

// Control logic for memory write/read
always @(*) begin
    if (addr_cnt < 9) begin
        mem_wr_en = 1'b1;
    end else if (addr_cnt < 72) begin
        mem_wr_en = 1'b0;
    end else begin
        mem_wr_en = 1'b1;
    end
end

endmodule