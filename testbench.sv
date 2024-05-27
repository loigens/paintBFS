module testbench();
	
timeunit 10ns;
timeprecision 1ns;

	
logic 				CLOCK_50;
logic   	[3:0]  	KEY;
logic 				Write;
logic 	[7:0] 	WritePixel;
logic 	[9:0] 	WriteX, WriteY;
//logic [9:0] read_addr, write_addr;
logic [5:0] DrawPixelX, DrawPixelY, WritePixelX, WritePixelY;
//logic [7:0] PixelSelect;
logic WE_OCM, RE_OCM;
logic [31:0] data, q;

logic [11:0] potential_addr;

logic [9:0] draw_addr;
logic [11:0] pop_node;
logic node_out;
logic empty;
/*
// SRAM Interface
wire 		[15:0] 	SRAM_DQ;	  // Data to/from SRAM
logic	   [19:0] 	SRAM_ADDR;	  // Addressing of the SRAM
logic             SRAM_CE_N, 	  // SRAM control signals
						SRAM_UB_N, 	  // Activates 15:8
						SRAM_LB_N, 	  // Activates 7:0
						SRAM_OE_N, 
						SRAM_WE_N;	*/	

// VGA Interface
logic        		VGA_CLK,      //VGA Clock
						VGA_SYNC_N,   //VGA Sync signal
						VGA_BLANK_N,  //VGA Blank signal
						VGA_VS,       //VGA vertical sync signal
						VGA_HS;       //VGA horizontal sync signal
							
logic 	[7:0]  	VGA_R,        //VGA Red
						VGA_G,        //VGA Green
						VGA_B;        //VGA Blue
						
							
// CY7C67200 Interface
wire  	[15:0] 	OTG_DATA;     //CY7C67200 Data bus 16 Bits
logic 	[1:0]  	OTG_ADDR;     //CY7C67200 Address 2 Bits

logic        		OTG_CS_N,     //CY7C67200 Chip Select
						OTG_RD_N,     //CY7C67200 Write
						OTG_WR_N,     //CY7C67200 Read
						OTG_RST_N,    //CY7C67200 Reset
						OTG_INT;      //CY7C67200 Interrupt

// SDRAM Interface for Nios II Software
logic [12:0] 		DRAM_ADDR;    //SDRAM Address 13 Bits
wire  [31:0] 		DRAM_DQ;      //SDRAM Data 32 Bits
logic [1:0]  		DRAM_BA;      //SDRAM Bank Address 2 Bits
logic [3:0]  		DRAM_DQM;     //SDRAM Data Mast 4 Bits
logic        		DRAM_RAS_N,   //SDRAM Row Address Strobe
						DRAM_CAS_N,   //SDRAM Column Address Strobe
						DRAM_CKE,     //SDRAM Clock Enable
						DRAM_WE_N,    //SDRAM Write Enable
						DRAM_CS_N,    //SDRAM Chip Select
						DRAM_CLK;      //SDRAM Clock


logic [9:0] DrawX, DrawY;
logic [12:0] Start, End;
logic traced, found_end;
logic LD_NEIGHBORS;
logic [6:0]  		HEX0, HEX1;
//logic write_queue;
toplevel toplevel(.*);
logic [4:0] State;
logic [11:0] trace_addr_data, trace_addr, last_addr_data, last_addr;
logic [7:0] temp_data;
always begin
#1
	DrawX = toplevel.DrawX;
	DrawY = toplevel.DrawY;
	DrawPixelX = toplevel.Render.DrawPixelX;
	DrawPixelY = toplevel.Render.DrawPixelY;
	WritePixelX = toplevel.Render.WritePixelX;
	WritePixelY = toplevel.Render.WritePixelY;
	Start = toplevel.StartPoint;
	End = toplevel.EndPoint;
	data = toplevel.Render.data;
	q = toplevel.Render.q;
	WE_OCM = toplevel.Render.WE_OCM;
	RE_OCM = toplevel.RE_OCM;
	//PixelSelect = toplevel.Render.PixelSelect;
	//read_addr = toplevel.Render.read_addr;
	//write_addr = toplevel.Render.write_addr;
	State = toplevel.Algorithm.State;
	traced = toplevel.Algorithm.traced;
	found_end = toplevel.Algorithm.found_end;
	//write_queue = toplevel.Algorithm.write_queue;
	pop_node = toplevel.Algorithm.pop_node;
	empty = toplevel.Algorithm.empty;
	trace_addr_data = toplevel.Algorithm.trace_addr_data;
	trace_addr = toplevel.Algorithm.trace_addr;
	potential_addr = toplevel.Algorithm.potential_addr;
	last_addr = toplevel.Algorithm.last_addr;
	last_addr_data = toplevel.Algorithm.last_addr_data;
	node_out = toplevel.Algorithm.node_out;
	temp_data = toplevel.Algorithm.temp_data;
	LD_NEIGHBORS = toplevel.Algorithm.LD_NEIGHBORS;
	draw_addr = toplevel.Render.draw_addr;
end

always begin : CLOCK_GENERATION 
#1 CLOCK_50 = ~CLOCK_50;
end

initial begin: CLOCK_INITIALIZATION 
	CLOCK_50 = 0;
end

initial begin : RUN
		KEY[1] = 1;
		
	   KEY[0] = 0;
	#2 KEY[0] = 1;
	
	#10 Write = 1;
	    WritePixel = 1; // Start
	    WriteX = 60; // tile 7
	    WriteY = 0;
	#11 Write = 0;
	
	#10 Write = 1;
		 WritePixel = 2; // End
	    WriteX = 30; // tile 3
	    WriteY = 0;
	#11 Write = 0;
	
	#10 Write = 1;
		 WritePixel = 4; // obstacle
	    WriteX = 34; // tile 4
	    WriteY = 0;
	#11 Write = 0;
	
	#5 KEY[1] = 0;
	#1	KEY[0] = 1;
	
end

endmodule
	




























