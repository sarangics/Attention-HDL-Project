module score_unit #(parameter N=2, D=4)(

    input clk,
    input start,

    input signed [31:0] Q [0:N-1][0:D-1],
    input signed [31:0] K [0:N-1][0:D-1],

    output reg signed [31:0] SCORE [0:N-1][0:N-1],
    output reg done
);

integer i,j,k;

always @(posedge clk) begin

    if(start) begin

        for(i=0;i<N;i=i+1) begin

            for(j=0;j<N;j=j+1) begin

                SCORE[i][j] = 0;

                for(k=0;k<D;k=k+1) begin

                    SCORE[i][j] =
                        SCORE[i][j] +
                        Q[i][k] * K[j][k];
                end

            end
        end

        done <= 1;
    end
end

endmodule