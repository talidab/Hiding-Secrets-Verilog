`timescale 1ns / 1ps

// -------------------------------------------
// !!! Nu includeti acest fisier in arhiva !!!
// -------------------------------------------

module base2_to_base3 #(
        parameter width      = 16,
        parameter base       = 3,
        parameter base_width = 2 // no of bits for the corresponding base
    )(
        output reg [base_width*width - 1 : 0] base3_no,
        output reg                                done,
        input                 [width - 1 : 0] base2_no,
        input                                       en,
        input                                      clk
    );
    
    `define READ 0
    `define EXEC 1
    `define DONE 3
    
    reg  [1:0] state = 0, next_state = 0;
    reg  [4:0] i;
    reg [15:0] x;
    
    wire [width-1:0] Q;
    wire [width-1:0] R;
	reg  [width-1:0] N;
	reg  [width-1:0] D=base;
    div_algo #(width) div (.Q(Q), .R(R), .N(N), .D(D));
    
    always @(posedge clk) begin       
        case(state)
            `READ: begin
                //init variables
                i                <= 0;
                done             <= 0;
                base3_no         <= 0;
                
                //read the number if the case
                x                <= en ? base2_no : 0;
                state            <= en ? `EXEC : `READ;
            end
            `EXEC: begin
                //execute the division
                N                <= x;
                state            <= `EXEC + 1;
            end
            `EXEC+1: begin
                //prepare for the next division or move on
                if (x) begin
                    i                <= i + 1;
                    x                <= Q;
                    base3_no[2*i+:2] <= R[1:0];
                    state            <= `EXEC;
                end else begin
                      state          <= `DONE;
                end
            end
            `DONE: begin
                done             <= 1;
                state            <= `READ;
            end
        endcase
    end

   

endmodule
