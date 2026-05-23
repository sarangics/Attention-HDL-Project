`timescale 1ns/1ps

module output_mac #(
    parameter N = 2,                // number of tokens
    parameter D = 4                 // embedding dimension
)(
    input  wire                         clk,
    input  wire                         start,

    input  signed [31:0] W   [0:N-1][0:N-1],   // softmax weights  Q8.8
    input  signed [31:0] V   [0:N-1][0:D-1],   // value matrix     integer

    output reg signed [31:0] OUT [0:N-1][0:D-1],
    output reg                          done
);

    integer i, j, k;

    // 64-bit accumulator to hold W*V before rescaling
    // W is 32-bit, V is 32-bit → product is up to 64-bit
    reg signed [63:0] acc;

    always @(posedge clk) begin

        if (start) begin

            for (i = 0; i < N; i = i + 1) begin
                for (j = 0; j < D; j = j + 1) begin

                    // ── accumulate W[i][k] × V[k][j] ──────────
                    acc = 64'sd0;
                    for (k = 0; k < N; k = k + 1)
                        acc = acc + $signed(W[i][k]) * $signed(V[k][j]);
                    OUT[i][j] <= acc >>> 8;

                end
            end

            done <= 1'b1;

        end else begin
            done <= 1'b0;
        end

    end

endmodule