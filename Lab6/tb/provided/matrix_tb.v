`timescale 1ns / 1ps
// ECE460M Lab 6 sample matrix multiplication tests. Note that these tests are not exhaustive.
module matrix_tb;
    reg clk = 0;
    reg reset = 0, start = 0;
    reg [5:0] bias;
    reg [7:0] a00, a01, a02, a10, a11, a12, a20, a21, a22;
    reg [7:0] b00, b01, b02, b10, b11, b12, b20, b21, b22;
    wire busy, done;
    wire [7:0] c00, c01, c02, c10, c11, c12, c20, c21, c22;
    wire [7:0] result [0:8];
    reg [7:0] expected [0:8];
    integer i;
    integer errors = 0;

    always #5 clk = ~clk;

    assign result[0] = c00;
    assign result[1] = c01;
    assign result[2] = c02;
    assign result[3] = c10;
    assign result[4] = c11;
    assign result[5] = c12;
    assign result[6] = c20;
    assign result[7] = c21;
    assign result[8] = c22;

    Matrix DUT (
        .clk(clk),
        .reset(reset),
        .start(start),
        .bias(bias),
        .a00(a00),
        .a01(a01),
        .a02(a02),
        .a10(a10),
        .a11(a11),
        .a12(a12),
        .a20(a20),
        .a21(a21),
        .a22(a22),
        .b00(b00),
        .b01(b01),
        .b02(b02),
        .b10(b10),
        .b11(b11),
        .b12(b12),
        .b20(b20),
        .b21(b21),
        .b22(b22),
        .busy(busy),
        .done(done),
        .c00(c00),
        .c01(c01),
        .c02(c02),
        .c10(c10),
        .c11(c11),
        .c12(c12),
        .c20(c20),
        .c21(c21),
        .c22(c22)
    );

    initial begin
        reset = 1;
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Case 1: Identity multiplication.
        @(negedge clk);
        bias = 6'd9;

        a00 = 8'h48; a01 = 8'hD0; a02 = 8'h40;    // 1  -2  0.5
        a10 = 8'h00; a11 = 8'h54; a12 = 8'hC8;    // 0  3  -1
        a20 = 8'h50; a21 = 8'h00; a22 = 8'h58;    // 2  0  4

        b00 = 8'h48; b01 = 8'h00; b02 = 8'h00;    // 1  0  0
        b10 = 8'h00; b11 = 8'h48; b12 = 8'h00;    // 0  1  0
        b20 = 8'h00; b21 = 8'h00; b22 = 8'h48;    // 0  0  1

        expected[0] = 8'h48; expected[1] = 8'hD0; expected[2] = 8'h40;    // 1  -2  0.5
        expected[3] = 8'h00; expected[4] = 8'h54; expected[5] = 8'hC8;    // 0  3  -1
        expected[6] = 8'h50; expected[7] = 8'h00; expected[8] = 8'h58;    // 2  0  4

        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;
        repeat (7) @(posedge clk);
        #1;
        for (i = 0; i < 9; i = i + 1) begin
            if (result[i] !== expected[i]) begin
                errors = errors + 1;
                $display("Case 1, c%0d%0d: expected %02h, got %02h",
                         i / 3, i % 3, expected[i], result[i]);
            end
        end

        // Case 2: Signed normal matrix multiplication.
        @(negedge clk);
        bias = 6'd10;

        a00 = 8'h50; a01 = 8'hD8; a02 = 8'h48;    // 1  -2  0.5
        a10 = 8'h00; a11 = 8'h5C; a12 = 8'hD0;    // 0  3  -1
        a20 = 8'h58; a21 = 8'h00; a22 = 8'h60;    // 2  0  4

        b00 = 8'h58; b01 = 8'h50; b02 = 8'h00;    // 2  1  0
        b10 = 8'hD0; b11 = 8'h00; b12 = 8'h58;    // -1  0  2
        b20 = 8'h50; b21 = 8'hD8; b22 = 8'hD0;    // 1  -2  -1

        expected[0] = 8'h61; expected[1] = 8'h00; expected[2] = 8'hE1;    // 4.5  0  -4.5
        expected[3] = 8'hE0; expected[4] = 8'h58; expected[5] = 8'h66;    // -4  2  7
        expected[6] = 8'h68; expected[7] = 8'hE4; expected[8] = 8'hE0;    // 8  -6  -4

        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;
        repeat (7) @(posedge clk);
        #1;
        for (i = 0; i < 9; i = i + 1) begin
            if (result[i] !== expected[i]) begin
                errors = errors + 1;
                $display("Case 2, c%0d%0d: expected %02h, got %02h",
                         i / 3, i % 3, expected[i], result[i]);
            end
        end

        // Case 3: Rounding and saturation.
        @(negedge clk);
        bias = 6'd10;

        a00 = 8'h51; a01 = 8'h40; a02 = 8'h00;    // 1.125  0.25  0
        a10 = 8'h51; a11 = 8'h00; a12 = 8'h00;    // 1.125  0  0
        a20 = 8'h7F; a21 = 8'h00; a22 = 8'h00;    // 60  0  0

        b00 = 8'h50; b01 = 8'h54; b02 = 8'h58;    // 1  1.5  2
        b10 = 8'h40; b11 = 8'h00; b12 = 8'h50;    // 0.25  0  1
        b20 = 8'h50; b21 = 8'h00; b22 = 8'h00;    // 1  0  0

        expected[0] = 8'h52; expected[1] = 8'h56; expected[2] = 8'h5A;    // 1.25  1.75  2.5
        expected[3] = 8'h51; expected[4] = 8'h56; expected[5] = 8'h59;    // 1.125  1.75  2.25
        expected[6] = 8'h7F; expected[7] = 8'h7F; expected[8] = 8'h7F;    // 60  60  60

        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;
        repeat (7) @(posedge clk);
        #1;
        for (i = 0; i < 9; i = i + 1) begin
            if (result[i] !== expected[i]) begin
                errors = errors + 1;
                $display("Case 3, c%0d%0d: expected %02h, got %02h",
                         i / 3, i % 3, expected[i], result[i]);
            end
        end

        if (errors == 0)
            $display("All matrix results passed.");
        else
            $display("Matrix result mismatches: %0d", errors);
        $finish;
    end
endmodule
