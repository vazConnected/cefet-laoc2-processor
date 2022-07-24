/*
 * Laboratório de Arquitetura e Organização de Computadores II
 *
 * Estudantes:
 * 	Pedro Vaz
 * 	Roberto Gontijo
 *
 * Prática II - Processador
 */

/*
 * Inputs:
 * 	in = SW[7:0];
 * 	addr = SW[15:11];
 * 	wren = SW[17];
 * 	clock = KEY[0];
 *
 * Outputs:
 * 	H1|H0 : dados de saída lidos da memória ram
 * 	H3|H2 : não utilizado
 * 	H5|H4 : dados de entrada a serem escritos na memória
 * 	H7|H6 : endereço da memória para leitura ou escrita
 *
 * Mapeamento de bits:
 * 	Palavra: 16 bits
 * 	Instrucao: 10 bits
 * 	Registrador: 3 bits
 *
 * Modulos:
 * 	- 1 RAM, 1 ROM, 1 TLB (registradores totalmente associativo)
 * 	- Processador: 
 * 		- Addsub (Quartus)
 * 		- Multiplexers (Quartus)
 * 		- Banco de registradores
 *
 * Instrucoes:
 * 	- LOAD, STORE, MVNZ, MV, MVI, ADD, SUB, OR, SLT, SLL, SRL 
 * 
 */

module processor(SW, KEY, BUS, DONE, Tstep_Q, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7); 
	input [17:0] SW;
	input [3:0]  KEY;
	
	output reg [15:0] BUS;
	output reg DONE;
	output [2:0] Tstep_Q;
	output [0:6] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;
	
	reg Ain, Gin, Gout, AddSub, auxULA, wren, imediato, mem_out_flag;
	reg [15:0] in = 0; // Entrada da memória RAM
	reg [11:0] MUXsel = 0;
	reg [7:0] PC = 0;
	reg [15:0] reg_auxULA = 0;
	reg [7:0] Rout  = 0, Rin = 0; // Para armazenar referências Xreg e Yreg na forma 0b*1*
	wire [15:0] out; // Saída da memória RAM
	wire [15:0] result;
	
	integer incr_pc = 0;
	integer addr = 0;
	integer num_ciclos = 0;
	
	// Wires
	// R7 Registrador de instrução: 4b - Nome instrução | 6 bit - Número do registrador | 6 bit - Dado ou número do registrador
	wire [15:0] R[0:7];
	wire [7:0] Xreg, Yreg;
	wire [15:0] A, G;
	wire clock, run, resetn;
	wire clear;
	wire [2:0] Tstep_Q;
	wire [3:0] instruction;

	assign clock = KEY[0];
	assign run = SW[0];
	assign resetn = SW[1];

	// TLB: mapear endereco virtual para endereço físico 
	reg [15:0] tlb [0:3]; // Registradores totalmente associativos

	initial begin
		tlb[0]=16'b0001000010000000;
		tlb[1]=16'b1010000110000001;
		tlb[2]=16'b1101011011011111;
		tlb[3]=16'b0000000000000000;

		DONE = 1;
		BUS = 0;
	end

	assign clear = DONE | resetn;
	assign instruction = R[7][15:12];

	upcount Tstep (clear, clock, Tstep_Q);

	dec3to8 decX (R[7][11:6], 1'b1, Xreg);
	dec3to8 decY (R[7][5:0], 1'b1, Yreg);

	localparam timeStep0 = 3'b000;
	localparam timeStep1 = 3'b001;
	localparam timeStep2 = 3'b010;
	localparam timeStep3 = 3'b011;
	localparam timeStep4 = 3'b100;

	localparam LOAD = 4'b0001; // LOAD (LD) - LD Rx, Mem(Ry) -> Rx = Mem(Ry)
	localparam STORE = 4'b0010; // STORE (ST) - ST Rx, Ry -> Mem(Ry) = Rx
	localparam MVNZ = 4'b0011; // MVNZ - if G1!=0, Rx = Ry
	localparam MV = 4'b0100; // MV -> Rx = Ry -> address
	localparam MVI = 4'b0101; // MVI - Rx = NUM
	localparam ADD = 4'b0110; // ADD - Rx = Rx + Ry
	localparam SUB = 4'b0111; // SUB - Rx = Rx - Ry
	localparam OR = 4'b1000; // OR  - Rx = Rx || Ry
	localparam SLT = 4'b1001; // SLT - if(Rx < Ry) Rx = 1 else Rx = 0 
	localparam SLL = 4'b1010; // SLL - Rx = Rx << Ry
	localparam SRL = 4'b1011; // SRL - Rx = Rx >> Ry

	always @(posedge clock) begin
		// Inicializa variáveis
		Ain = 0;
		AddSub = 0;
		Gout = 0;
		Gin = 0;
		auxULA = 0;
		incr_pc = 0;
		Rout = 0;
		Rin = 0;
		wren = 0;
		imediato = 0;
		mem_out_flag = 0;
		DONE = 0;
		MUXsel = 0;

		case (Tstep_Q)
			// Time step 0
			timeStep0: begin
				num_ciclos = num_ciclos + 1; // 1 ciclo para buscar instrução
			end

			// Executa instrucoes - Time step 1
			timeStep1: begin
				num_ciclos = num_ciclos + 1;

				case (instruction)
					LOAD: begin
						Rout = Yreg;
					end

					STORE: begin
						Rout = Xreg;
					end

					MVNZ: begin
						if (G != 0) begin
							Rin = Xreg;
							Rout = Yreg;
						end
						DONE = 1;
					end

					MV: begin
						Rin = Xreg;
						Rout = Yreg;
						DONE = 1;
					end

					MVI: begin
						imediato = 1;
					end

					ADD, SUB, OR, SLT, SLL, SRL: begin
						Rout = Xreg; // Coloca no BUS
						Ain = 1; // Salva conteúdo do BUS no registrador A
					end
				endcase
			end

			// Executa instrucoes - Time step 2
			timeStep2: begin
				num_ciclos = num_ciclos + 1;

				case (instruction)
					LOAD: begin end

					STORE: begin
						wren = 1;
						in = BUS; // TBD: adicionar o TLB
						Rout = Yreg;
						DONE = 1;
					end

					MVI: begin
						Rin = Xreg;
						DONE = 1;
					end

					ADD: begin
						Rout = Yreg;
						Gin = 1;
					end

					SUB: begin
						Rout = Yreg;
						Gin = 1;
						AddSub = 1;
					end		

					OR,SLT, SLL, SRL: begin
						Rout = Yreg;
					end
				endcase
			end

			// Executa instrucoes - Time step 3 
			timeStep3: begin
				num_ciclos = num_ciclos + 1;

				case (instruction)
					LOAD: begin
						mem_out_flag = 1;
						Rin = Xreg;
						DONE = 1;
					end

					ADD, SUB: begin end

					OR: begin
						reg_auxULA = BUS | A;
					end

					SLT: begin
						if (A < BUS) begin
							reg_auxULA = 1;	
						end else begin
							reg_auxULA = 0;
						end
					end

					SLL: begin
						reg_auxULA = A << BUS;
					end

					SRL: begin
						reg_auxULA = A >> BUS;
					end
				endcase
			end

			// Executa instrucoes - Time step 4
			timeStep4: begin
				case (instruction)
					ADD, SUB: begin
						Gout = 1;
						Rin = Xreg;
						DONE = 1;
					end

					OR, SLT, SLL, SRL: begin
						auxULA = 1;
						Rin = Xreg;
						DONE = 1;
					end
				endcase
			end
		endcase

		if (DONE == 1) begin
			PC = PC + 1;
		end
	end

	// Ler instrução na ROM
	rom reg_7 (PC, clock, R[7]);
	
	ram ramModule (BUS, clock, in, wren, out);
	
	// Banco de registradores
	regn reg_0 (BUS, Rin[0], clock, R[0]);
	regn reg_1 (BUS, Rin[1], clock, R[1]);
	regn reg_2 (BUS, Rin[2], clock, R[2]);
	regn reg_3 (BUS, Rin[3], clock, R[3]);
	regn reg_4 (BUS, Rin[4], clock, R[4]);
	regn reg_5 (BUS, Rin[5], clock, R[5]);
	regn reg_6 (BUS, Rin[6], clock, R[6]);	

	// Registradores do módulo Addsub e auxULA
	regn reg_A (BUS, Ain, clock, A);
	regn reg_G (result, Gin, clock, G);
	
	addsub ULA (~AddSub, A, BUS, result); 

	// Definir Bus
	always @(MUXsel or Rout or Gout or auxULA or imediato or mem_out_flag) begin
		MUXsel[0] = Gout;
		MUXsel[8:1] = Rout;
		MUXsel[9] = auxULA;
		MUXsel[10] = imediato;
		MUXsel[11] = mem_out_flag;
		
		case (MUXsel)
			12'b000000000001: BUS = G;
			12'b000000000010: BUS = R[0];
			12'b000000000100: BUS = R[1];
			12'b000000001000: BUS = R[2];
			12'b000000010000: BUS = R[3];
			12'b000000100000: BUS = R[4];
			12'b000001000000: BUS = R[5];
			12'b000010000000: BUS = R[6];
			12'b000100000000: BUS = R[7];
			12'b001000000000: BUS = reg_auxULA;
			12'b010000000000: BUS = R[7][5:0]; // Imediato
			12'b100000000000: BUS = out;
		endcase
	end

	// Escrever no display de sete segmentos
	hex_ssd H0 (R[0][3:0], clock, HEX7); // Registrador 0
	hex_ssd H1 (R[1][3:0], clock, HEX6); // Registrador 1 
	hex_ssd H2 (R[2][3:0], clock, HEX5); // Registrador 2
	hex_ssd H3 (R[3][3:0], clock, HEX4); // Registrador 3
	hex_ssd H4 (R[4][3:0], clock, HEX3); // Registrador 4
	hex_ssd H5 (R[5][3:0], clock, HEX2); // Registrador 5
	hex_ssd H6 (R[6][3:0], clock, HEX1); // Registrador 6
	hex_ssd H7 (PC, clock, HEX0); // Program counter
endmodule
