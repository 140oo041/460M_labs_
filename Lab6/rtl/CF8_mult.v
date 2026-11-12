module  CF8_mult #(parameter [3:0] EXP_BIAS = 4'd7) (
    input [7:0] a,b,
    output [7:0] c
);

    wire sign_a = a[7];
    wire sign_b = b[7];

    wire [3:0] exp_a = a[6:3];
    wire [3:0] exp_b = b[6:3];

    wire [2:0] frac_a = a[2:0];
    wire [2:0] frac_b = b[2:0];

    wire [7:0] product = {1'b1,frac_a} * {1'b1,frac_b};
    wire [3:0] exp_product = exp_a + exp_b - EXP_BIAS;


    reg [3:0] exp_product_norm;
    reg [7:0] product_norm;

    always @(*) begin
        if (product[7]) begin
            exp_product_norm = exp_product + 1;
            product_norm = {1'b0,product[7:1]};
        end else begin
            exp_product_norm = exp_product;
            product_norm = product;
        end
    end

    wire [7:0] result = {sign_a ^ sign_b, exp_product_norm, product_norm[5:3]};
    
endmodule