// -----------------------------------------------------------------------------
// Module:      [tb_tx.sv]
// Description: [Black Box Verification of the TX module given by the consultant]
// -----------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_tx;
    logic clk;
    logic rst;

    logic[7:0] data;
    logic parity; //i_parity input
    logic tx;
    logic tx_strobe;
    logic ready;
    logic error;

    localparam DIVISOR = 401;
    localparam int DATA_BITS = 8;
    localparam logic P_PARITY = 1;
    localparam int STOP_BITS = 2;

    localparam time CLK_T = 20ns;
    localparam time BIT_TIME = 13*DIVISOR*CLK_T;
    localparam time BIT_TIME_FASTER = BIT_TIME - ((BIT_TIME * 15)/1000);
    localparam time BIT_TIME_SLOWER = BIT_TIME + ((BIT_TIME * 15)/1000);

    integer random_seed;
    logic[7:0] random_data;
    logic random_parity;

uart_tx_d20_1 #(
    .P_DIVISOR(DIVISOR),
    .P_DATA_BITS(DATA_BITS),
    .P_PARITY(P_PARITY),
    .P_STOP_BIT(STOP_BITS)
)
uut(
    .i_clk(clk),
    .i_rst(rst),
    .i_data(data),
    .i_tx_strobe(tx_strobe),
    .i_parity(parity),

    .o_tx(tx),
    .o_rdy(ready),
    .o_err(error)
);

bind uut sva_uart_tx tx_sva(
    .clk(i_clk),
    .rst(i_rst),
    .tx_data(i_data),
    .tx_strobe(i_tx_strobe),
    .tx_parity(i_parity),
    .tx(o_tx),
    .ready(o_rdy),
    .err(o_err)
);

    task automatic one_packet(input logic[7:0] tx_data);
    begin
        @(negedge clk);
        data = tx_data;
        tx_strobe = 1;

        @(negedge clk);
        tx_strobe = 0;
        wait(ready == 1'b0);
        wait(ready == 1'b1);
        #(BIT_TIME * 2);
    end
    endtask

initial begin
    random_seed = $get_initial_random_seed;
    random_seed = $urandom(random_seed);
	clk = 0;
	rst = 1;
    tx_strobe = 0;
    parity = 0;
    data = 0;

	#60;
	rst = 0;
	#60;
	rst = 1;
    #10;
    for(int i = 0; i<30; i++)begin
        random_parity = $urandom_range(1);
        random_data = $urandom_range(255, 0);
        one_packet(random_data);
    end
end

always #10 clk = ~clk;

endmodule