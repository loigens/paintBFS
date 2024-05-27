module Palette
(
	input logic VGA_CLK, RE_OCM, blank,
	input logic [7:0] PixelColor,
	output logic [7:0] VGA_R, VGA_G, VGA_B
);
	
	always_ff @ (posedge VGA_CLK) begin
		if( ~blank || ~RE_OCM ) begin // when not reading or during blanking
			VGA_R <= 8'h00;
			VGA_G <= 8'h00;
			VGA_B <= 8'h00;
		end else 
			unique case(PixelColor)
			
			/* Black (path) */
			0: begin
				VGA_R <= 8'h00;
				VGA_G <= 8'h00;
				VGA_B <= 8'h00;
				end
			
			/* Start */
			1: begin
				VGA_R <= 8'hC0;
				VGA_G <= 8'hC0;
				VGA_B <= 8'hC0;
				end
			
			/* Finish */
			2: begin
				VGA_R <= 8'h7F;
				VGA_G <= 8'h82;
				VGA_B <= 8'hBB;
				end
			
			/* Path */
			3: begin
				VGA_R <= 8'h99;
				VGA_G <= 8'hD9;
				VGA_B <= 8'hEA;
				end
			
			/* Light Blue */
			4: begin
				VGA_R <= 8'hAD;
				VGA_G <= 8'hD8;
				VGA_B <= 8'hE6;
				end
				
			/* Blue */
			5:	begin
				VGA_R <= 8'h32;
				VGA_G <= 8'h82;
				VGA_B <= 8'hF6;
				end
			
			/* Blue2 */
			6: begin
				VGA_R <= 8'h00;
				VGA_G <= 8'h23;
				VGA_B <= 8'hF5;
				end
				
			/* Navy */
			7: begin
				VGA_R <= 8'h00;
				VGA_G <= 8'h00;
				VGA_B <= 8'h80;
				end
				
			/* Blue */
			8: begin
				VGA_R <= 8'h00;
				VGA_G <= 8'h00;
				VGA_B <= 8'hFF;
				end
			
			/* Purple */
			9: begin
				VGA_R <= 8'h73;
				VGA_G <= 8'h2B;
				VGA_B <= 8'hF5;
				end
			
			/* Purple2 */
			10:	begin
				VGA_R <= 8'h7E;
				VGA_G <= 8'h84;
				VGA_B <= 8'hF7;
				end
				
			/* Magenta */
			11: begin
				VGA_R <= 8'hFF;
				VGA_G <= 8'h00;
				VGA_B <= 8'hFF;
				end
				
			/* Red */
			12: begin
				VGA_R <= 8'hFF;
				VGA_G <= 8'h00;
				VGA_B <= 8'h00;
				end
				
			/* Red */
			13: begin
				VGA_R <= 8'hEB;
				VGA_G <= 8'h33;
				VGA_B <= 8'h24;
				end
			
			/* Red2 */
			14: begin
				VGA_R <= 8'hF0;
				VGA_G <= 8'h87;
				VGA_B <= 8'h84;
				end
			
			/* Maroon */
			15: begin
				VGA_R <= 8'h80;
				VGA_G <= 8'h00;
				VGA_B <= 8'h00;
				end
			
			/* Olive */
			16: begin
				VGA_R <= 8'h80;
				VGA_G <= 8'h80;
				VGA_B <= 8'h00;
				end
				
			/* Pink */
			17: begin
				VGA_R <= 8'hEA;
				VGA_G <= 8'h36;
				VGA_B <= 8'h80;
				end
			
			/* Orange */
			18: begin
				VGA_R <= 8'hFF;
				VGA_G <= 8'hA5;
				VGA_B <= 8'h00;
				end
				
			/* Yellow */
			19: begin
				VGA_R <= 8'hFF;
				VGA_G <= 8'hFF;
				VGA_B <= 8'h00;
				end
				
			/* Yellow */
			20: begin
				VGA_R <= 8'hFF;
				VGA_G <= 8'hFD;
				VGA_B <= 8'h55;
				end
			
			/* Orange2 */
			21: begin
				VGA_R <= 8'hF0;
				VGA_G <= 8'hBE;
				VGA_B <= 8'h46;
				 end
			
			/* Green Yellow */
			22: begin
				VGA_R <= 8'h80;
				VGA_G <= 8'hA5;
				VGA_B <= 8'h80;
				end
				
			/* Green */
			23: begin
				VGA_R <= 8'hA1;
				VGA_G <= 8'hFB;
				VGA_B <= 8'h8E;
				 end
			
			/* Green2 */
			24: begin
				VGA_R <= 8'h75;
				VGA_G <= 8'hF9;
				VGA_B <= 8'h4D;
				 end
				 
			/* Teal */
			25: begin
				VGA_R <= 8'h36;
				VGA_G <= 8'h7E;
				VGA_B <= 8'h7F;
				 end
			
			/* Teal2 */
			26: begin
				VGA_R <= 8'h48;
				VGA_G <= 8'hAB;
				VGA_B <= 8'hC9;
				 end
				 
			/* Cyan */
			27: begin
				VGA_R <= 8'h00;
				VGA_G <= 8'hFF;
				VGA_B <= 8'hFF;
				end
				
			/* Green */
			28: begin
				VGA_R <= 8'h00;
				VGA_G <= 8'hFF;
				VGA_B <= 8'h00;
				end
			
			/* Dark Green */
			29: begin
				VGA_R <= 8'h00;
				VGA_G <= 8'h80;
				VGA_B <= 8'h00;
				end

			/* Tan */
			30: begin
				VGA_R <= 8'hD2;
				VGA_G <= 8'hB4;
				VGA_B <= 8'h8C;
				end
			

			/* Khaki */
			31: begin
				VGA_R <= 8'hF0;
				VGA_G <= 8'hE6;
				VGA_B <= 8'h8C;
				end

			/* Lavender */
			32: begin
				VGA_R <= 8'hE6;
				VGA_G <= 8'hE6;
				VGA_B <= 8'hFA;
				end

			/* Pale Green */
			33: begin
				VGA_R <= 8'h98;
				VGA_G <= 8'hFB;
				VGA_B <= 8'h98;
				end

			/* Pale Turquoise */
			34: begin
				VGA_R <= 8'hAF;
				VGA_G <= 8'hEE;
				VGA_B <= 8'hEE;
				end

			/* Pale Violet Red */
			35: begin
				VGA_R <= 8'hDB;
				VGA_G <= 8'h70;
				VGA_B <= 8'h93;
				end

			/* Dark Orange */
			36: begin
				VGA_R <= 8'hFF;
				VGA_G <= 8'h45;
				VGA_B <= 8'h00;
				end

			/* Light Coral */
			37: begin
				VGA_R <= 8'hFA;
				VGA_G <= 8'h80;
				VGA_B <= 8'h72;
				end

			/* Tomato */
			38: begin
				VGA_R <= 8'hFF;
				VGA_G <= 8'h63;
				VGA_B <= 8'h47;
				end

			/* Gold */
			39: begin
				VGA_R <= 8'hFF;
				VGA_G <= 8'hD7;
				VGA_B <= 8'h00;
				end

			/* Violet */
			40: begin
				VGA_R <= 8'hEE;
				VGA_G <= 8'h82;
				VGA_B <= 8'hEE;
				end

			/* Dark Magenta */
			41: begin
				VGA_R <= 8'h8B;
				VGA_G <= 8'h00;
				VGA_B <= 8'h8B;
				end

			/* Dark Khaki */
			42: begin
				VGA_R <= 8'h8B;
				VGA_G <= 8'h8B;
				VGA_B <= 8'h7A;
				end

			/* Floral White */
			43: begin
				VGA_R <= 8'hFF;
				VGA_G <= 8'hFA;
				VGA_B <= 8'hF0;
				end

			/* Sienna */
			44: begin
				VGA_R <= 8'hA0;
				VGA_G <= 8'h52;
				VGA_B <= 8'h2D;
				end

			/* Beige */
			45: begin
				VGA_R <= 8'hF5;
				VGA_G <= 8'hF5;
				VGA_B <= 8'hDC;
				end

			/* Antique White */
			46: begin
				VGA_R <= 8'hFA;
				VGA_G <= 8'hEB;
				VGA_B <= 8'hD7;
				end

			/* Bisque */
			47: begin
				VGA_R <= 8'hFF;
				VGA_G <= 8'hE4;
				VGA_B <= 8'hC4;
				end

			/* Coral */
			48: begin
				VGA_R <= 8'hFF;
				VGA_G <= 8'hA0;
				VGA_B <= 8'h7A;
				end

			/* Chocolate */
			49: begin
				VGA_R <= 8'hD2;
				VGA_G <= 8'h69;
				VGA_B <= 8'h1E;
				end

			/* Peru */
			50: begin
				VGA_R <= 8'hCD;
				VGA_G <= 8'h85;
				VGA_B <= 8'h3F;
				end

			/* Thistle */
			51: begin
				VGA_R <= 8'hD8;
				VGA_G <= 8'hBF;
				VGA_B <= 8'hD8;
				end

			/* Crimson */
			52: begin
				VGA_R <= 8'hDC;
				VGA_G <= 8'h14;
				VGA_B <= 8'h3C;
				end

			/* Magenta */
			53: begin
				VGA_R <= 8'hFF;
				VGA_G <= 8'h00;
				VGA_B <= 8'hFF;
				end

			/* Aquamarine */
			54: begin
				VGA_R <= 8'h66;
				VGA_G <= 8'hCD;
				VGA_B <= 8'hAA;
				end

			/* Firebrick */
			55: begin
				VGA_R <= 8'hB2;
				VGA_G <= 8'h22;
				VGA_B <= 8'h22;
				end

			/* Light Yellow */
			56: begin
				VGA_R <= 8'hFF;
				VGA_G <= 8'hFF;
				VGA_B <= 8'hE0;
				end

			/* Spring Green */
			57: begin
				VGA_R <= 8'h00;
				VGA_G <= 8'hFF;
				VGA_B <= 8'h7F;
				end

			/* Honeydew */
			58: begin
				VGA_R <= 8'hF0;
				VGA_G <= 8'hFF;
				VGA_B <= 8'hF0;
				end

			/* Blue Violet */
			59: begin
				VGA_R <= 8'h8A;
				VGA_G <= 8'h2B;
				VGA_B <= 8'hE2;
				end
			
			/* Gray */
			60: begin
				VGA_R <= 8'h80;
				VGA_G <= 8'h80;
				VGA_B <= 8'h80;
				end
				
			default: begin
				VGA_R <= 8'hFF;
				VGA_G <= 8'hFF;
				VGA_B <= 8'hFF;
				end
			endcase
	end
	
endmodule	