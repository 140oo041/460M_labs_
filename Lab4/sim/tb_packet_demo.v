`timescale 1ns / 1ps

module tb_packet_demo;

    reg clk_tx = 0;
    reg clk_rx = 0;

    always #5 clk_tx = ~clk_tx;
    initial begin
        #3;
        forever #6.5 clk_rx = ~clk_rx;
    end

    reg rst = 1;
    reg send = 0;
    reg sw15 = 0;
    reg [7:0] sw = 8'h37;

    wire req, data, busy, ack;
    wire [23:0] rx_packet;
    wire rx_valid, rx_error;
    wire [7:0] rx_payload = rx_packet[15:8];

    tx_24bit tx_dut (
        .clk(clk_tx), .rst(rst), .sw_in(sw), .send_async(send), .ack_async(ack),
        .sw15(sw15), .busy(busy), .req(req), .data_out(data)
    );

    twenty_four_bit_receiver rx_dut (
        .clk(clk_rx), .rst(rst), .req(req), .data_stream(data),
        .data_out(rx_packet), .ack(ack), .valid(rx_valid), .error(rx_error)
    );

    // send is held for 5 cycles so it gets through the synchronizer
    task press_send;
        begin
            send = 1;
            repeat (5) @(posedge clk_tx);
            send = 0;
        end
    endtask

    // busy drops after the tx gets the ack for the last bit, then extra rx
    // cycles so the receiver has shifted that bit in and updated its status
    task wait_for_transfer;
        begin
            wait (busy);
            wait (!busy);
            repeat (10) @(posedge clk_rx);
        end
    endtask

    task send_packet(input [7:0] value, input fault);
        begin
            wait (!busy);
            sw = value;
            sw15 = fault;
            press_send;
            wait_for_transfer;
        end
    endtask

    task check(input exp_valid, input exp_error, input [7:0] exp_payload);
        begin
            if (rx_valid === exp_valid && rx_error === exp_error && rx_payload === exp_payload)
                $display("PASS: valid=%b error=%b payload=%h", rx_valid, rx_error, rx_payload);
            else
                $display("FAIL: expected valid=%b error=%b payload=%h, got valid=%b error=%b payload=%h",
                         exp_valid, exp_error, exp_payload, rx_valid, rx_error, rx_payload);
        end
    endtask

    initial begin
        repeat (5) @(posedge clk_tx);
        rst = 0;
        repeat (5) @(posedge clk_tx);

        // 1. valid packet, receiver accepts 37
        send_packet(8'h37, 0);
        check(1, 0, 8'h37);

        // 2. corrupted packet, error is set and the payload stays 37
        send_packet(8'h37, 1);
        check(0, 1, 8'h37);

        // 3. new valid packet, receiver updates to A5 and error clears
        send_packet(8'hA5, 0);
        check(1, 0, 8'hA5);

        $finish;
    end

endmodule
