	module DijkstraCore (
    input logic Clk, Reset, Run,
	 input logic VGA_CLK,
	 //input logic VGA_CLK,
    input logic [12:0] StartPoint, EndPoint,
	 
	 output logic done,	// finished flag
	 
	 /* PixelOCM */
	 input logic [31:0] AVL_READDATA,	// Data from PixelOCM
	 input logic AVL_WAIT_REQUEST,
	 output logic AVL_READ, AVL_WRITE, AVL_CS,  // Control to PixelOCM
	 output logic [3:0] AVL_BYTE_EN,
    output logic [9:0] AVL_ADDRESS, // Access address to PixelOCM
	 output logic [31:0] AVL_WRITEDATA  // To write path to PixelOCM
);
	assign AVL_CS = 1'b1; // always turn on CS
	
	enum  logic [4:0] {
		 RESET, // 0
		 IDLE,  // 1
		 INIT,  // 2
		 LOAD_END, // 3
		 BOUND_CHECK1A, // 4
		 BOUND_CHECK1B, // 5
		 BOUND_CHECK2A, // 6
		 BOUND_CHECK2B, // 7
		 BOUND_CHECK3A, // 8
		 BOUND_CHECK3B, // 9
		 BOUND_CHECK4A, // 10
		 BOUND_CHECK4B, // 11
		 VISIT_NODES1, // 12
		 VISIT_NODES2, // 13
		 VISIT_NODES3, // 14
		 VISIT_NODES4, // 15
		 CHECK_NEIGHBORS, // 16
		 DONE_BFS, // 17
		 LOAD_PREV1, // 18
		 LOAD_PREV2, // 19
		 TRACE_PATH, // 20
		 FINISH // 21
	} State, Next_state;
	
	logic [11:0] temp_addr, temp_pos, potential_addr;
	logic [31:0] temp_data;
	
	/* For Queue */
	logic [11:0] load_node, pop_node;
	logic read_queue, write_queue, clear_queue, empty;
	
	/* for DijkstraOCM */
	logic [11:0] data, qBFS;
	logic [11:0] wraddress, rdaddress;
	logic WE_ALGO, RE_ALGO;
	
	/* start and end points as X+64*Y */
	logic [11:0] end_addr, start_addr;
	
	assign end_addr = {6'd0,EndPoint[12:7]}  + {EndPoint[6:1],6'd0};
	assign start_addr = {6'd0,StartPoint[12:7]}  + {StartPoint[6:1],6'd0};
	
	/* OCM STORES THE NODES AS ADDRESSES OF X+Y*64 */
	Dijkstra	DijkstraOCM( .clock ( Clk ),
								 .data ( data ),
								 .rdaddress ( rdaddress ),
								 .wraddress ( wraddress ),
								 .wren ( WE_ALGO ),
								 .rden ( RE_ALGO ),
								 .q ( qBFS ) );
	
	/* QUEUE STORES THE NODES AS X+Y*64 */
	queue	queue(       .clock ( Clk ),
							 .data ( load_node ),
							 .rdreq ( read_queue ),
							 .sclr ( clear_queue ),
							 .wrreq ( write_queue ),
							 .q ( pop_node ),
							 .empty( empty )
							);
							
	/* visited table */
	logic [11:0] node_addr;
	logic node_in, node_out;
	logic WE_node, RE_node;
	
	visited	visitedOCM( .clock ( Clk ),
								.rdaddress ( node_addr ),
								.wraddress ( node_addr ),
								.data ( node_in ),
								.wren ( WE_node ),
								.rden ( RE_node ),
								.q ( node_out )
								);

							
	/* found_end register */
	logic found_end, LD_END;
	
	/* dead_end register */
	logic dead_end, LD_DEAD;
	
	always_ff @ (posedge Clk) begin
		if( State == RESET )
			dead_end <= 1'b0;
		else if( LD_DEAD )
			dead_end <=1'b1;
	end
	
	always_ff @ (posedge Clk) begin
		if( State == RESET )
			found_end <= 1'b0;
		else if( LD_END )
			found_end <= 1'b1;
	end
										 
	/* tracing register */
	logic traced, LD_TRACED;
	
	always_ff @ (posedge Clk) begin
		if( State == RESET )
			traced <= 1'b0;
		else if( LD_TRACED )
			traced <= 1'b1;
	end
								
	
	/* done register */
	logic LD_DONE;	
	
	always_ff @ (posedge Clk) begin
		if( State == RESET )
			done <= 1'b0;
		else if( LD_DONE )
			done <= 1'b1;
	end					
								
	
	/* for neighbors register */
	logic LD_NEIGHBORS;
	logic [1:0] neighbors_index;
	logic [12:0] neighbors[4];
	logic [12:0] neighbors_data;
	
	always_ff @ (posedge Clk) begin
		if ( (State == RESET) || (State == CHECK_NEIGHBORS) )
			for( int i=0; i<4; i++ )
				neighbors[i][0] <= 1'b0;
		else if( LD_NEIGHBORS )
			neighbors[neighbors_index] <= neighbors_data;
	end
	
	/* last_addr registers */
	logic [11:0] last_addr, last_addr_data; // used during traceback
	logic LD_last_addr;
	
	always_ff @ (posedge Clk) begin
		if( State == RESET )
			last_addr <= 0;
		else if( LD_last_addr )
			last_addr <= last_addr_data;
	end
										  
	/* trace_addr register */
	logic [11:0] trace_addr, trace_addr_data; // used during traceback
	logic LD_trace_addr;
	
	always_ff @ (posedge Clk) begin
		if( State == RESET )
			trace_addr <= 0;
		else if( LD_trace_addr )
			trace_addr <= trace_addr_data;
	end
	
	/* State register */
	always_ff @ (posedge VGA_CLK) begin
		if( Reset )
			State <= RESET;
		else
			State <= Next_state;
	end
	
	always_comb begin
		// Default next state is staying at current state
		Next_state = State;
		
		/* States goes like this:
		 *
		 * IDLE: Dont do anything, this stage is during the DRAW phase
		 * INIT: Loads the endpoint into the visited array, queue FIFO, and DijkstraOCM (PROCESS phase)
		 * LOAD_END: Dequeue the endpoint from the queue
		 * BOUND_COND: Determine all boundary conditions, interfaces with PixelOCM
		 * BOUND_CHECK: Load boundary conditions into neighbor array
		 * VISIT_NODES: Mark all neighbors as visited nodes. If we visit the start node, set found_end flag
		 * CHECK_NEIGHBORS: Dequeue a node. Goes to BOUND_COND otherwise it goes to DONE_BFS
		 * DONE_BFS: BFS is done, prepare for storing path to PixelOCM
		 * LOAD_PREV: Load the previous node n-1 from the nth node. Sets the traced flag.
		 * TRACE_PATH: Load the path data 
		 */
		case (State)
			RESET				: Next_state = IDLE;
			IDLE				: if( Run ) 
										Next_state = INIT;						
			INIT				: Next_state = LOAD_END;
			LOAD_END			: Next_state = BOUND_CHECK1A;
			BOUND_CHECK1A  : Next_state = BOUND_CHECK1B;
			BOUND_CHECK1B  : Next_state = BOUND_CHECK2A;
			BOUND_CHECK2A  : Next_state = BOUND_CHECK2B;
			BOUND_CHECK2B  : Next_state = BOUND_CHECK3A;
			BOUND_CHECK3A  : Next_state = BOUND_CHECK3B;
			BOUND_CHECK3B  : Next_state = BOUND_CHECK4A;
			BOUND_CHECK4A  : Next_state = BOUND_CHECK4B;
			BOUND_CHECK4B	: Next_state = VISIT_NODES1;
			VISIT_NODES1	: Next_state = VISIT_NODES2;
			VISIT_NODES2	: if( found_end )
										Next_state = DONE_BFS;
								  else
										Next_state = VISIT_NODES3;
			VISIT_NODES3	: if( found_end )
										Next_state = DONE_BFS;
								  else
										Next_state = VISIT_NODES4;
			VISIT_NODES4	: if( found_end ) Next_state = DONE_BFS;
								  else if( dead_end ) Next_state = FINISH;
								  else	Next_state = CHECK_NEIGHBORS;
			CHECK_NEIGHBORS: Next_state = BOUND_CHECK1A;
			DONE_BFS			: Next_state = LOAD_PREV1;
			LOAD_PREV1 		: Next_state = LOAD_PREV2;
			LOAD_PREV2		: if( traced ) Next_state = FINISH;
								  else Next_state = TRACE_PATH;
			TRACE_PATH		: Next_state = LOAD_PREV1;
			FINISH			: if( (~Run) && Reset ) 
										Next_state = RESET;
			default			: Next_state = RESET;
		endcase
	end
	
	// End -> Start
	logic [11:0] address_compute; // address_compute stores address computed data for later use
	always_comb begin
		AVL_READ = 1'b0;
		AVL_WRITE = 1'b0;
		AVL_BYTE_EN = 4'd0;
		WE_ALGO = 1'b0;
		RE_ALGO = 1'b0;
		read_queue = 1'b0;
		write_queue = 1'b0;
		clear_queue = 1'b0;
		LD_END = 1'b0;
		LD_TRACED = 1'b0;
		LD_DONE = 1'b0;
		LD_DEAD = 1'b0;
		LD_trace_addr = 1'b0;
		LD_last_addr = 1'b0;
		LD_NEIGHBORS = 1'b0;
		WE_node = 1'b0;
		RE_node = 1'b0;
		
		node_in = 1'b0;
		node_addr = 12'd0;
		potential_addr = 0;
		data = 0;
		wraddress = 0;
		rdaddress = 0;
		load_node = 0;
		AVL_ADDRESS = 0;
		last_addr_data = 0;
		trace_addr_data = 0;
		temp_addr = 0;
		temp_data = 0;
		temp_pos = 0;
		neighbors_index = 0;
		neighbors_data = 0;
		AVL_WRITEDATA = 0;
		
		case (State)
			default: ;
			RESET: clear_queue = 1'b1;
			
			INIT: begin // Load the endpoint into the queue
			
						/* mark as visited */
						wraddress = end_addr; // in DijkstraOCM
						data = end_addr;
						WE_ALGO = 1'b1;
						
						node_addr = end_addr; // in visitedOCM
						node_in = 1'b1;
						WE_node = 1'b1;
						
						/* add to FIFO */
						load_node = end_addr;
						write_queue = 1'b1;
					end
			
			LOAD_END: 	begin
								/* dequeue "End" from FIFO to "pop_node" */
								WE_ALGO = 1'b0;
								write_queue = 1'b0;
								read_queue = 1'b1;
							end
			
			/*     0
			 *    3x1
			 *     2
			 */ 				 
			BOUND_CHECK1A: begin
									if( pop_node > 63 ) begin // up
										potential_addr = pop_node - 12'd64;
										AVL_ADDRESS = potential_addr[11:2];
										AVL_READ = 1'b1;
										node_addr = potential_addr;
										RE_node = 1'b1;
									end
								end
								
			BOUND_CHECK1B: begin
									if( pop_node > 63 ) begin 
										potential_addr = pop_node - 12'd64;
										unique case( potential_addr[1:0] )
												0: temp_data = AVL_READDATA[7:0];
												1: temp_data = AVL_READDATA[15:8];
												2: temp_data = AVL_READDATA[23:16];
												3: temp_data = AVL_READDATA[31:24];
										endcase
										
										if( (temp_data < 3) & (node_out == 1'b0) ) begin
											LD_NEIGHBORS = 1'b1;
											neighbors_index = 2'd0;
											neighbors_data = {potential_addr,1'b1};
										end
									end
								end
								
			BOUND_CHECK2A: begin
									temp_pos = pop_node - {pop_node[11:6], 6'd0}; // Rshift pop_node 6x, Lshift pop_node 6x
									if( temp_pos < 63 ) begin // right
										potential_addr = pop_node + 12'd1;
										AVL_ADDRESS = potential_addr[11:2];
										AVL_READ = 1'b1;
										node_addr = potential_addr;
										RE_node = 1'b1;
									end
								end				
			BOUND_CHECK2B: begin
									temp_pos = pop_node - {pop_node[11:6], 6'd0};
									if( temp_pos < 63 ) begin
										potential_addr = pop_node + 12'd1;
										unique case( potential_addr[1:0] )
												0: temp_data = AVL_READDATA[7:0];
												1: temp_data = AVL_READDATA[15:8];
												2: temp_data = AVL_READDATA[23:16];
												3: temp_data = AVL_READDATA[31:24];
										endcase
										
										if( (temp_data < 3) & (node_out == 1'b0) ) begin
											LD_NEIGHBORS = 1'b1;
											neighbors_index = 2'd1;
											neighbors_data = {potential_addr,1'b1};
										end
									end
								end
								
			BOUND_CHECK3A: if( pop_node < 3776 ) begin // down
									potential_addr = pop_node + 12'd64;
									AVL_ADDRESS = potential_addr[11:2];
									AVL_READ = 1'b1;
									node_addr = potential_addr;
									RE_node = 1'b1;
								end
								
			BOUND_CHECK3B: begin
									if( pop_node < 3776 ) begin
										potential_addr = pop_node + 12'd64;
										unique case( potential_addr[1:0] )
												0: temp_data = AVL_READDATA[7:0];
												1: temp_data = AVL_READDATA[15:8];
												2: temp_data = AVL_READDATA[23:16];
												3: temp_data = AVL_READDATA[31:24];
										endcase
											
										if( (temp_data < 3) & (node_out == 1'b0) ) begin
											LD_NEIGHBORS = 1'b1;
											neighbors_index = 2'd2;
											neighbors_data = {potential_addr,1'b1};
										end
									end
								end
								
			BOUND_CHECK4A: begin
									temp_pos = pop_node - {pop_node[11:6], 6'd0}; // Rshift pop_node 6x, Lshift pop_node 6x
									if( temp_pos > 0 ) begin // left
										potential_addr = pop_node - 12'd1;
										AVL_ADDRESS = potential_addr[11:2];
										AVL_READ = 1'b1;
										node_addr = potential_addr;
										RE_node = 1'b1;
									end					
								end
			BOUND_CHECK4B: begin
									temp_pos = pop_node - {pop_node[11:6], 6'd0};
									if( temp_pos > 0 ) begin
										potential_addr = pop_node - 12'd1;
										unique case( potential_addr[1:0] )
												0: temp_data = AVL_READDATA[7:0];
												1: temp_data = AVL_READDATA[15:8];
												2: temp_data = AVL_READDATA[23:16];
												3: temp_data = AVL_READDATA[31:24];
										endcase
										
										if( (temp_data < 3) & (node_out == 1'b0) ) begin
											LD_NEIGHBORS = 1'b1;
											neighbors_index = 2'd3;
											neighbors_data = {potential_addr,1'b1};
										end
									end
								end
								
			VISIT_NODES1:	if( neighbors[0][0] ) begin
										
									/* add to FIFO */
									load_node = neighbors[0][12:1];
									write_queue = 1'b1;
									
									/* add to DijkstraOCM and visitedOCM */
									wraddress = neighbors[0][12:1]; // current node
									data = pop_node; // stores the previous node
									WE_ALGO = 1'b1;
									
									node_in = 1'b1;
									node_addr = neighbors[0][12:1]; // mark neighbouring node as visited
									WE_node = 1'b1;
									
									if( neighbors[0][12:1] == start_addr )
										LD_END = 1'b1;
								end
								
			VISIT_NODES2:	if( neighbors[1][0] ) begin
										
									/* add to FIFO */
									write_queue = 1'b0;
									load_node = neighbors[1][12:1];
									write_queue = 1'b1;
									
									/* add to DijkstraOCM and visitedOCM */
									wraddress = neighbors[1][12:1]; // current node
									data = pop_node; // stores the previous node
									WE_ALGO = 1'b1;
									
									node_in = 1'b1;
									node_addr = neighbors[1][12:1]; // mark neighbouring node as visited
									WE_node = 1'b1;
									
									if( neighbors[1][12:1] == start_addr )
										LD_END = 1'b1;
								end
			
			VISIT_NODES3:	if( neighbors[2][0] ) begin
										
									/* add to FIFO */
									write_queue = 1'b0;
									load_node = neighbors[2][12:1];
									write_queue = 1'b1;
									
									/* add to DijkstraOCM and visitedOCM */
									wraddress = neighbors[2][12:1]; // current node
									data = pop_node; // stores the previous node
									WE_ALGO = 1'b1;
									
									node_in = 1'b1;
									node_addr = neighbors[2][12:1]; // mark neighbouring node as visited
									WE_node = 1'b1;
									
									if( neighbors[2][12:1] == start_addr )
										LD_END = 1'b1;
								end
								
			VISIT_NODES4:	begin
									if( neighbors[3][0] ) begin
										
										/* add to FIFO */
										write_queue = 1'b0;
										load_node = neighbors[3][12:1];
										write_queue = 1'b1;
										
										/* add to DijkstraOCM and visitedOCM */
										wraddress = neighbors[3][12:1]; // current node
										data = pop_node; // stores the previous node
										WE_ALGO = 1'b1;
										
										node_in = 1'b1;
										node_addr = neighbors[3][12:1]; // mark neighbouring node as visited
										WE_node = 1'b1;
										
										if( neighbors[3][12:1] == start_addr )
											LD_END = 1'b1;
									end else if( empty )
										LD_DEAD = 1'b1;
								end
								
			CHECK_NEIGHBORS: begin
									 /* dequeue node from FIFO */
									 read_queue = 1'b1;
								  end
			
			DONE_BFS: begin
							last_addr_data = start_addr;
							LD_last_addr = 1'b1;
						 end
			
			LOAD_PREV1: begin
							 rdaddress = last_addr;
							 RE_ALGO = 1'b1;
						  end
			
			LOAD_PREV2: begin
							 trace_addr_data = qBFS;
							 LD_trace_addr = 1'b1;
							 
							 if( trace_addr_data == end_addr ) LD_TRACED = 1'b1;
							end
			
			TRACE_PATH:	begin
								AVL_ADDRESS = trace_addr[11:2];
								unique case(trace_addr[1:0]) // same as the BE_OCM case
									0: begin
											AVL_BYTE_EN = {3'd0, 1'b1};
											AVL_WRITEDATA = {24'd0, 8'd3};
										end
										
									1: begin
											AVL_BYTE_EN = {2'd0, 1'b1, 1'b0};
											AVL_WRITEDATA = {16'd0, 8'd3, 8'd0};
										end
										
									2: begin	
											AVL_BYTE_EN = {1'b0, 1'b1, 2'd0};
											AVL_WRITEDATA = {8'd0, 8'd3, 16'd0};
										end
										
									3: begin
											AVL_BYTE_EN = {1'b1, 3'd0};
											AVL_WRITEDATA = {8'd3, 24'd0};
										end
								endcase
								AVL_WRITE = 1'b1;
								last_addr_data = trace_addr;
								LD_last_addr = 1'b1;
							end
			
			FINISH:	LD_DONE = 1'b1;
		endcase
	end

endmodule
