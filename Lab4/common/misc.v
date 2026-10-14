`timescale 1ns / 1ps

module synchronizer(input clk, input rst, input in_sig, output wire out_sig);

  reg FF1;
  reg FF2;


  always @(posedge clk or posedge rst) begin
    if (rst) begin
      FF1 <= 1'b0;
      FF2 <= 1'b0;
    end else begin
      FF1 <= in_sig;
      FF2 <= FF1;
    end
  end

  assign out_sig = FF2;
endmodule

module edge_detector
(input clk, input rst, input in_sig, output wire out_sig_rising_edge, output wire out_sig_falling_edge, output wire sync_out);

    wire SYNCH_SIG;
    reg FF3;
    synchronizer sync1(.clk(clk), .rst(rst), .in_sig(in_sig), .out_sig(SYNCH_SIG));
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            FF3 <= 1'b0;
        end else begin
            FF3 <= SYNCH_SIG;
        end
    end

    assign sync_out = SYNCH_SIG;
  assign out_sig_rising_edge = SYNCH_SIG & ~FF3; // Detect rising edge
  assign out_sig_falling_edge = ~SYNCH_SIG & FF3; // Detect falling edge
endmodule