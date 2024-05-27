module Control
(
	input Clk, Reset, check, valid, done,
	output logic Run
);


	enum logic [2:0] {DRAW, VERIFY, PROCESS} State, Next_state;
	
	always_ff @ (posedge Clk) begin
		begin
			if (Reset)
				State <= DRAW;
			else 
				State <= Next_state;
		end
	end
	
	always_comb begin
	
		// Default next state is staying at current state
		Next_state = State;
		
		
		// check -> valid -> Run
		unique case (State)
			DRAW: if( check ) Next_state = VERIFY;
			VERIFY: if( valid ) Next_state = PROCESS;
			PROCESS: if( done ) Next_state = DRAW;
		endcase
		
		case (State)
			PROCESS: Run = 1;
			default:
				Run = 0;
		endcase	 
	end
	
	
endmodule
