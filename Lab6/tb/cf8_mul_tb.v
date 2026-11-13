`timescale 1ns / 1ps
// checks cf8_mul: a few known answers, then every input pair at biases 9 to 12
module cf8_mul_tb;
    `include "cf8_ref.vh"

    reg [7:0] a = 0, b = 0;
    reg [5:0] bias = 6'd10;
    wire [7:0] p;
    cf8_mul dut (.a(a), .b(b), .bias(bias), .p(p));

    integer ia, ib, ibias, errors, checked;
    reg [8:0] r;

    task known;
        input [7:0] x, y, expect_p;
        begin
            a = x; b = y; bias = 6'd10; #1;
            if (p !== expect_p) begin
                errors = errors + 1;
                $display("known answer: %h * %h = %h, expected %h", x, y, p, expect_p);
            end
        end
    endtask

    initial begin
        errors = 0; checked = 0;
        known(8'h54, 8'h54, 8'h59); // 1.5 * 1.5 = 2.25
        known(8'h51, 8'h51, 8'h52); // 1.265625 rounds down to 1.25
        known(8'h51, 8'h54, 8'h56); // tie, goes to even
        known(8'h52, 8'h52, 8'h54); // tie, goes to even
        known(8'h7F, 8'h7F, 8'h7F);
        known(8'h7F, 8'hFF, 8'hFF);
        known(8'h80, 8'h54, 8'h00);
        known(8'h00, 8'h54, 8'h00);

        for (ibias = 9; ibias <= 12; ibias = ibias + 1) begin
            bias = ibias;
            for (ia = 0; ia < 256; ia = ia + 1)
                for (ib = 0; ib < 256; ib = ib + 1) begin
                    a = ia; b = ib; #1;
                    r = ref_mul(a, b, bias);
                    if (!r[8]) begin
                        checked = checked + 1;
                        if (p !== r[7:0]) begin
                            errors = errors + 1;
                            if (errors <= 20)
                                $display("bias %0d: %h * %h = %h, expected %h", bias, a, b, p, r[7:0]);
                        end
                    end
                end
        end

        if (errors == 0) $display("cf8_mul PASSED: %0d pairs checked, 0 mismatches", checked);
        else $display("cf8_mul FAILED: %0d mismatches in %0d pairs", errors, checked);
        $finish;
    end
endmodule
