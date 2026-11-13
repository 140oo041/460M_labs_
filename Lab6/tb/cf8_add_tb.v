`timescale 1ns / 1ps
// checks cf8_add: a few known answers, then every input pair at biases 9 to 12
module cf8_add_tb;
    `include "cf8_ref.vh"

    reg [7:0] acc = 0, p = 0;
    wire [7:0] acc_next;
    cf8_add dut (.acc(acc), .p(p), .acc_next(acc_next));

    integer ix, iy, ibias, errors, checked;
    reg [5:0] bias;
    reg [8:0] r;

    task known;
        input [7:0] x, y, expect_s;
        begin
            acc = x; p = y; #1;
            if (acc_next !== expect_s) begin
                errors = errors + 1;
                $display("known answer: %h + %h = %h, expected %h", x, y, acc_next, expect_s);
            end
        end
    endtask

    initial begin
        errors = 0; checked = 0;
        known(8'h50, 8'h50, 8'h58); // 1 + 1 = 2
        known(8'h50, 8'hD0, 8'h00); // 1 + -1 = 0
        known(8'h50, 8'h30, 8'h50); // tie, goes to even
        known(8'h50, 8'h31, 8'h51);
        known(8'h7F, 8'h7F, 8'h7F);
        known(8'hFF, 8'hFF, 8'hFF);
        known(8'h00, 8'h54, 8'h54);
        known(8'h54, 8'h80, 8'h54);
        known(8'h80, 8'h00, 8'h00);

        for (ibias = 9; ibias <= 12; ibias = ibias + 1) begin
            bias = ibias;
            for (ix = 0; ix < 256; ix = ix + 1)
                for (iy = 0; iy < 256; iy = iy + 1) begin
                    acc = ix; p = iy; #1;
                    r = ref_add(acc, p, bias);
                    if (!r[8]) begin
                        checked = checked + 1;
                        if (acc_next !== r[7:0]) begin
                            errors = errors + 1;
                            if (errors <= 20)
                                $display("bias %0d: %h + %h = %h, expected %h", bias, acc, p, acc_next, r[7:0]);
                        end
                    end
                end
        end

        if (errors == 0) $display("cf8_add PASSED: %0d pairs checked, 0 mismatches", checked);
        else $display("cf8_add FAILED: %0d mismatches in %0d pairs", errors, checked);
        $finish;
    end
endmodule
