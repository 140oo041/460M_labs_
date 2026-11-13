`timescale 1ns / 1ps
// full Matrix testbench: protocol checks plus random and directed matrices at biases 9 to 12
module matrix_sys_tb;
    `include "cf8_ref.vh"

    reg clk = 0;
    reg reset = 0, start = 0;
    reg [5:0] bias = 6'd10;
    reg [71:0] amat = 72'd0, bmat = 72'd0; // element n is bits [71-8n -: 8]
    wire busy, done;
    wire [7:0] c00, c01, c02, c10, c11, c12, c20, c21, c22;

    wire [7:0] a00 = amat[71:64], a01 = amat[63:56], a02 = amat[55:48],
        a10 = amat[47:40], a11 = amat[39:32], a12 = amat[31:24],
        a20 = amat[23:16], a21 = amat[15:8], a22 = amat[7:0];
    wire [7:0] b00 = bmat[71:64], b01 = bmat[63:56], b02 = bmat[55:48],
        b10 = bmat[47:40], b11 = bmat[39:32], b12 = bmat[31:24],
        b20 = bmat[23:16], b21 = bmat[15:8], b22 = bmat[7:0];

    Matrix DUT (
        .clk(clk), .reset(reset), .start(start), .bias(bias),
        .a00(a00), .a01(a01), .a02(a02), .a10(a10), .a11(a11), .a12(a12), .a20(a20), .a21(a21), .a22(a22),
        .b00(b00), .b01(b01), .b02(b02), .b10(b10), .b11(b11), .b12(b12), .b20(b20), .b21(b21), .b22(b22),
        .busy(busy), .done(done),
        .c00(c00), .c01(c01), .c02(c02), .c10(c10), .c11(c11), .c12(c12), .c20(c20), .c21(c21), .c22(c22)
    );

    wire [71:0] cmat = {c00, c01, c02, c10, c11, c12, c20, c21, c22};
    reg [71:0] expc;
    reg skip; // case has values the lab doesn't test

    integer seed = 32'h1234abcd;
    integer errors = 0, nruns = 0, nskipped = 0;

    always #5 clk = ~clk;

    task check;
        input exp_busy, exp_done;
        input [71:0] exp_c;
        input cmp_c;
        input [8*24-1:0] tag;
        begin
            if (busy !== exp_busy || done !== exp_done || (cmp_c && cmat !== exp_c)) begin
                errors = errors + 1;
                if (errors <= 20)
                    $display("FAIL %0s @%0t: busy=%b done=%b (want %b %b) c=%h (want %h)",
                        tag, $time, busy, done, exp_busy, exp_done, cmat, exp_c);
            end
        end
    endtask

    // expected C, rounding each product and each sum like the hardware does
    task compute_expected;
        integer i, j, k;
        reg [7:0] acc;
        reg [8:0] pm, ps;
        begin
            skip = 0;
            for (i = 0; i < 3; i = i + 1)
                for (j = 0; j < 3; j = j + 1) begin
                    acc = 8'h00;
                    for (k = 0; k < 3; k = k + 1) begin
                        pm = ref_mul(amat[(71 - 8*(3*i + k)) -: 8], bmat[(71 - 8*(3*k + j)) -: 8], bias);
                        ps = ref_add(acc, pm[7:0], bias);
                        skip = skip | pm[8] | ps[8];
                        acc = ps[7:0];
                    end
                    expc[(71 - 8*(3*i + j)) -: 8] = acc;
                end
        end
    endtask

    task rnd_elem;
        output [7:0] v;
        integer r, e;
        begin
            r = $random(seed) & 32'h7fffffff;
            if (r % 100 < 12) begin
                v = (r & 32'h100) ? 8'h80 : 8'h00;
            end else begin
                case (($random(seed) & 32'h7fffffff) % 100)
                    0, 1, 2, 3, 4: e = 1 + (($random(seed) & 32'h7fffffff) % 15);
                    5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19:
                        e = bias + (($random(seed) & 32'h7fffffff) % 7); // big, saturates
                    default: e = bias + (($random(seed) & 32'h7fffffff) % 5) - 2;
                endcase
                if (e < 1) e = 1;
                if (e > 15) e = 15;
                v = {1'b0, e[3:0], 3'd0};
                v[7] = $random(seed);
                v[2:0] = $random(seed);
            end
        end
    endtask

    task rnd_matrices;
        integer n;
        reg [7:0] v;
        begin
            for (n = 0; n < 9; n = n + 1) begin
                rnd_elem(v); amat[(71 - 8*n) -: 8] = v;
                rnd_elem(v); bmat[(71 - 8*n) -: 8] = v;
            end
        end
    endtask

    task fill_all;
        input [7:0] av, bv;
        integer n;
        begin
            for (n = 0; n < 9; n = n + 1) begin
                amat[(71 - 8*n) -: 8] = av;
                bmat[(71 - 8*n) -: 8] = bv;
            end
        end
    endtask

    // one operation. hostile scrambles the inputs and holds start high while busy.
    // holds = idle edges to check after done, 0 means the next start comes right away
    task do_run;
        input hostile;
        input integer holds;
        integer cyc;
        begin
            compute_expected;
            nruns = nruns + 1;
            if (skip) nskipped = nskipped + 1;

            @(negedge clk); start = 1;
            @(posedge clk); #1;
            check(1'b1, 1'b0, 72'd0, 1'b1, "after accept");
            for (cyc = 1; cyc <= 7; cyc = cyc + 1) begin
                @(negedge clk);
                if (hostile) begin
                    bias = $random(seed);
                    rnd_matrices;
                    start = 1;
                end else begin
                    start = 0;
                end
                @(posedge clk); #1;
                if (cyc < 7) check(1'b1, 1'b0, 72'd0, 1'b1, "computing");
                else check(1'b0, 1'b1, expc, ~skip, "after cycle 7");
            end
            if (holds > 0) begin
                @(negedge clk); start = 0;
                repeat (holds) begin
                    @(posedge clk); #1;
                    check(1'b0, 1'b1, expc, ~skip, "hold after done");
                end
            end
        end
    endtask

    integer ibias, n, cyc, m;

    initial begin
        // reset from power up
        reset = 1; repeat (2) @(posedge clk); #1;
        check(1'b0, 1'b0, 72'd0, 1'b1, "in reset");
        @(negedge clk); reset = 0;
        repeat (2) begin @(posedge clk); #1; check(1'b0, 1'b0, 72'd0, 1'b1, "idle"); end

        // reset in the middle of a run, at every cycle 1..7
        for (cyc = 1; cyc <= 7; cyc = cyc + 1) begin
            bias = 6'd10; rnd_matrices;
            @(negedge clk); start = 1;
            @(posedge clk); #1;
            for (m = 1; m < cyc; m = m + 1) begin
                @(negedge clk); start = 0;
                @(posedge clk); #1;
            end
            @(negedge clk); start = 0; reset = 1;
            @(posedge clk); #1;
            check(1'b0, 1'b0, 72'd0, 1'b1, "mid-run reset");
            @(negedge clk); reset = 0;
            repeat (3) begin @(posedge clk); #1; check(1'b0, 1'b0, 72'd0, 1'b1, "after mid-run reset"); end
        end

        // reset beats start
        @(negedge clk); reset = 1; start = 1;
        @(posedge clk); #1;
        check(1'b0, 1'b0, 72'd0, 1'b1, "reset with start");
        @(negedge clk); reset = 0; start = 0;
        repeat (3) begin @(posedge clk); #1; check(1'b0, 1'b0, 72'd0, 1'b1, "idle after reset+start"); end

        // reset after done
        bias = 6'd9; rnd_matrices;
        do_run(0, 1);
        @(negedge clk); reset = 1;
        @(posedge clk); #1;
        check(1'b0, 1'b0, 72'd0, 1'b1, "reset after done");
        @(negedge clk); reset = 0;
        repeat (2) begin @(posedge clk); #1; check(1'b0, 1'b0, 72'd0, 1'b1, "idle after reset"); end

        // directed matrices
        for (ibias = 9; ibias <= 12; ibias = ibias + 1) begin
            bias = ibias;
            fill_all(8'h7F, 8'h7F);
            do_run(0, 1);
            fill_all(8'h7F, 8'hFF);
            do_run(0, 1);
            fill_all(8'h00, 8'h80);
            do_run(0, 1);
            fill_all(8'h80, 8'h80);
            do_run(0, 1);
            fill_all({1'b0, bias[3:0], 3'd2}, {1'b0, bias[3:0], 3'd5});
            do_run(0, 1);
            // every column of B is y, -y, 0 so the sums cancel
            fill_all({1'b0, bias[3:0], 3'd3}, 8'h00);
            bmat = {{3{{1'b0, bias[3:0], 3'd6}}}, {3{{1'b1, bias[3:0], 3'd6}}}, {3{8'h00}}};
            do_run(0, 1);
            // A times identity
            rnd_matrices;
            bmat = {{1'b0, bias[3:0], 3'd0}, 8'h00, 8'h00, 8'h00, {1'b0, bias[3:0], 3'd0}, 8'h00, 8'h00, 8'h00, {1'b0, bias[3:0], 3'd0}};
            do_run(0, 1);
        end

        // random, back to back, hostile inputs on odd runs
        for (ibias = 9; ibias <= 12; ibias = ibias + 1) begin
            for (n = 0; n < 700; n = n + 1) begin
                bias = ibias;
                rnd_matrices;
                do_run(n % 2, n % 3);
            end
        end

        bias = 6'd10; rnd_matrices;
        do_run(0, 2);

        $display("%0d operations run, %0d had untested values (data compare skipped, protocol still checked)", nruns, nskipped);
        if (errors == 0) $display("matrix_sys_tb PASSED");
        else $display("matrix_sys_tb FAILED: %0d errors", errors);
        $finish;
    end
endmodule
