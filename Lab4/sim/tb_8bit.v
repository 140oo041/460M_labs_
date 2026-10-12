`timescale 1ns / 1ps

module tb_8bit;

    reg clk_tx = 0;
    reg clk_rx = 0;

    always #5 clk_tx = ~clk_tx;
    initial begin
        #3;
        forever #6.5 clk_rx = ~clk_rx;
    end

    reg rst = 1;
    reg send = 0;
    reg [7:0] sw = 8'h00;

    wire req, data, busy, ack;
    wire [7:0] rx_data;

    integer pass_count = 0;
    integer fail_count = 0;
    integer i;

    tx_8bit tx_dut (
        .clk(clk_tx), .rst(rst), .sw_in(sw), .send_async(send), .ack_async(ack),
        .busy(busy), .req(req), .data_out(data)
    );

    eight_bit_receiver rx_dut (
        .clk(clk_rx), .rst(rst), .req(req), .data_stream(data),
        .data_out(rx_data), .ack(ack)
    );

    // send is held for 5 cycles so it gets through the synchronizer
    task press_send;
        begin
            send = 1;
            repeat (5) @(posedge clk_tx);
            send = 0;
        end
    endtask

    // busy drops after the tx gets the ack for the last bit, then a few
    // rx cycles so the receiver has shifted that bit in
    task wait_for_transfer;
        begin
            wait (busy);
            wait (!busy);
            repeat (5) @(posedge clk_rx);
        end
    endtask

    task check(input [7:0] expected);
        begin
            if (rx_data === expected) begin
                pass_count = pass_count + 1;
                $display("PASS: got %h", rx_data);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: expected %h, got %h", expected, rx_data);
            end
        end
    endtask

    task send_byte(input [7:0] value);
        begin
            wait (!busy);
            sw = value;
            press_send;
            wait_for_transfer;
            check(value);
        end
    endtask

    // stops the sim if a handshake hangs
    initial begin
        #2_000_000;
        $display("FAIL: timeout");
        $finish;
    end

    initial begin
        repeat (5) @(posedge clk_tx);
        rst = 0;
        repeat (5) @(posedge clk_tx);

        send_byte(8'h00);
        send_byte(8'h01);
        send_byte(8'h55);
        send_byte(8'hAA);
        send_byte(8'hFF);

        for (i = 0; i < 8; i = i + 1)
            send_byte($random);

        // switches change mid-transfer, receiver should still get A5
        wait (!busy);
        sw = 8'hA5;
        press_send;
        repeat (10) @(posedge clk_tx);
        sw = 8'h3C;
        wait_for_transfer;
        check(8'hA5);

        // second send while busy should be ignored
        wait (!busy);
        sw = 8'h96;
        press_send;
        repeat (10) @(posedge clk_tx);
        sw = 8'h69;
        press_send;
        wait_for_transfer;
        check(8'h96);

        $display("%0d passed, %0d failed", pass_count, fail_count);
        $finish;
    end

endmodule
