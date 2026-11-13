// cfloat8 multiplier
module cf8_mul (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [5:0] bias,
    output wire [7:0] p
);
    wire [3:0] ea = a[6:3];
    wire [3:0] eb = b[6:3];
    wire sign = a[7] ^ b[7];
    wire zero = (ea == 4'd0) | (eb == 4'd0);

    wire [7:0] prod = {1'b1, a[2:0]} * {1'b1, b[2:0]};
    wire hi = prod[7]; // product is 2.0 or more

    wire [2:0] frac = hi ? prod[6:4] : prod[5:3];
    wire guard = hi ? prod[3] : prod[2];
    wire sticky = hi ? (|prod[2:0]) : (|prod[1:0]);
    wire up = guard & (sticky | frac[0]); // nearest even
    wire [3:0] frac_r = {1'b0, frac} + {3'b0, up};

    wire [9:0] e = {6'b0, ea} + {6'b0, eb} - {4'b0, bias} + {9'b0, hi} + {9'b0, frac_r[3]};
    wire under = e[9] | (e == 10'd0);
    wire over = ~e[9] & (e > 10'd15);

    assign p = (zero | under) ? 8'h00 :
        over ? {sign, 7'h7F} :
        {sign, e[3:0], frac_r[2:0]};
endmodule
