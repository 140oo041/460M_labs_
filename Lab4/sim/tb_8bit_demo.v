`timescale 1ns / 1ps

module tb_8bit_demo;

    reg clk_tx = 0;
    reg clk_rx = 0;

    always #5 clk_tx = ~clk_tx;
    initial begin
        #3;
        forever #6.5 clk_rx = ~clk_rx;
    end

    reg rst = 1;
    reg send = 0;
    reg [7:0] sw = 8'hA5;

    wire req, data, busy, ack;
    wire [7:0] rx_data;

    tx_8bit tx_dut (
        .clk(clk_tx), .rst(rst), .sw_in(sw), .send_async(send), .ack_async(ack),
        .busy(busy), .req(req), .data_out(data)
    );

    N_bit_receiver #(.N(8)) rx_dut (
        .clk(clk_rx), .rst(rst), .req(req), .data_stream(data),
        .data_out(rx_data), .ack(ack)
    );

    initial begin
        repeat (5) @(posedge clk_tx);
        rst = 0;
        repeat (5) @(posedge clk_tx);

        // send is held for 5 cycles so it gets through the synchronizer
        send = 1;
        repeat (5) @(posedge clk_tx);
        send = 0;

        // switches change while the transfer is still running
        repeat (30) @(posedge clk_tx);
        sw = 8'h3C;

        // wait for the tx to finish, then a few rx cycles for the last shift
        wait (busy);
        wait (!busy);
        repeat (5) @(posedge clk_rx);

        if (rx_data === 8'hA5) $display("PASS: receiver got %h", rx_data);
        else $display("FAIL: receiver got %h, expected A5", rx_data);
        $finish;
    end

endmodule
