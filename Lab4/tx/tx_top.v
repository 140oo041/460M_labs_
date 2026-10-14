`timescale 1ns / 1ps

module tx_top (
    input clk,
    input btn_rst,
    input btnu,
    input [7:0] sw,
    input sw15,
    output led_busy,
    output [3:0] an,
    output [6:0] seg,
    output ja_data,
    output ja_req,
    input ja_ack
);

    tx_24bit tx (
        .clk(clk),
        .rst(btn_rst),
        .sw_in(sw),
        .send_async(btnu),
        .ack_async(ja_ack),
        .sw15(sw15),
        .busy(led_busy),
        .req(ja_req),
        .data_out(ja_data)
    );

    hex_display display (
        .clk(clk),
        .rst(btn_rst),
        .value(sw),
        .an(an),
        .seg(seg)
    );

endmodule
