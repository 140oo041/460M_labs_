// processing element, acc += a_in * b_in
module cf8_pe (
    input wire clk,
    input wire clear,
    input wire en,
    input wire [5:0] bias,
    input wire [7:0] a_in,
    input wire [7:0] b_in,
    output reg [7:0] a_out = 8'h00,
    output reg [7:0] b_out = 8'h00,
    output reg [7:0] acc = 8'h00
);
    wire [7:0] p;
    wire [7:0] acc_next;

    cf8_mul mul (.a(a_in), .b(b_in), .bias(bias), .p(p));
    cf8_add add (.acc(acc), .p(p), .acc_next(acc_next));

    always @(posedge clk) begin
        if (clear) begin
            a_out <= 8'h00;
            b_out <= 8'h00;
            acc <= 8'h00;
        end else if (en) begin
            a_out <= a_in;
            b_out <= b_in;
            acc <= acc_next;
        end
    end
endmodule
