/* verilator lint_off UNUSEDSIGNAL */
`default_nettype none

module tt_um_dilithium_butterfly (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Reset handling (TinyTapeout uses active low reset)
    wire rst = !rst_n;

    // Silence unused signal warnings
    wire [7:0] _unused_inputs = {uio_in};
    wire       _unused_ena = ena;
    wire [3:0] _unused_ui = ui_in[7:4];

    // --- Input Shift Register ---
    // We need approx 76 bits:
    // mode(3) + validi(1) + aj(24) + ajlen(24) + zeta(24) = 76 bits
    // We use 80 bits for alignment/padding
    reg [79:0] input_sr; 
    
    // Controls derived from dedicated inputs
    wire shift_en  = ui_in[0]; // Pin 0: Enable shifting input data
    wire data_in   = ui_in[1]; // Pin 1: Serial Data Input
    wire load_en   = ui_in[2]; // Pin 2: Load SR into Butterfly module
    wire load_out  = ui_in[3]; // Pin 3: Load Output into Output SR
    
    // Butterfly Inputs
    reg [2:0]  mode;
    reg        validi;
    reg signed [23:0] aj;
    reg signed [23:0] ajlen;
    reg [23:0] zeta;

    // Butterfly Outputs
    wire [23:0] bj;
    wire [23:0] bjlen;
    wire        valido;

    // Instantiate the Butterfly Unit
    butterfly u_butterfly (
        .clk    (clk),
        .rst    (rst),
        .mode   (mode),
        .validi (validi),
        .aj     (aj),
        .ajlen  (ajlen),
        .zeta   (zeta),
        .bj     (bj),
        .bjlen  (bjlen),
        .valido (valido)
    );

    // Input Logic
    always @(posedge clk) begin
        if (rst) begin
            input_sr <= 0;
            mode <= 0; validi <= 0; aj <= 0; ajlen <= 0; zeta <= 0;
        end else begin
            // Shift Register Operation
            if (shift_en) begin
                input_sr <= {input_sr[78:0], data_in};
            end
            
            // Parallel Load to Core
            // Mapping: [75:73]mode, [72]valid, [71:48]aj, [47:24]ajlen, [23:0]zeta
            if (load_en) begin
                mode   <= input_sr[75:73];
                validi <= input_sr[72];
                aj     <= input_sr[71:48];
                ajlen  <= input_sr[47:24];
                zeta   <= input_sr[23:0];
            end
        end
    end

    // --- Output Shift Register ---
    // We need 49 bits: valido(1) + bj(24) + bjlen(24)
    reg [48:0] output_sr;
    
    always @(posedge clk) begin
        if (rst) begin
            output_sr <= 0;
        end else begin
            if (load_out) begin
                output_sr <= {valido, bj, bjlen};
            end else if (shift_en) begin
                output_sr <= {output_sr[47:0], 1'b0}; // Shift out MSB first
            end
        end
    end

    // Map Output SR MSB to Output Pin 0
    assign uo_out[0] = output_sr[48]; 
    assign uo_out[7:1] = 0; // Unused outputs driven low

    // Unused bidirectional pins
    assign uio_out = 0;
    assign uio_oe  = 0;

endmodule
