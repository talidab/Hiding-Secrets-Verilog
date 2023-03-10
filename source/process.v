`timescale 1ns / 1ps

module process (
        input                		clk,		    	// clock 
        input  	 [23:0]        in_pix,	        // valoarea pixelului de pe pozitia [in_row, in_col] din imaginea de intrare (R 23:16; G 15:8; B 7:0)
        input  	 [8*512-1:0]   hiding_string,     // sirul care trebuie codat
        output reg [6-1:0]       row, col, 	        // selecteaza un rand si o coloana din imagine
        output reg           		out_we, 		    // activeaza scrierea pentru imaginea de iesire (write enable)
        output reg [23:0]    		out_pix,	        // valoarea pixelului care va fi scrisa in imaginea de iesire pe pozitia [out_row, out_col] (R 23:16; G 15:8; B 7:0)
        output reg           		gray_done,		    // semnaleaza terminarea actiunii de transformare in grayscale (activ pe 1)
        output reg           		compress_done,		// semnaleaza terminarea actiunii de compresie (activ pe 1)
        output reg           		encode_done        // semnaleaza terminarea actiunii de codare (activ pe 1)
    );	
    
    //TODO - instantiate base2_to_base3 here
	wire [31:0] base3_no;
	wire done;
	reg en = 0;
	reg [15:0] hiding_string2;
	reg [31:0] hiding_string3;
	base2_to_base3 #(.width(16), .base(3), .base_width(2)) b2b3 (.base3_no(base3_no), .done(done), .base2_no(hiding_string2), .en(en), .clk(clk));
	
    //TODO - build your FSM here
`define READ 					0 			//starea de citire si de calculare maxim si minim pentru in_pix
`define WRITE 					1			//starea de construire out_pix si scriere
`define CHECK					2 			//starea de verificare daca s-a ajuns la sfarsitul matricei
`define INC						3			//starea de incrementare
`define GRAY_DONE 			4			//starea care marcheaza sfarsitul procesului grayscale
`define INIT					5			//starea in care initializez suma, suma_var si beta cu 0 si fac tecerea de la un bloc la altul
`define SUM						6			//starea in care calculez suma elementelor din bloc
`define SET 					8			//starea in care setez row si col		
`define CALC_VAR 				9			//starile in care calculez deviatia standard var si beta
`define CALC_LM_HM			13			//starea in care calculez Lm si Hm
`define CONSTR 				14			//starea in care scriu noile valori ale pixelilor
`define CHECK2					18			//starea in care verific sfarsitul unui bloc 4x4
`define COMPRESS_DONE   	19			//starea care marcheaza sfarsitul procesului de compresie
`define INIT2					20			//starea in care ma mut la inceputul imaginii si initializez pozitiile i1,j1, i2,j2 cu 0
`define PRIMAPOZ				21			//starea in care retin valoarea de pe prima pozitie din bloc si indicii acesteia
`define ADOUAPOZ				22			//starea in care calculez urmatoarea valoare diferita din bloc si ii retin pozitia
`define ENCODE					24			//starea in care are loc procesul de codificare confrom algoritmului
`define CONV					28			//starea de conversie a cate 16 biti din sirul care trebuie codat din baza 2 in bazaa 3
`define CHECK3					29			//starea in care verific daca am ajuns la sfarsitul unui bloc sau la sfarsitul imaginii
`define SETRC					30			//starea in care setez row si col cu valorile lui i si j
`define ENCODE_DONE			31			//starea care marcheaza sfarsitul procesului de codificare

reg [6:0] state = 0, next_state;
reg [7:0] max, min;
reg [7:0] media = 0;
reg [6:0] i = 0, j = 0, nr = 0, k1;
reg [8*512 - 1:0] k = 0;
reg [6:0] i1 = 0, j1 = 0, i2 = 0, j2 = 0;
reg [2:0] M = 4;
reg [16:0] suma = 0, suma_var = 0;
reg [7:0] avg = 0, var = 0;
reg [4:0] beta = 0;
reg [7:0] Lm = 0, Hm = 0, Lm1 = 0, Hm1 = 0;

always @(posedge clk) begin
	state <= next_state;
end

always @(*) begin
	out_we = 0;
	gray_done = 0;
	compress_done = 0;
	encode_done = 0;
	case(state)
		`READ: begin 
			row = i;
			col = j;
			// calculare maxim
			if (in_pix[23:16] >= in_pix[15:8] && in_pix[23:16] >= in_pix[7:0])
					max = in_pix[23:16];
			else if (in_pix[15:8] >= in_pix[23:16] && in_pix[15:8] >= in_pix[7:0])
					max = in_pix[15:8];
			else if (in_pix[7:0] >= in_pix[23:16] && in_pix[7:0] >= in_pix[15:8]) 
					max = in_pix[7:0];
					
			//calculare minim
			if(in_pix[23:16] <= in_pix[15:8] && in_pix[23:16] <= in_pix[7:0])
					min = in_pix[23:16];
			else if(in_pix[15:8] <= in_pix[23:16] && in_pix[15:8] <= in_pix[7:0])
					min = in_pix[15:8];
			else if(in_pix[7:0] <= in_pix[23:16] && in_pix[7:0] <= in_pix[15:8])
					min = in_pix[7:0];
			
			next_state = `WRITE;
		end
			
		`WRITE: begin	
			out_we = 1; 
			media = (max + min)/2;
			out_pix[23:16] = 0;
			out_pix[15:8] = media;
			out_pix[7:0] = 0;		
			next_state = `CHECK;
		end
	
		`CHECK: begin 
			if ( i == 63 && j == 63) 
				next_state = `GRAY_DONE;
			else 
				next_state = `INC;
		end
		
		`INC: begin
				j = j + 1;
				if( j == 64) begin
					i = i + 1;
					j = 0;
				end
				if( i == 64) 
					i = 0; 
				next_state = `READ;
		end
		
		`GRAY_DONE: begin //starea gray done 3
			gray_done = 1;
			i = 0;
			j = 0;
			next_state = `SET;
		end
		
		`SET: begin
			row = i;
			col = j;
			next_state = `SUM;
		end
		
		`INIT: begin
			suma = 0;
			suma_var = 0;
			beta = 0;
			avg = 0;
		if(i == 63 && j == 63) next_state = `COMPRESS_DONE;
		else if(i == 63 && j%M == 3) begin
				i = 0;
				j = j + 1;
				next_state = `SET;
		end
		else 
		if (j%M == 3) begin
			j = j - 3;
			i = i + 1;
			next_state = `SET;
			end
		end
		
		`SUM: begin
			 suma = suma + in_pix[15:8];
			 if(row%M == 3 && col%M == 3) begin
				avg = suma / (M * M);
				next_state = `CALC_VAR;
			 end else next_state = `SUM + 1;
		end
		
		`SUM + 1: begin
			j = j + 1;
			if( j%M == 0) begin
				i = i + 1;
				j = j - 4;
				end
			next_state = `SET;
		end
		
		`CALC_VAR: begin
			i = i - 3;
			j = j - 3;
			next_state = `CALC_VAR + 1;
		end
		
		`CALC_VAR + 1: begin
			row = i;
			col = j;
			next_state = `CALC_VAR + 2;
		end
		
		`CALC_VAR + 2: begin
			if(avg > in_pix[15:8])
				suma_var = suma_var + avg - in_pix[15:8];
				else
				suma_var = suma_var + in_pix[15:8] - avg;
			if(in_pix[15:8] >= avg)
				beta = beta + 1;
			if(row%M == 3 && col%M == 3) begin
				var = suma_var / ( M * M);
				next_state = `CALC_LM_HM;
			end
			else next_state = `CALC_VAR + 3;
		end
		
		`CALC_VAR + 3: begin
			j = j + 1;
			if( j%M == 0) begin
				i = i + 1;
				j = j - 4;
				end
			next_state = `CALC_VAR + 1;
		end
		
		`CALC_LM_HM: begin
			Lm = avg - (M*M*var)/(2 * (M*M - beta));
			Hm = avg + (M * M * var) / (2 * beta);
			next_state = `CONSTR;
		end
		
		`CONSTR: begin
			i = i - 3;
			j = j - 3;
			next_state = `CONSTR + 1;
		end
		
		`CONSTR + 1: begin
			row = i;
			col = j;
			next_state = `CONSTR + 2;
		end
		
		`CONSTR + 2: begin
		out_we = 1;
			if(in_pix[15:8] < avg)
				out_pix[15:8] = Lm;
				else
					out_pix[15:8] = Hm;
				next_state = `CHECK2;
		end
		
		`CHECK2: begin
			if ( row%M == 3 && col%M == 3) next_state = `INIT;
			else
			next_state = `CONSTR + 3;
		end
		
		`CONSTR + 3: begin
			j = j + 1;
			if( j%M == 0) begin
				i = i + 1;
				j = j - 4;
				end
			next_state = `CONSTR + 1;
		end
		
		`COMPRESS_DONE: begin
			compress_done = 1;
			next_state = `INIT2;
		end

		`INIT2: begin
			i = 0;
			j = 0;
			i1 = 0;
			j1 = 0;
			i2 = 0;
			j2 = 0;
			nr = 0;
			next_state = `PRIMAPOZ;
		end
		
		`PRIMAPOZ: begin
			row = i;
			col = j;
			if(row%M == 0 && col%M == 0) begin
					Lm1 = in_pix[15:8];
					i1 = row;
					j1 = col;
				end
			next_state = `ADOUAPOZ;
		end
		
		`ADOUAPOZ: begin
			if (in_pix[15:8] != Lm1) begin
					i2 = i;
					j2 = j;
					next_state = `CONV;
				end
			else 
			begin 
				nr = nr + 1; 
				next_state = `ADOUAPOZ + 1; 
			end
			// tratez separat cazul in care nu exista decat o valoare in bloc
			if(nr == 16) begin 
				i2 = i1; 
				j2 = j1 + 1; 
				next_state = `CONV; 
			end
		end
		
		`ADOUAPOZ + 1: begin
			j = j + 1;
			if( j%M == 0) begin
				i = i + 1;
				j = j - 4;
				end
				next_state = `PRIMAPOZ;
		end
		
		 `CONV: begin
			en = 1;
			i = i1;
			j = j1;
			hiding_string2 = hiding_string[k+:16];
			if (done == 1) begin 
				en = 0; 
				k1 = 0;
				hiding_string3 = base3_no; 
				next_state = `SETRC;
			end 
			else if (done == 0) begin 
				en = 1;
				next_state = `CONV;
			end
			
		 end

		`CHECK3: begin
			if(row == 63 && col == 63) begin 
				next_state = `ENCODE_DONE;
			end
			else
			if ( row%M == 3 && col%M == 3) begin
				k = k + 16;
				k1 = 0;
				nr = 0;
				next_state = `ENCODE + 3;
			end
			else next_state = `ENCODE + 1;
		end
		
		`SETRC: begin
			row = i;
			col = j;
			next_state = `ENCODE;
		end
		
		`ENCODE: begin 
			if( row == i1 && col == j1)
				out_pix[15:8] = in_pix[15:8];
			else
			if ( row == i2 && col == j2 )
				out_pix[15:8] = in_pix[15:8];
			else begin
					out_we = 1;
					if( hiding_string3[k1+:2] == 2'b00)
						out_pix[15:8] = in_pix[15:8];
					else
					if( hiding_string3[k1+:2] == 2'b01)
						out_pix[15:8] = in_pix[15:8] + 1;
					else
						if(hiding_string3[k1+:2] == 2'b10)
							out_pix[15:8] = in_pix[15:8] - 1;
					k1 = k1 + 2;
			end
			next_state = `CHECK3;
		end
		
		`ENCODE + 1: begin
			j = j + 1;
			if( j%M == 0) begin
				i = i + 1;
				j = j - 4;
				end
			next_state = `ENCODE + 2;
		end
		
		`ENCODE + 2: begin
			if ( row%M == 3 && col%M == 3) begin
				next_state = `ENCODE + 3;
			end
			else
				next_state = `SETRC;
		end
		
		`ENCODE + 3: begin
			if(i == 63 && j == 63) next_state = `ENCODE_DONE;
				else if(j == 63 && i%M == 3) begin
						j = 0;
						i = i + 1;
						i1 = i;
						j1 = j;
						next_state = `PRIMAPOZ;
					end
					else 
						if (i%M == 3) begin
							i = i - 3;
							j = j + 1;
							i1 = i;
							j1 = j;
							next_state = `PRIMAPOZ;
					end
		end
		
		`ENCODE_DONE: begin
			encode_done = 1;
			next_state = `READ;
		end
		endcase
end

endmodule
