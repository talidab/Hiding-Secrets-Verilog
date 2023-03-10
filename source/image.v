`timescale 1ns / 1ps

// -------------------------------------------
// !!! Nu includeti acest fisier in arhiva !!!
// -------------------------------------------

module image # (
		parameter image_size = 6,
        parameter image_init = 1
	)(
		input clk,			                // clock 
		input[image_size - 1:0] row,		// selecteaza un rand din imagine
		input[image_size - 1:0] col,		// selecteaza o coloana din imagine
		input we,			                // write enable (activeaza scrierea in imagine la randul si coloana date)
		input[23:0] in,		                // valoarea pixelului care va fi scris pe pozitia data
		output[23:0] out                    // valoarea pixelului care va fi citit de pe pozitia data
	);	

reg[23:0]  data[2**image_size - 1:0][2**image_size -1:0];

integer i, j, data_file;
initial begin
    if(image_init) begin
        data_file = $fopen("test.data", "r");
        if(!data_file) begin
            $write("error opening data file\n");
            $finish;
        end
        for(i = 0; i < 2**image_size; i = i + 1) begin
            for(j = 0; j < 2**image_size; j = j + 1) begin
                if($fscanf(data_file, "%d\n", data[i][j]) != 1) begin
                    $write("error reading test data\n");
                    $finish;
                end
            end
        end
        $fclose(data_file);
    end else begin
    for(i = 0; i < 2**image_size; i = i + 1)
        for(j = 0; j < 2**image_size; j = j + 1)
            data[i][j] = i + j;
    end
end

assign out = data[row][col];
	
always @(posedge clk) begin
	if(we)
		data[row][col] <= in;
end

endmodule
