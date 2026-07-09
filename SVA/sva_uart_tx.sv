// -----------------------------------------------------------------------------
// Module:      [sva_uart_tx]
// Description: [SystemVerilog Assertions for the testbench of the TX module]
// -----------------------------------------------------------------------------

module sva_uart_tx #(
    parameter int P_DIVISOR = 401,
    parameter int P_DATA_BITS = 8,
    parameter int P_PARITY = 1,
    parameter int P_STOP_BIT = 2,
    localparam int BAUD_TIME = 13*P_DIVISOR,
    localparam int BITS_TO_STOP = 1 + P_DATA_BITS + P_PARITY,
    localparam int BITS_TO_PARITY = 1 + P_DATA_BITS,
    localparam int TIME_TO_STOP = BITS_TO_STOP * BAUD_TIME,
    localparam int TIME_TO_PARITY = BITS_TO_PARITY * BAUD_TIME,
    localparam int TOTAL_BITS = BITS_TO_STOP + P_STOP_BIT,
    localparam int PACKET_TIME = BAUD_TIME*TOTAL_BITS
)
(
    input clk,
    input rst,
    input[P_DATA_BITS - 1:0] tx_data,
    input tx_strobe,
    input tx_parity,
    input tx,
    input ready,
    input err,
    input tb_expected_parity
);


//------------------------------------------------------------
//Default clocking and default reset
//------------------------------------------------------------
default clocking cb_sva @(posedge clk); endclocking
default disable iff(rst == 1'b0);

//------------------------------------------------------------
//Properties
//------------------------------------------------------------

//1. property: p_strobe_starts_tx
property p_strobe_starts_tx;
    tx_strobe |=> (ready == 1'b0);
endproperty

//2. property: p_stop_bit_ready
property p_stop_bit_ready;
    $rose(ready) |-> tx;
endproperty

//------------------------------------------------------------
//Assertions
//------------------------------------------------------------

//1. assertion: a_strobe_starts_tx
a_strobe_starts_tx : assert property(p_strobe_starts_tx)
    else $error("ERR: The TX module haven't pulled down the ready signal after the strobe signal!");

//2. assertion: a_stop_bit_ready
a_stop_bit_ready : assert property(p_stop_bit_ready)
    else $error("STOP ERROR");

//------------------------------------------------------------
//Covers
//------------------------------------------------------------
c_strobe_starts_tx : cover property(p_strobe_starts_tx);
c_stop_bit_ready : cover property(p_stop_bit_ready);


endmodule