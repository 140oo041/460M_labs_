`timescale 1ns / 1ps

module tb_packet;

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
    reg [7:0] sw = 8'h00;

    wire req, data, busy, ack;
    wire [23:0] rx_packet;
    wire rx_valid, rx_error;
    wire [7:0] rx_payload = rx_packet[15:8];

    integer pass_count = 0;
    integer fail_count = 0;
    integer req_toggles = 0;
    integer i;

    tx_24bit tx_dut (
        .clk(clk_tx), .rst(rst), .sw_in(sw), .send_async(send), .ack_async(ack),
        .sw15(sw15), .busy(busy), .req(req), .data_out(data)
    );

    twenty_four_bit_receiver rx_dut (
        .clk(clk_rx), .rst(rst), .req(req), .data_stream(data),
        .data_out(rx_packet), .ack(ack), .valid(rx_valid), .error(rx_error)
    );

    // counts every time req changes, a full packet should be 24
    always @(req) req_toggles = req_toggles + 1;

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

    task check_toggles;
        begin
            if (req_toggles === 24) begin
                pass_count = pass_count + 1;
                $display("PASS: 24 req toggles");
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: %0d req toggles, expected 24", req_toggles);
            end
            req_toggles = 0;
        end
    endtask

    // rx_packet is the last valid packet, a corrupted packet should not change it
    task check_packet(input [23:0] expected);
        begin
            if (rx_packet === expected) begin
                pass_count = pass_count + 1;
                $display("PASS: packet %h", rx_packet);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: packet expected %h, got %h", expected, rx_packet);
            end
        end
    endtask

    task check_status(input exp_valid, input exp_error, input [7:0] exp_payload);
        begin
            if (rx_valid === exp_valid && rx_error === exp_error && rx_payload === exp_payload) begin
                pass_count = pass_count + 1;
                $display("PASS: valid=%b error=%b payload=%h", rx_valid, rx_error, rx_payload);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: expected valid=%b error=%b payload=%h, got valid=%b error=%b payload=%h",
                         exp_valid, exp_error, exp_payload, rx_valid, rx_error, rx_payload);
            end
        end
    endtask

    // stops the sim if a handshake hangs
    initial begin
        #5_000_000;
        $display("FAIL: timeout");
        $finish;
    end

    initial begin
        repeat (5) @(posedge clk_tx);
        rst = 0;
        repeat (5) @(posedge clk_tx);
        req_toggles = 0;

        // required sequence: valid 37, corrupted 37, valid A5
        send_packet(8'h37, 0);
        check_toggles;
        check_packet({8'hA5, 8'h37, 8'hA5 ^ 8'h37});
        check_status(1, 0, 8'h37);

        send_packet(8'h37, 1);
        check_toggles;
        check_packet({8'hA5, 8'h37, 8'hA5 ^ 8'h37});
        check_status(0, 1, 8'h37);

        send_packet(8'hA5, 0);
        check_toggles;
        check_packet({8'hA5, 8'hA5, 8'h00});
        check_status(1, 0, 8'hA5);

        // other values, valid then corrupted
        send_packet(8'h00, 0);
        check_packet({8'hA5, 8'h00, 8'hA5});
        check_status(1, 0, 8'h00);

        send_packet(8'hFF, 0);
        check_packet({8'hA5, 8'hFF, 8'h5A});
        check_status(1, 0, 8'hFF);

        send_packet(8'hFF, 1);
        check_packet({8'hA5, 8'hFF, 8'h5A});
        check_status(0, 1, 8'hFF);

        for (i = 0; i < 6; i = i + 1) begin
            send_packet($random, 0);
            check_status(1, 0, sw);
        end

        // switches and sw15 change mid-transfer, packet should not change
        wait (!busy);
        sw = 8'h3C;
        sw15 = 0;
        press_send;
        repeat (20) @(posedge clk_tx);
        sw = 8'hC3;
        sw15 = 1;
        wait_for_transfer;
        check_packet({8'hA5, 8'h3C, 8'hA5 ^ 8'h3C});
        check_status(1, 0, 8'h3C);
        sw15 = 0;

        // second send while busy should be ignored
        req_toggles = 0;
        wait (!busy);
        sw = 8'h96;
        press_send;
        repeat (20) @(posedge clk_tx);
        sw = 8'h69;
        press_send;
        wait_for_transfer;
        check_toggles;
        check_packet({8'hA5, 8'h96, 8'hA5 ^ 8'h96});

        $display("%0d passed, %0d failed", pass_count, fail_count);
        $finish;
    end

endmodule
