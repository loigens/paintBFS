module PixelRender
(
	input logic 				Clk, Reset, blank, Run,
	input logic					VGA_CLK,
	input logic 				WE, RE_OCM,
	
	input logic [7:0]			WritePixel,
	input logic [9:0]			WriteX, WriteY,
	input logic [9:0] 		DrawX, DrawY,
	
	output logic [7:0] 		VGA_R, VGA_G, VGA_B,	 // Colors for the VGA
	output logic [12:0]		StartPoint, EndPoint,
	
	// For Dijkstra
	input logic					AVL_READ, AVL_WRITE, AVL_CS,
	input logic [3:0]       AVL_BYTE_EN,
	input logic [31:0]		AVL_WRITEDATA,
	input logic [9:0]		   AVL_ADDRESS,
	
	output logic 				AVL_WAIT_REQUEST,
	output logic [31:0]		AVL_READDATA
);

	logic WE_OCM;
	logic [3:0] BE, BE_OCM;
	logic [7:0] PixelSelect, PixelColor;
	logic [9:0] read_addr, write_addr, ADDR_OCM;
	logic [31:0] data, data_b, q, DATA_OCM;
	
	
	assign AVL_WAIT_REQUEST = 1'b0; // lol
	
	/* STEP 1: Convert the pixel into an 8*8 pixel (e.g., 0<X,Y<8 correspond to pixel 0) */
	logic [5:0] DrawPixelX, DrawPixelY, WritePixelX, WritePixelY;
			
	always_comb begin
		if( DrawX < 512 ) begin
			DrawPixelX = DrawX[8:3]; // Every 8 pixels (equivalent to >> 3)
			DrawPixelY = DrawY[8:3];
		end else begin
			DrawPixelX = 0;
			DrawPixelY = 0;
		end
	end
	
	always_comb begin
		if( WriteX < 512 ) begin
			WritePixelX = WriteX[8:3];
			WritePixelY = WriteY[8:3];
		end else begin
			WritePixelX = 0;
			WritePixelY = 0;
		end
	end
	
	/* STEP 2: Convert the pixel into OCM address */
	logic [11:0] readtemp, writetemp;
	
	assign readtemp = {6'd0,DrawPixelX} + {DrawPixelY,6'd0}; // Each pixel as an element from 0 to 3840-1 
	assign writetemp = {6'd0,WritePixelX} + {WritePixelY,6'd0};
	
	assign read_addr = readtemp[11:2]; // equivalent to >> 2, since each word contains 4 pixels
	assign write_addr = writetemp[11:2];
	
	/* STEP 3a: Determine byte enable for write */
	
	always_comb begin
		unique case(writetemp[1:0])
			0: data = {24'd0,WritePixel};
			1: data = {16'd0,WritePixel,8'd0};
			2: data = {8'd0,WritePixel,16'd0};
			3: data = {WritePixel,24'd0};
			
			default:
				data = 0;
		endcase
	end
	
	always_comb begin
		unique case(writetemp[1:0])
			0: BE = {3'd0,1'b1};
			1: BE = {2'd0,1'b1,1'b0};
			2: BE = {1'b0,1'b1,2'd0};
			3: BE = {1'b1,3'd0};
			
			default:
				BE = 0;
		endcase
	end
	
	/* Step 3b: Determine byte enable for read */
	
	always_comb begin
		unique case(readtemp[1:0]) // indexes one byte
			0: PixelSelect = q[7:0];
			1: PixelSelect = q[15:8];
			2: PixelSelect = q[23:16];
			3: PixelSelect = q[31:24];
			
			default:
				PixelSelect = q[7:0];
		endcase
	end
	
	logic [12:0] StartNext, EndNext;
	
	always_ff @ (posedge Clk) begin
		StartPoint <= StartNext;
		EndPoint <= EndNext;
	end
	
	always_comb begin
		StartNext = StartPoint;
		EndNext = EndPoint;
		
		if( Reset ) begin
			StartNext = 13'd0;
			EndNext = 13'd0;
			
		end else if( WE_OCM ) begin
			case( WritePixel )
				1: StartNext = {WritePixelX, WritePixelY, 1'b1};
				2: EndNext = {WritePixelX, WritePixelY, 1'b1};
			endcase
		end
	end
	
	logic [9:0] draw_addr;
	
	always_comb begin
		if( Run ) begin
			WE_OCM = AVL_WRITE & AVL_CS;
			ADDR_OCM = AVL_ADDRESS;
			BE_OCM = AVL_BYTE_EN;
			DATA_OCM = AVL_WRITEDATA;
		end else begin
			WE_OCM = WE;
			ADDR_OCM = write_addr;
			BE_OCM = BE;
			DATA_OCM = data;
		end
	end
	
	logic			READ_A, WRITE_A;
	logic [3:0] BYTE_EN_A;
	logic [9:0] ADDRESS_A;
	logic [31:0] DATA_A, Q_A;
	
	int DistX, DistY;
	
	assign DistX = DrawX - WriteX;
	assign DistY = DrawY - WriteY;
	
	
	
	always_comb begin // Cursor
		if( ( DistX*DistX + DistY*DistY) <= 9 )
			PixelColor = WritePixel; // White
		else if( ( DistX*DistX + DistY*DistY) <= 4 )
			PixelColor = 63; // Mouse selection color
		else
			PixelColor = PixelSelect; // Background color
	end
			
	
	PixelOCM	PixelOCM(.clock ( Clk ),
	
							.address_a ( read_addr ),
							.data_a ( 32'd0 ),
							.byteena_a ( 4'd0 ),
							.rden_a ( RE_OCM ),
							.wren_a ( 1'b0 ),
							.q_a ( q ),
							
							.address_b ( ADDR_OCM ),
							.byteena_b ( BE_OCM ),
							.data_b ( DATA_OCM ),
							.rden_b ( AVL_READ ), // Read and Readdata will never be in conflict with drawing
							.wren_b ( WE_OCM ),
							.q_b ( AVL_READDATA ));
					 
					 
	Palette  Palette(.VGA_CLK, .PixelColor, .RE_OCM, 
						  .VGA_R, .VGA_G, .VGA_B, .blank );
	
endmodule