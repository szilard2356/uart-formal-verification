// -----------------------------------------------------------------------------
// Module:      [tb_tx_rx]
// Description: [Verification of the RX and TX module connected to eachother]
// -----------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_tx_rx;
    logic clk_tx;
    logic rst_tx;
    logic clk_rx;
    logic rst_rx;

    logic rx_busy;
    logic parity_err;
    logic frame_err;

    logic[7:0] tx_data;
    logic[7:0] rx_data;
    logic parity; //i_parity input
    logic tx;
    logic tx_strobe;
    logic ready;
    logic error;



    localparam DIVISOR_TX = 401;
    localparam DIVISOR_RX = 401;
    localparam int DATA_BITS = 8;
    localparam logic P_PARITY = 1;
    localparam int STOP_BITS = 2;

    localparam time CLK_T = 20ns;
    localparam time BIT_TIME = 13*DIVISOR_TX*CLK_T;
    localparam time BIT_TIME_FASTER = BIT_TIME - ((BIT_TIME * 15)/1000);
    localparam time BIT_TIME_SLOWER = BIT_TIME + ((BIT_TIME * 15)/1000);

    integer random_seed;
    logic[7:0] random_data;
    logic expected_parity;

    //scoreboard
    logic [7:0] expected_queue [$];
    int fail = 0;
    int passed = 0;

uart_tx_d20_1 #(
    .P_DIVISOR(DIVISOR_TX),
    .P_DATA_BITS(DATA_BITS),
    .P_PARITY(P_PARITY),
    .P_STOP_BIT(STOP_BITS)
)
uut_tx(
    .i_clk(clk_tx),
    .i_rst(rst_tx),
    .i_data(tx_data),
    .i_tx_strobe(tx_strobe),
    .i_parity(parity),

    .o_tx(tx),
    .o_rdy(ready),
    .o_err(error)
);

uart_rx #(
    .P_DIVISOR(DIVISOR_RX),
    .P_DATA_BITS(DATA_BITS),
    .P_PARITY(P_PARITY),
    .P_STOP_BIT(STOP_BITS)
)
uut_rx(
    .i_clk(clk_rx),
    .i_rst(rst_rx),
    .o_data(rx_data),
    .o_rx_busy(rx_busy),
    .i_parity(parity),
    .o_parity_err(parity_err),
    .o_frame_err(frame_err),
    .i_rx(tx)
);

sva_uart_tx_rx system_sva(
    .clk(clk_tx),
    .rst(rst_tx),
    .tx_data(tx_data),
    .tx_strobe(tx_strobe),
    .tx_parity(parity),
    .tx(tx),
    .ready(ready),
    .err(error),
    //RX
    .rx_data(rx_data),
    .busy(rx_busy),
    .rx_parity(parity),
    .parity_err(parity_err),
    .frame_err(frame_err),
    .rx(tx)
);

bind uut_tx sva_uart_tx tx_sva(
    .tb_expected_parity(expected_parity),
    .clk(i_clk),
    .rst(i_rst),
    .tx_data(i_data),
    .tx_strobe(i_tx_strobe),
    .tx_parity(i_parity),
    .tx(o_tx),
    .ready(o_rdy),
    .err(o_err)
);
    
    task automatic one_packet(input logic[7:0] in_data);
    begin
        @(negedge clk_tx);
        tx_data = in_data;
        tx_strobe = 1;

        @(negedge clk_tx);
        tx_strobe = 0;
        wait(ready == 1'b0);
        wait(ready == 1'b1);
        #(BIT_TIME * 2);
    end
    endtask

initial begin
    random_seed = $get_initial_random_seed;
    random_seed = $urandom(random_seed);
	clk_rx = 0;
    clk_tx = 0;
	rst_rx = 1;
    rst_tx = 1;
    tx_strobe = 0;
    parity = 0;
    tx_data = 0;
    //SCOREBOARD
    // Asynchronous Scoreboard thread: Independently monitors the rx_busy flag 
    // to compare received data against the expected queue in real-time.
    fork
        begin : scoreboard
            forever begin
                @(negedge rx_busy);
                if(expected_queue.size() > 0) begin
                    logic [7:0] expected_data;
                    expected_data = expected_queue.pop_front();
                    if(rx_data != expected_data) begin
                        $display("FAIL - Expected: %h | Received: %h", expected_data, rx_data);
                        fail++;
                    end else begin
                        //$display("PASSED");
                        passed++;
                    end
                end
            end
        end   
    join_none

    //Classic waveform verification:
	#60;
	rst_rx = 0;
    rst_tx = 0;
	#60;
    rst_rx = 1;
    rst_tx = 1;
    #10;
        for(int i = 0; i<100; i++)begin
        random_data = $urandom_range(255, 0);
        expected_parity = ^random_data;
        expected_queue.push_back(random_data);
        one_packet(random_data);
    end
    #100
    $display("FINISHED");
    $display("Passed: %d", passed);
    $display("Failed: %d", fail);
    $stop;
end

always #10 clk_rx = ~clk_rx;
always #10 clk_tx = ~clk_tx;

endmodule

