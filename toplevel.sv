module toplevel
( 
	input logic 				CLOCK_50,
	input logic   	[3:0]  	KEY,
	output logic   [6:0]  	HEX0, HEX1,
	
	//////// LED //////////
	output		  [8:0]		LEDG,
	output		  [17:0]    LEDR,
	// Mouse
	inout	wire        		PS2_CLK,
	inout wire         		PS2_DAT,
	inout wire         		PS2_CLK2,
	inout wire         		PS2_DAT2,
	/*
	// SRAM Interface
	inout wire 		[15:0] 	SRAM_DQ,	     // Data to/from SRAM
	output logic	[19:0] 	SRAM_ADDR,	  // Addressing of the SRAM
	output logic            SRAM_CE_N, 	  // SRAM control signals
									SRAM_UB_N, 	  // Activates 15:8
									SRAM_LB_N, 	  // Activates 7:0
									SRAM_OE_N, 
									SRAM_WE_N,	*/	
	
	// VGA Interface
	output logic        		VGA_CLK,      //VGA Clock
									VGA_SYNC_N,   //VGA Sync signal
									VGA_BLANK_N,  //VGA Blank signal
									VGA_VS,       //VGA vertical sync signal
									VGA_HS,       //VGA horizontal sync signal
								
	output logic 	[7:0]  	VGA_R,        //VGA Red
									VGA_G,        //VGA Green
									VGA_B,         //VGA Blue
	
	// CY7C67200 Interface
	inout  wire  [15:0] 		OTG_DATA,     //CY7C67200 Data bus 16 Bits
	output logic [1:0]  		OTG_ADDR,     //CY7C67200 Address 2 Bits
	output logic        		OTG_CS_N,     //CY7C67200 Chip Select
									OTG_RD_N,     //CY7C67200 Write
									OTG_WR_N,     //CY7C67200 Read
									OTG_RST_N,    //CY7C67200 Reset
	input               		OTG_INT,      //CY7C67200 Interrupt
	
	// SDRAM Interface for Nios II Software
	output logic [12:0] 		DRAM_ADDR,    //SDRAM Address 13 Bits
	inout  wire  [31:0] 		DRAM_DQ,      //SDRAM Data 32 Bits
	output logic [1:0]  		DRAM_BA,      //SDRAM Bank Address 2 Bits
	output logic [3:0]  		DRAM_DQM,     //SDRAM Data Mast 4 Bits
	output logic        		DRAM_RAS_N,   //SDRAM Row Address Strobe
									DRAM_CAS_N,   //SDRAM Column Address Strobe
									DRAM_CKE,     //SDRAM Clock Enable
									DRAM_WE_N,    //SDRAM Write Enable
									DRAM_CS_N,    //SDRAM Chip Select
									DRAM_CLK      //SDRAM Clock
);
	
	logic Clk, Reset, check, Run; // Execute is button, Run is the state command. Same with Reset and Clean
	logic RE_OCM, WE; // RE and WE for drawing 
	
	assign LEDG[0] = done;
	assign LEDG[2] = check;
	assign LEDR[0] = valid;
	assign LEDR[1] = Run;
	
	logic valid; // Has start and endpoint?
	
	logic done;		
	
	logic [9:0] DrawX, DrawY;
	
	logic [12:0] StartPoint, EndPoint;
	
	assign Clk = CLOCK_50;
	always_ff @ (posedge Clk) begin
	  Reset <= ~(KEY[0]);        // The push buttons are active low
	  check <= ~(KEY[1]);
	end
	
	always_comb begin
		if( (DrawX < 512) && ~Run )
			RE_OCM = 1;
		else 
			RE_OCM = 0;	// Dont read pixel data when its over 512
	end
	
	always_comb begin
		if( (WriteX < 512) && Write && ~Run )
			WE <= 1;
		else
			WE <= 0; // Dont draw pixel when its over 512
	end
	
	assign valid = (StartPoint[0] & EndPoint[0]) ? 1'b1 : 1'b0;
	
	
	/* Interfaces keyboard and NIOS */
	logic [1:0] hpi_addr;
	logic [7:0] keycode;
   logic [15:0] hpi_data_in, hpi_data_out;
   logic hpi_r, hpi_w, hpi_cs, hpi_reset;
	 
   hpi_io_intf  hpi_io_inst(
                            .Clk(Clk),
                            .Reset(Reset),
                            // signals connected to NIOS II
                            .from_sw_address(hpi_addr),
                            .from_sw_data_in(hpi_data_in),
                            .from_sw_data_out(hpi_data_out),
                            .from_sw_r(hpi_r),
                            .from_sw_w(hpi_w),
                            .from_sw_cs(hpi_cs),
                            .from_sw_reset(hpi_reset),
                            // signals connected to EZ-OTG chip
                            .OTG_DATA(OTG_DATA),    
                            .OTG_ADDR(OTG_ADDR),    
                            .OTG_RD_N(OTG_RD_N),    
                            .OTG_WR_N(OTG_WR_N),    
                            .OTG_CS_N(OTG_CS_N),
                            .OTG_RST_N(OTG_RST_N)
    );
	 
	// Mouse controls 
	
	logic Write;
	logic Left, Middle, Right; // left to draw, right to erase
	logic [7:0] WritePixelKey, WritePixel;
	logic [9:0] WriteX, WriteY; // we make two xs and ys to relief computational burden when using WX and WY.
	logic [9:0] mx, my;
	int ex, ey; // to store overflows
	
	assign ex = mx << 2;
	assign ey = my << 2;
	assign Write = (Left || Right);
	assign WritePixel = Right ? 8'd0 : WritePixelKey;
	
	always_comb begin
	
		if( ex >= 511 )
			WriteX = 10'd511;
		else
			WriteX = ex[9:0];
			
		if ( ey >= 478 )
			WriteY = 10'd0;
		else
			WriteY = 10'd479 - ey[9:0];
	end
	
	logic key_change;
	always_ff @ (posedge Clk) begin
		if( keycode == 0 )
			key_change <= 1;
		else
			key_change <= 0;
	end
	
	always_ff @ (posedge Clk) begin
		if( Reset )
			WritePixelKey <= 0;
			
		else if(keycode == 30)
			WritePixelKey <= 1;
			
		else if(keycode == 31)
			WritePixelKey <= 2;
			
		else if((keycode == 40) & (WritePixelKey < 60) & key_change) //Enter
			WritePixelKey <= WritePixelKey + 8'd1;
			
		else if((keycode == 40) & (WritePixelKey >= 60) & key_change)
			WritePixelKey <= 8'd4;
	end
	
	 // Mouse file that Altera graciously provided to me in the last minute
	 ps2 U1(.iSTART(KEY[2]),  //press the button for transmitting instrucions to device;
           .iRST_n(KEY[0]),  //global reset signal;
           .iCLK_50(CLOCK_50),  //clock source;
           .PS2_CLK(PS2_CLK), //ps2_clock signal inout;
           .PS2_DAT(PS2_DAT), //ps2_data  signal inout;
           .oLEFBUT(Left),  //left button press display;
           .oRIGBUT(Right),  //right button press display;
           .oMIDBUT(Middle),  //middle button press display;
           .mx(mx[7:0]),
			  .my(my[7:0])); //higher SEG of mouse displacement display for Y axis.
	
	/* Outputs X and Y coordinates to draw on VGA */
	vga_controller VGA(	.Clk(Clk),
								.Reset(Reset),
								.hs(VGA_HS),
								.vs(VGA_VS),
								.pixel_clk(VGA_CLK),
								.blank(VGA_BLANK_N),
								.sync(VGA_SYNC_N),
								.DrawX(DrawX),
								.DrawY(DrawY)
							);
	
	logic AVL_WAIT_REQUEST;
	/*
	DijkstraCore DijkstraCore (
    .Clk, .Reset, .Run,
	 .VGA_CLK,
	 //input logic VGA_CLK,
    .StartPoint, .EndPoint,
	 
	 .done,	// finished flag
	 
	 .AVL_READDATA,	// Data from PixelOCM
	 .AVL_WAIT_REQUEST,
	 .AVL_READ, .AVL_WRITE, .AVL_CS,  // Control to PixelOCM
	 .AVL_BYTE_EN,
    .AVL_ADDRESS, // Access address to PixelOCM
	 .AVL_WRITEDATA  // To write path to PixelOCM
);

PixelRender PR
(
	.Clk, .Reset, .blank(VGA_BLANK_N), .Run,
	.VGA_CLK,
	.WE, .RE_OCM,
	
	.WritePixel,
	.WriteX, .WriteY,
	.DrawX, .DrawY,
	
	.VGA_R, .VGA_G, .VGA_B,	 // Colors for the VGA
	.StartPoint, .EndPoint,
	
	// For Dijkstra
	.AVL_READ, .AVL_WRITE, .AVL_CS,
	.AVL_BYTE_EN,
	.AVL_WRITEDATA,
	.AVL_ADDRESS,
	
	.AVL_WAIT_REQUEST,
	.AVL_READDATA
);*//*
soc				  SoC(  	.clk_clk(Clk),         
									.reset_reset_n(1'b1),    // Never reset NIOS
								  
								    // SDRAM
									.sdram_wire_addr(DRAM_ADDR), 
									.sdram_wire_ba(DRAM_BA),   
									.sdram_wire_cas_n(DRAM_CAS_N),
									.sdram_wire_cke(DRAM_CKE),  
									.sdram_wire_cs_n(DRAM_CS_N), 
									.sdram_wire_dq(DRAM_DQ),   
									.sdram_wire_dqm(DRAM_DQM),  
									.sdram_wire_ras_n(DRAM_RAS_N),
									.sdram_wire_we_n(DRAM_WE_N), 
									.sdram_clk_clk(DRAM_CLK),
								  
								    // Keyboard
									.keycode_export(keycode),  
									.otg_hpi_address_export(hpi_addr),
									.otg_hpi_data_in_port(hpi_data_in),
									.otg_hpi_data_out_port(hpi_data_out),
									.otg_hpi_cs_export(hpi_cs),
									.otg_hpi_r_export(hpi_r),
									.otg_hpi_w_export(hpi_w),
									.otg_hpi_reset_export(hpi_reset));*/

	soc				  SoC(  	.clk_clk(Clk),         
									.reset_reset_n(1'b1),    // Never reset NIOS
								  
								    // SDRAM
									.sdram_wire_addr(DRAM_ADDR), 
									.sdram_wire_ba(DRAM_BA),   
									.sdram_wire_cas_n(DRAM_CAS_N),
									.sdram_wire_cke(DRAM_CKE),  
									.sdram_wire_cs_n(DRAM_CS_N), 
									.sdram_wire_dq(DRAM_DQ),   
									.sdram_wire_dqm(DRAM_DQM),  
									.sdram_wire_ras_n(DRAM_RAS_N),
									.sdram_wire_we_n(DRAM_WE_N), 
									.sdram_clk_clk(DRAM_CLK),
								  
								    // Keyboard
									.keycode_export(keycode),  
									.otg_hpi_address_export(hpi_addr),
									.otg_hpi_data_in_port(hpi_data_in),
									.otg_hpi_data_out_port(hpi_data_out),
									.otg_hpi_cs_export(hpi_cs),
									.otg_hpi_r_export(hpi_r),
									.otg_hpi_w_export(hpi_w),
									.otg_hpi_reset_export(hpi_reset),
								  
								    // Dijkstra Core       
									.conduit_startpoint (StartPoint), 
									.conduit_endpoint   (EndPoint),   
									.conduit_done       (done),  
									.conduit_run        (Run),
									.vga_clk_dc_clk      (VGA_CLK), 
									
									 // Pixel Render
									.draw_control_re_ocm      (RE_OCM),    
									.draw_control_writepixel  (WritePixel), 
									.draw_control_writex      (WriteX),     
									.draw_control_writey      (WriteY),  
									.draw_control_drawx       (DrawX),      
									.draw_control_drawy       (DrawY),     
									.draw_control_startp      (StartPoint),     
									.draw_control_endp        (EndPoint),    
									.draw_control_we          (WE),   
									.draw_control_run         (Run),
		
									.vga_clk_pr_clk             (VGA_CLK),         
									.vga_control_red          (VGA_R),        
									.vga_control_green        (VGA_G),      
									.vga_control_blue         (VGA_B),   
									.vga_control_blank        (VGA_BLANK_N)    
								  );
										
	Control Control(.Clk, .Reset, .check, .valid, .done, .Run);
	/* Hexdrivers for color selection */
   HexDriver hex_inst_0 (WritePixel[3:0], HEX0);
   HexDriver hex_inst_1 (WritePixel[7:4], HEX1);
endmodule