module dec3to8(W, En, Y);
	input [5:0] W;
	input En;
	output [7:0] Y;
	reg [7:0] Y;

	always @(W or En) begin
		if (En == 1)
			case (W)
				6'b000000: Y = 8'b00000001;
				6'b000001: Y = 8'b00000010;
				6'b000010: Y = 8'b00000100;
				6'b000011: Y = 8'b00001000;
				6'b000100: Y = 8'b00010000;
				6'b000101: Y = 8'b00100000;
				6'b000110: Y = 8'b01000000;
				6'b000111: Y = 8'b10000000;
			endcase
		else
			Y = 8'b00000000;
	end
endmodule
