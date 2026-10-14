`timescale 1ns / 1ps

module tb_1bit_demo;

    reg clk_tx = 0;
    reg clk_rx = 0;

    always #5 clk_tx = ~clk_tx;
    initial begin
        #3;
        forever #6.5 clk_rx = ~clk_rx;
    end

    reg rst = 1;
    reg send = 0;
    reg bit_in = 0;

    wire req, data, ack;
    wire rx_bit, rx_event;

    tx_1bit tx_dut (
        .clk(clk_tx), .rst(rst), .data_in(bit_in), .send_async(send),
        .ack_async(ack), .req(req), .data_out(data)
    );

    one_bit_receiver rx_dut (
        .clk(clk_rx), .rst(rst), .req(req), .data_in(data),
        .data_out(rx_bit), .ack(ack), .RX_EVENT(rx_event)
    );

    // send is held for 5 cycles so it gets through the synchronizer
    task press_send;
        begin
            send = 1;
            repeat (5) @(posedge clk_tx);
            send = 0;
        end
    endtask

    // transfer is done when the rx acks (ack catches up to req), then a few
    // tx cycles for the ack to cross back and the tx to return to idle
    task send_bit(input value);
        begin
            wait (req == ack);
            bit_in = value;
            press_send;
            wait (req != ack);
            wait (req == ack);
            repeat (5) @(posedge clk_tx);
            if (rx_bit === value) $display("PASS: sent %b, receiver got %b", value, rx_bit);
            else $display("FAIL: sent %b, receiver got %b", value, rx_bit);
        end
    endtask

    // stops the sim if the handshake hangs
    initial begin
        #200_000;
        $display("FAIL: timeout");
        $finish;
    end

    initial begin
        repeat (5) @(posedge clk_tx);
        rst = 0;
        repeat (5) @(posedge clk_tx);

        send_bit(1);
        send_bit(0);
        send_bit(1);
        send_bit(0);

        $finish;
    end

endmodule
