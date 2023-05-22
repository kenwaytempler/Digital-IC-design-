// Determine the smallest power of 2 that is greater than or equal to the image width and height
parameter MAX_SIZE = 256; // maximum size of image
integer pow2_width, pow2_height;
initial begin
  pow2_width = 1;
  pow2_height = 1;
  while (pow2_width < width || pow2_height < height) begin
    pow2_width = pow2_width * 2;
    pow2_height = pow2_height * 2;
  end
end

// Pad the image to the nearest power of 2 by adding zeros to the right and bottom edges
reg [7:0] padded_image[MAX_SIZE-1:0][MAX_SIZE-1:0]; // image is assumed to be 8-bit grayscale
integer i, j;
always @* begin
  for (i = 0; i < pow2_height; i = i + 1) begin
    for (j = 0; j < pow2_width; j = j + 1) begin
      if (i < height && j < width) begin
        padded_image[i][j] = original_image[i][j];
      end else begin
        padded_image[i][j] = 8'h00; // pad with zeros
      end
    end
  end
end