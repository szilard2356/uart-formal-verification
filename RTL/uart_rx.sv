// -----------------------------------------------------------------------------
// Module:      [uart_rx.sv]
// Description: [UART reciever with 13x oversampling]
// -----------------------------------------------------------------------------

module uart_rx #(
    parameter                 P_DIVISOR = 401,
    parameter int unsigned    P_DATA_BITS = 8,
    parameter                 P_PARITY = 1,
    parameter                 P_STOP_BIT = 2
)
(
    input                     i_clk,
    input                     i_rst,
    output[P_DATA_BITS - 1:0] o_data,
    output                    o_rx_busy,
    input                     i_parity,
    output                    o_parity_err,
    output                    o_frame_err,
    input                     i_rx  
);


//--------------------------------------------------------------------------------------------------------------------------------
//Local parameters
//--------------------------------------------------------------------------------------------------------------------------------
localparam [2:0] 
        IDLE  = 0,
        START = 1,
        DATA  = 2,
        CHECK_PARITY = 3,
        CHECK_FRAME = 4;

//--------------------------------------------------------------------------------------------------------------------------------
//Logics
//--------------------------------------------------------------------------------------------------------------------------------
logic[$clog2(P_DIVISOR) - 1 :0] b_counter;
logic                           baud_cycl;

logic[2:0]                      current_state;
logic                           rx_q1, rx_q2;
logic                           falling_edge;
logic[P_DATA_BITS - 1: 0]       data;
logic[P_DATA_BITS - 1: 0]       o_buffer;
logic[3:0]                      counter;
logic[$clog2(P_DATA_BITS):0]    data_counter;

logic                           busy;
logic                           cntr_en;
logic                           frame_err;
logic[P_STOP_BIT - 1 : 0]       stop_cntr;
logic                           parity;
logic                           parity_sample;
logic                           parity_err;

assign o_data = o_buffer;
assign o_parity_err = parity_err;
assign o_frame_err = frame_err;
assign o_rx_busy = busy;

//---------------------------------------------------------------------------------------------------------------------------------
//Baudrate generator
//---------------------------------------------------------------------------------------------------------------------------------
always_ff @(posedge i_clk or negedge i_rst)
begin
    if(!i_rst)
        b_counter <= 0;
    else if(baud_cycl)
        b_counter <= 0;
    else
        b_counter <= b_counter + 1;

end
assign baud_cycl = (b_counter == (P_DIVISOR - 1));

//---------------------------------------------------------------------------------------------------------------------------------
//Oversampling counter
//---------------------------------------------------------------------------------------------------------------------------------
always_ff@(posedge i_clk or negedge i_rst) begin 
    if(!i_rst)
        counter <= 0;
    else if(baud_cycl && cntr_en)begin
        if(counter == 12)
            counter <= 0;
        else
            counter <= counter + 1;
    end
    else
        counter <= counter;
end

//---------------------------------------------------------------------------------------------------------------------------------
//Start bit sampling
//---------------------------------------------------------------------------------------------------------------------------------
always_ff @(posedge i_clk or negedge i_rst) begin
    if(!i_rst) begin
        rx_q1 <= 1;
        rx_q2 <= 1;
    end
    else begin
        rx_q1 <= i_rx;
        rx_q2 <= rx_q1;
    end
end
assign falling_edge = rx_q2 && ~rx_q1;

//---------------------------------------------------------------------------------------------------------------------------------
//State machine
//---------------------------------------------------------------------------------------------------------------------------------
always_ff @(posedge i_clk or negedge i_rst) begin
    if(!i_rst) begin
        stop_cntr <= 0;
        parity <= 0;
        parity_sample <= 0;
        o_buffer <= 0;
        cntr_en <= 0;
        data <= 0;
        busy <= 0;
        parity_err <= 0;
        frame_err <= 0;
        data_counter <= 0;
        current_state <= IDLE;
    end
    else begin
        case(current_state)
            IDLE: begin
                busy <= 0;
                parity_err <= 0;
                frame_err <= 0;
                if(falling_edge) begin
                    parity_sample <= i_parity;
                    current_state <= START;
                    cntr_en <= 1;
		        end
                else begin
                    current_state <= current_state;
		        end
            end
            START: begin 
                if(baud_cycl && counter == 12)
                    current_state <= DATA;
                else
                    current_state <= current_state;
            end
            DATA: begin
                // Sample the incoming data strictly at the middle of the bit period (counter == 6)
                if(baud_cycl && counter == 6) begin
                    data <= {i_rx, data[P_DATA_BITS - 1:1]};
                end
                if(baud_cycl && counter == 12)begin
                    
                
                    if(data_counter == P_DATA_BITS - 1) begin
                        if(P_PARITY == 1)
                            current_state <= CHECK_PARITY;
                        else
                            current_state <= CHECK_FRAME;
                    end
                    else begin
                        data_counter <= data_counter + 1;
                    end
                end
            end
            CHECK_PARITY: begin 
                if(baud_cycl && counter == 4)
                    parity <= ^data;
                if(baud_cycl && counter == 6)begin
                    if(parity_sample)
                        parity_err <= parity ~^ i_rx;
                    else
                        parity_err <= parity ^ i_rx;
		        end
                if(baud_cycl && counter == 12)
                    current_state <= CHECK_FRAME;

            end
            CHECK_FRAME: begin
                if(baud_cycl && counter == 6) begin
                    if(i_rx == 0) begin
                        frame_err <= 1;
                    end
                end 
                if(baud_cycl && counter == 12) begin
                    if(stop_cntr == P_STOP_BIT - 1) begin
                        data_counter <= 0;
                        stop_cntr <= 0;
                        busy <= 1;
                        cntr_en <= 0;
                        counter <= 0;
                        current_state <= IDLE;
                        o_buffer <= data;
                    end
                    else begin
                        stop_cntr <= stop_cntr + 1;
                    end
                end
                
            end 
        endcase
    end
end

endmodule
