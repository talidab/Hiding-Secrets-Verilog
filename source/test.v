`timescale 1ns / 1ps

// -------------------------------------------
// !!! Nu includeti acest fisier in arhiva !!!
// -------------------------------------------

module top;

    parameter string_len = 512;
    //NOTE: In order to see shorter messages on the waveform, one can set string_len to a lower value
    //parameter string_len = 50;
    
    reg                    clk;
    reg [8*string_len-1:0] hiding_string;
    wire[23:0]             in_pix;
    wire[5:0]              row, col;
    wire                   we;
    wire[23:0]             out_pix;
    wire                   gray_done;
    wire                   compress_done; 
    wire                   encode_done;

    process p(clk, in_pix, hiding_string, row, col, we, out_pix, gray_done, compress_done, encode_done);
    image   i(clk, row, col, we, out_pix, in_pix);

    initial begin : LOAD_STRING
       reg [8*string_len-1:0] aux = 0;
       integer data_file;
       clk = 0;
       
       //Open the data file
       data_file = $fopen("test.string", "r");
       if(!data_file) begin
           $write("error opening data file\n");
           $finish;
       end
       
       //Take the data string from the file
       hiding_string = 0;
       if(!$fgets(aux, data_file)) begin
           $write("error reading from data file\n");
           $finish;
       end
       
       $fclose(data_file);
       
       hiding_string = aux;
    end

    always #2 clk = !clk;


endmodule
