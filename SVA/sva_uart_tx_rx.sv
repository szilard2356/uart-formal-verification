// -----------------------------------------------------------------------------
// Module:      [sva_uart_tx_rx]
// Description: [SystemVerilog Assertions for the testbench of the RX_TX module]
// -----------------------------------------------------------------------------

module sva_uart_tx_rx(
    input      clk,
    input      rst,
    //TX
    input[7:0] tx_data,
    input      tx_strobe,
    input      tx_parity,
    input      tx,
    input      ready,
    input      err,
    //RX
    input[7:0] rx_data,
    input      busy,
    input      rx_parity,
    input      parity_err,
    input      frame_err,
    input      rx
);

//------------------------------------------------------------
//Default clocking and default reset
//------------------------------------------------------------
default clocking cb_sva @(posedge clk); endclocking
default disable iff(rst == 1'b0);

//------------------------------------------------------------
//Properties
//------------------------------------------------------------

//1. property: p_busy_after_start
property p_busy_after_start;
    tx_strobe |-> s_eventually (busy == 1'b1);
endproperty

//2. property: p_strobe_tx_start_bit
// Wait for 2 clock cycles after the strobe signal for the start bit to appear on the TX line
property p_strobe_tx_start_bit;
    tx_strobe |-> ##2 (tx == 1'b0);
endproperty

//------------------------------------------------------------
//Assertions
//------------------------------------------------------------

//1. assertion: a_busy_after_start
a_busy_after_start : assert property(p_busy_after_start)
    else $error("ERR: Haven't received a busy bit");

//2. assertion: a_strobe_tx_start_bit
a_strobe_tx_start_bit : assert property(p_strobe_tx_start_bit)
    else $error("ERR: Haven't received a start bit");

//------------------------------------------------------------
//Covers
//------------------------------------------------------------

c_busy_after_start : cover property(p_busy_after_start);
c_strobe_tx_start_bit : cover property(p_strobe_tx_start_bit);

endmodule