module matrix_mult #(parameter N=2, D=4)(
    input clk,
    input start,

    input signed [15:0] A [0:N-1][0:D-1],
    input signed [15:0] B [0:D-1][0:D-1],

    output reg signed [31:0] C [0:N-1][0:D-1],
    output reg done
);

integer i,j,k;

always @(posedge clk) begin

    if(start) begin

        for(i=0;i<N;i=i+1) begin

            for(j=0;j<D;j=j+1) begin

                C[i][j] = 0;

                for(k=0;k<D;k=k+1) begin

                    C[i][j] = C[i][j] + A[i][k] * B[k][j];
                end

            end
        end

        done <= 1;
    end
end

endmodule