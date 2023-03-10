`timescale 1ns / 1ps

// -------------------------------------------
// !!! Nu includeti acest fisier in arhiva !!!
// -------------------------------------------

module div_algo # (
			parameter WIDTH = 16
		) (
		output [WIDTH-1:0] Q,
		output [WIDTH-1:0] R,
		input  [WIDTH-1:0] N,
		input  [WIDTH-1:0] D
    );

	assign Q = N/D;
	assign R = N%D;

endmodule
