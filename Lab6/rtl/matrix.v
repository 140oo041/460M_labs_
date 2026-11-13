// 3x3 systolic array matrix multiplier
module Matrix (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [5:0] bias,
    input wire [7:0] a00, a01, a02, a10, a11, a12, a20, a21, a22,
    input wire [7:0] b00, b01, b02, b10, b11, b12, b20, b21, b22,
    output wire busy,
    output wire done,
    output wire [7:0] c00, c01, c02, c10, c11, c12, c20, c21, c22
);
    reg busy_r = 1'b0;
    reg done_r = 1'b0;
    reg [2:0] cnt = 3'd0; // compute cycle 1..7 while busy
    reg [5:0] bias_l = 6'd0;
    reg [7:0] la00 = 8'h00, la01 = 8'h00, la02 = 8'h00,
        la10 = 8'h00, la11 = 8'h00, la12 = 8'h00,
        la20 = 8'h00, la21 = 8'h00, la22 = 8'h00;
    reg [7:0] lb00 = 8'h00, lb01 = 8'h00, lb02 = 8'h00,
        lb10 = 8'h00, lb11 = 8'h00, lb12 = 8'h00,
        lb20 = 8'h00, lb21 = 8'h00, lb22 = 8'h00;

    wire accept = ~reset & ~busy_r & start;
    wire clear = reset | accept;

    always @(posedge clk) begin
        if (reset) begin
            busy_r <= 1'b0;
            done_r <= 1'b0;
            cnt <= 3'd0;
        end else if (accept) begin
            {la00, la01, la02, la10, la11, la12, la20, la21, la22} <=
                {a00, a01, a02, a10, a11, a12, a20, a21, a22};
            {lb00, lb01, lb02, lb10, lb11, lb12, lb20, lb21, lb22} <=
                {b00, b01, b02, b10, b11, b12, b20, b21, b22};
            bias_l <= bias;
            busy_r <= 1'b1;
            done_r <= 1'b0;
            cnt <= 3'd1;
        end else if (busy_r) begin
            if (cnt == 3'd7) begin
                busy_r <= 1'b0;
                done_r <= 1'b1;
                cnt <= 3'd0;
            end else begin
                cnt <= cnt + 3'd1;
            end
        end
    end

    assign busy = busy_r;
    assign done = done_r;

    // inputs are skewed and zero padded
    reg [7:0] ain0, ain1, ain2;
    reg [7:0] bin0, bin1, bin2;

    always @(*) begin
        ain0 = 8'h00; ain1 = 8'h00; ain2 = 8'h00;
        bin0 = 8'h00; bin1 = 8'h00; bin2 = 8'h00;
        case (cnt)
            3'd1: begin ain0 = la00; bin0 = lb00; end
            3'd2: begin ain0 = la01; ain1 = la10; bin0 = lb10; bin1 = lb01; end
            3'd3: begin
                ain0 = la02; ain1 = la11; ain2 = la20;
                bin0 = lb20; bin1 = lb11; bin2 = lb02;
            end
            3'd4: begin ain1 = la12; ain2 = la21; bin1 = lb21; bin2 = lb12; end
            3'd5: begin ain2 = la22; bin2 = lb22; end
            default: ;
        endcase
    end

    // a goes right, b goes down
    wire [7:0] ao00, ao01, ao02, ao10, ao11, ao12, ao20, ao21, ao22;
    wire [7:0] bo00, bo01, bo02, bo10, bo11, bo12, bo20, bo21, bo22;
    wire [7:0] acc00, acc01, acc02, acc10, acc11, acc12, acc20, acc21, acc22;

    cf8_pe pe00 (.clk(clk), .clear(clear), .en(busy_r), .bias(bias_l), .a_in(ain0), .b_in(bin0), .a_out(ao00), .b_out(bo00), .acc(acc00));
    cf8_pe pe01 (.clk(clk), .clear(clear), .en(busy_r), .bias(bias_l), .a_in(ao00), .b_in(bin1), .a_out(ao01), .b_out(bo01), .acc(acc01));
    cf8_pe pe02 (.clk(clk), .clear(clear), .en(busy_r), .bias(bias_l), .a_in(ao01), .b_in(bin2), .a_out(ao02), .b_out(bo02), .acc(acc02));

    cf8_pe pe10 (.clk(clk), .clear(clear), .en(busy_r), .bias(bias_l), .a_in(ain1), .b_in(bo00), .a_out(ao10), .b_out(bo10), .acc(acc10));
    cf8_pe pe11 (.clk(clk), .clear(clear), .en(busy_r), .bias(bias_l), .a_in(ao10), .b_in(bo01), .a_out(ao11), .b_out(bo11), .acc(acc11));
    cf8_pe pe12 (.clk(clk), .clear(clear), .en(busy_r), .bias(bias_l), .a_in(ao11), .b_in(bo02), .a_out(ao12), .b_out(bo12), .acc(acc12));

    cf8_pe pe20 (.clk(clk), .clear(clear), .en(busy_r), .bias(bias_l), .a_in(ain2), .b_in(bo10), .a_out(ao20), .b_out(bo20), .acc(acc20));
    cf8_pe pe21 (.clk(clk), .clear(clear), .en(busy_r), .bias(bias_l), .a_in(ao20), .b_in(bo11), .a_out(ao21), .b_out(bo21), .acc(acc21));
    cf8_pe pe22 (.clk(clk), .clear(clear), .en(busy_r), .bias(bias_l), .a_in(ao21), .b_in(bo12), .a_out(ao22), .b_out(bo22), .acc(acc22));

    // outputs stay 00 until done
    assign c00 = done_r ? acc00 : 8'h00;
    assign c01 = done_r ? acc01 : 8'h00;
    assign c02 = done_r ? acc02 : 8'h00;
    assign c10 = done_r ? acc10 : 8'h00;
    assign c11 = done_r ? acc11 : 8'h00;
    assign c12 = done_r ? acc12 : 8'h00;
    assign c20 = done_r ? acc20 : 8'h00;
    assign c21 = done_r ? acc21 : 8'h00;
    assign c22 = done_r ? acc22 : 8'h00;
endmodule
