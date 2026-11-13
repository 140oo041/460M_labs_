// reference model, not synthesizable. returns {dc, result}, dc = case the lab doesn't test

function real cf8_dec;
    input [7:0] x;
    input [5:0] bias;
    integer ex;
    begin
        ex = x[6:3];
        ex = ex - bias;
        if (x[6:3] == 4'd0) cf8_dec = 0.0;
        else cf8_dec = (x[7] ? -1.0 : 1.0) * (1.0 + x[2:0] / 8.0) * $pow(2.0, ex);
    end
endfunction

function [8:0] cf8_enc;
    input real v;
    input [5:0] bias;
    real m, fl, fr;
    integer e, r, eb;
    reg s;
    begin
        if (v == 0.0) cf8_enc = 9'h000;
        else begin
            s = (v < 0.0);
            m = s ? -v : v;
            e = 0;
            while (m >= 2.0) begin m = m / 2.0; e = e + 1; end
            while (m < 1.0) begin m = m * 2.0; e = e - 1; end
            m = m * 8.0;
            fl = $floor(m);
            fr = m - fl;
            r = $rtoi(fl);
            if (fr > 0.5 || (fr == 0.5 && (r % 2 == 1))) r = r + 1;
            if (r == 16) begin r = 8; e = e + 1; end
            eb = e + bias;
            if (eb > 15) cf8_enc = {1'b0, s, 7'h7F};
            else if (eb <= 0) cf8_enc = {1'b1, 8'h00}; // underflow
            else cf8_enc = {1'b0, s, eb[3:0], r[2:0]};
        end
    end
endfunction

function [8:0] ref_mul;
    input [7:0] a, b;
    input [5:0] bias;
    reg [8:0] r;
    begin
        r = cf8_enc(cf8_dec(a, bias) * cf8_dec(b, bias), bias);
        ref_mul = {r[8] | (a[6:3] == 0 && a[2:0] != 0) | (b[6:3] == 0 && b[2:0] != 0), r[7:0]};
    end
endfunction

function [8:0] ref_add;
    input [7:0] x, y;
    input [5:0] bias;
    reg [8:0] r;
    begin
        r = cf8_enc(cf8_dec(x, bias) + cf8_dec(y, bias), bias);
        ref_add = {r[8] | (x[6:3] == 0 && x[2:0] != 0) | (y[6:3] == 0 && y[2:0] != 0), r[7:0]};
    end
endfunction
