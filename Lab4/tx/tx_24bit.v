`timescale 1ns / 1ps

module tx_24bit (
    input clk,
    input rst,
    input [7:0] sw_in,
    input send_async,
    input ack_async,
    input sw15,
    output busy,
    output reg req,
    output reg data_out
);

    wire send_pulse;
    single_pulser single_pulser_u (
        .clk(clk),
        .rst(rst),
        .btn_in(send_async),
        .pulse(send_pulse)
    );

    wire ack_sync;
    ff_sync ff_sync_u (
        .clk(clk),
        .rst(rst),
        .async_in(ack_async),
        .sync_out(ack_sync)
    );

    localparam  IDLE = 2'b00,
                DRIVE_DATA = 2'b01,
                TOGGLE_REQ = 2'b10,
                WAIT_ACK = 2'b11;

    reg [1:0] cs, ns;

    always @(posedge clk) begin
        if (rst) cs <= IDLE;
        else cs <= ns;
    end

    reg toggle_req, drive_data, capture_sw, decrement_bit_idx;

    reg [23:0] tx_packet;
    reg [4:0] bit_idx;

    assign busy = (cs != IDLE);

    always @(*) begin
        ns = cs;
        toggle_req = 0;
        capture_sw = 0;
        drive_data = 0;
        decrement_bit_idx = 0;
        case (cs)
            IDLE: begin
                if (send_pulse && (req == ack_sync)) begin
                    ns = DRIVE_DATA;
                    capture_sw = 1;
                end
            end
            DRIVE_DATA: begin
                drive_data = 1;
                ns = TOGGLE_REQ;
            end
            TOGGLE_REQ: begin
                toggle_req = 1;
                ns = WAIT_ACK;
            end
            WAIT_ACK: begin
                if (ack_sync == req) begin
                    if (bit_idx == 0) ns = IDLE;
                    else ns = DRIVE_DATA;
                    decrement_bit_idx = 1; // either decrement or reload to 5'd23 on overflow
                end
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            req <= 0;
            data_out <= 0;
            tx_packet <= 24'b0;
            bit_idx <= 5'd23;
        end else begin
            if (toggle_req) req <= ~req;
            if (capture_sw) tx_packet <= (sw15) ? {8'hA5, sw_in ^ 8'h01, (8'hA5 ^ sw_in)}
                                                : {8'hA5, sw_in, (8'hA5 ^ sw_in)};
            if (drive_data) data_out <= tx_packet[bit_idx];
            if (decrement_bit_idx) bit_idx <= (bit_idx == 0) ? 5'd23 : bit_idx - 1;
        end
    end

endmodule
