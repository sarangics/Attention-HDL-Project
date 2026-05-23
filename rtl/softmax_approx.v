`timescale 1ns/1ps

module softmax_approx #(
    parameter N = 2                 // number of tokens
)(
    input  wire                          clk,
    input  wire                          start,
    input  signed [31:0]  SCALE  [0:N-1][0:N-1],
    output reg   signed [31:0]  WEIGHT [0:N-1][0:N-1],
    output reg                           done
);

    // ── loop indices ───────────────────────────────────────────
    integer i, j;

    // ── per-row temporaries (module-level regs) ────────────────
    reg signed [31:0] max_val;
    reg signed [31:0] shifted  [0:N-1];  
    reg        [31:0] exp_val  [0:N-1]; 
    reg        [63:0] sum_exp;           

    function [31:0] exp_lut;
        input signed [31:0] x;
        reg [31:0] abs_x;
        begin
            if (x >= 0) begin
                exp_lut = 32'd256;          // exp(0) = 1.0
            end else begin
                abs_x = -x;                 // magnitude of negative x
                if      (abs_x == 32'd1)  exp_lut = 32'd94;
                else if (abs_x == 32'd2)  exp_lut = 32'd35;
                else if (abs_x == 32'd3)  exp_lut = 32'd13;
                else if (abs_x == 32'd4)  exp_lut = 32'd5;
                else if (abs_x == 32'd5)  exp_lut = 32'd2;
                else if (abs_x == 32'd6)  exp_lut = 32'd1;
                else                      exp_lut = 32'd0;  // exp(−7+) ≈ 0
            end
        end
    endfunction

    // ── main FSM ───────────────────────────────────────────────
    always @(posedge clk) begin

        if (start) begin

            for (i = 0; i < N; i = i + 1) begin

                // ── STEP 1 : find row maximum ──────────────────
                max_val = SCALE[i][0];
                for (j = 1; j < N; j = j + 1)
                    if (SCALE[i][j] > max_val)
                        max_val = SCALE[i][j];

                // ── STEP 2 : subtract max, apply exp LUT ───────
                sum_exp = 64'd0;
                for (j = 0; j < N; j = j + 1) begin
                    shifted[j]  = SCALE[i][j] - max_val;   // always ≤ 0
                    exp_val[j]  = exp_lut(shifted[j]);
                    sum_exp     = sum_exp + {32'd0, exp_val[j]};
                end

                // ── STEP 3 : normalise ─────────────────────────
                
                for (j = 0; j < N; j = j + 1) begin
                    if (sum_exp != 64'd0)
                        WEIGHT[i][j] = (exp_val[j] * 32'd256) / sum_exp[31:0];
                    else
                        WEIGHT[i][j] = 32'd0;
                end

            end // for i

            done <= 1'b1;

        end else begin
            done <= 1'b0;
        end

    end 

endmodule