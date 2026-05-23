module scaling_unit #(parameter N=2)(

    input clk,
    input start,

    input signed [31:0] SCORE [0:N-1][0:N-1],

    output reg signed [31:0] SCALE [0:N-1][0:N-1],
    output reg done
);

integer i,j;

always @(posedge clk) begin

    if(start) begin

        for(i=0;i<N;i=i+1) begin

            for(j=0;j<N;j=j+1) begin

                SCALE[i][j] = SCORE[i][j] >>> 1;
            end
        end

        done <= 1;
    end
end

endmodule
