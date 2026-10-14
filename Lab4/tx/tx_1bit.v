`timescale 1ns / 1ps

module tx_1bit (
    input clk,
    input rst,
    input data_in,
    input send_async,
    input ack_async,
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

    reg toggle_req, drive_data;

    always @(*) begin
        ns = cs;
        toggle_req = 0;
        drive_data = 0;
        case (cs)
            IDLE: begin
                if (send_pulse && (req == ack_sync)) begin
                    ns = DRIVE_DATA;
                    drive_data = 1;
                end
            end
            DRIVE_DATA: begin
                ns = TOGGLE_REQ;
            end
            TOGGLE_REQ: begin
                toggle_req = 1;
                ns = WAIT_ACK;
            end
            WAIT_ACK: begin
                if (ack_sync == req) ns = IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            req <= 0;
            data_out <= 0;
        end else begin
            if (toggle_req) req <= ~req;
            if (drive_data) data_out <= data_in;
        end
    end

endmodule
