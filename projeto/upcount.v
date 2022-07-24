module upcount(Clear, Clock, Q);
	input Clear, Clock;
	output [2:0] Q;
	reg [2:0] Q;

	initial begin
		Q = 0;
	end
	
	always @(posedge Clock)
		if (Clear)
			Q = 0;
		else
			Q <= Q + 1'b1;
endmodule
