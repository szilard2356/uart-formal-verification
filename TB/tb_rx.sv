// -----------------------------------------------------------------------------
// Module:      [tb_rx]
// Description: [White Box Verification of the RX module]
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_mismatch;
    reg        clk;
    reg        rst;
    wire [7:0] data;
    wire       rx_busy;
    reg        parity; //i_parity input
    reg        rx;
    wire       parity_err;
    wire       frame_err;

    localparam       DIVISOR = 401;
    localparam int   DATA_BITS = 8;
    localparam logic PARITY_EN = 1;
    localparam int   STOP_BITS = 2;

    localparam time CLK_T = 20ns;
    localparam time BIT_TIME = 13*DIVISOR*CLK_T;
    localparam time BIT_TIME_FASTER = BIT_TIME - ((BIT_TIME * 30)/1000);
    localparam time BIT_TIME_SLOWER = BIT_TIME + ((BIT_TIME * 15)/1000);



    logic expected_parity;
    integer random_seed;
    logic[7:0] random_data;
    logic random_parity;

uart_rx #(
    .P_DIVISOR(DIVISOR),
    .P_DATA_BITS(DATA_BITS),
    .P_PARITY(PARITY_EN),
    .P_STOP_BIT(STOP_BITS)
)
uut(
    .i_clk(clk),
    .i_rst(rst),
    .o_data(data),
    .o_rx_busy(rx_busy),
    .i_parity(parity),
    .o_parity_err(parity_err),
    .o_frame_err(frame_err),
    .i_rx(rx)
);

    task automatic generic_task(input logic[7:0] tx_data, input logic tx_parity, input time timer);
    begin
        rx = 0;
        #(timer);

        for(int i = 0; i < DATA_BITS; i++) begin
            rx = tx_data[i];
            #(timer);
        end

        if(PARITY_EN)begin
            rx = tx_parity;
            #(timer);
        end

        for(int i = 0; i < STOP_BITS; i++) begin
            rx = 1;
            #(timer);
        end
    end
    endtask

initial begin
    random_seed = $get_initial_random_seed;
    random_seed = $urandom(random_seed);
	clk = 0;
	rst = 0;
    rx = 1;
    parity = 0;

	#60;
	rst = 1;
    #15;
    for(int i = 0; i<25; i ++) begin
        random_parity = $urandom_range(1);
        random_data = $urandom_range(255, 0);
        expected_parity = ^random_data;
        generic_task(random_data, expected_parity, BIT_TIME);
        //wait(rx_busy == 1'b0);
        //#(BIT_TIME *2 );
    end
    $stop;
end
    always #10 clk <=~clk;
endmodule