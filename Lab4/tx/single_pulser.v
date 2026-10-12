module single_pulser (
    input clk,
    input rst,
    input btn_in,
    output pulse
);

    wire btn_sync;
    reg btn_sync_prev;

    ff_sync ff_sync_u (
        .clk(clk),
        .rst(rst),
        .async_in(btn_in),
        .sync_out(btn_sync)
    );

    always @(posedge clk) begin
        if (rst) btn_sync_prev <= 0;
        else btn_sync_prev <= btn_sync;
    end

    assign pulse = !btn_sync_prev & btn_sync;

endmodule
