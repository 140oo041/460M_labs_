// cfloat8 adder, doesn't need the bias
module cf8_add (
    input wire [7:0] acc,
    input wire [7:0] p,
    output wire [7:0] acc_next
);
    wire zx = (acc[6:3] == 4'd0);
    wire zy = (p[6:3] == 4'd0);

    // big = larger magnitude
    wire x_big = (acc[6:0] >= p[6:0]);
    wire [7:0] big = x_big ? acc : p;
    wire [7:0] sml = x_big ? p : acc;

    wire [3:0] es = sml[6:3];
    wire [3:0] d = big[6:3] - es;
    wire sub = big[7] ^ sml[7];

    // shift the big one left by d so nothing gets lost
    wire [19:0] wb = {16'b0, 1'b1, big[2:0]} << d;
    wire [19:0] ws = {16'b0, 1'b1, sml[2:0]};
    wire [19:0] sum = sub ? (wb - ws) : (wb + ws);

    // count leading zeros by shifting 16, 8, 4, 2, 1
    wire z16 = ~|sum[19:4];
    wire [19:0] n1 = z16 ? {sum[3:0], 16'b0} : sum;
    wire z8 = ~|n1[19:12];
    wire [19:0] n2 = z8 ? {n1[11:0], 8'b0} : n1;
    wire z4 = ~|n2[19:16];
    wire [19:0] n3 = z4 ? {n2[15:0], 4'b0} : n2;
    wire z2 = ~|n3[19:18];
    wire [19:0] n4 = z2 ? {n3[17:0], 2'b0} : n3;
    wire z1 = ~n4[19];
    wire [19:0] n5 = z1 ? {n4[18:0], 1'b0} : n4;
    wire [4:0] lz = {z16, z8, z4, z2, z1};

    wire [2:0] frac = n5[18:16];
    wire guard = n5[15];
    wire sticky = |n5[14:0];
    wire up = guard & (sticky | frac[0]); // nearest even
    wire [3:0] frac_r = {1'b0, frac} + {3'b0, up};

    wire [7:0] e = {4'b0, es} + 8'd16 - {3'b0, lz} + {7'b0, frac_r[3]};
    wire under = e[7] | (e == 8'd0);
    wire over = ~e[7] & (|e[6:4]);
    wire zero = (sum == 20'd0);

    wire [7:0] calc = (zero | under) ? 8'h00 :
        over ? {big[7], 7'h7F} :
        {big[7], e[3:0], frac_r[2:0]};

    assign acc_next = (zx & zy) ? 8'h00 :
        zy ? acc :
        zx ? p :
        calc;
endmodule
