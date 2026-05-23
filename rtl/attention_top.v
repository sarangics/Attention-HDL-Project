module attention_top(

    input clk,
    input rst
);

//
// PARAMETERS
//

parameter N = 2;
parameter D = 4;

//
// INPUT MEMORIES
//

reg signed [15:0] X  [0:N-1][0:D-1];

reg signed [15:0] WQ [0:D-1][0:D-1];
reg signed [15:0] WK [0:D-1][0:D-1];
reg signed [15:0] WV [0:D-1][0:D-1];

//
// INTERNAL BUFFERS
//

wire signed [31:0] Q [0:N-1][0:D-1];
wire signed [31:0] K [0:N-1][0:D-1];
wire signed [31:0] V [0:N-1][0:D-1];

wire signed [31:0] SCORE [0:N-1][0:N-1];
wire signed [31:0] SCALE [0:N-1][0:N-1];
wire signed [31:0] WEIGHT [0:N-1][0:N-1];

wire signed [31:0] OUT [0:N-1][0:D-1];

//
// FSM CONTROL SIGNALS
//

wire load_start;
wire qkv_start;
wire score_start;
wire scale_start;
wire softmax_start;
wire output_start;
wire write_start;

wire load_done;
wire qkv_done;
wire score_done;
wire scale_done;
wire softmax_done;
wire output_done;
wire write_done;

wire done;

//
// INTERNAL CONTROL
//

reg finished;

//
// FILE LOADING
//

integer i;
integer j;
integer outfile;

initial begin

    finished = 0;

    //
    // LOAD INPUT TOKENS
    //

    $readmemh("data/token.txt", X);

    //
    // LOAD WEIGHT MATRICES
    //

    $readmemh("data/wq.txt", WQ);
    $readmemh("data/wk.txt", WK);
    $readmemh("data/wv.txt", WV);

end

//
// LOAD DONE
//

assign load_done = 1'b1;

//
// FSM CONTROLLER
//

controller_fsm FSM (

    .clk(clk),
    .rst(rst),

    .load_done(load_done),
    .qkv_done(qkv_done),
    .score_done(score_done),
    .scale_done(scale_done),
    .softmax_done(softmax_done),
    .output_done(output_done),
    .write_done(write_done),

    .load_start(load_start),
    .qkv_start(qkv_start),
    .score_start(score_start),
    .scale_start(scale_start),
    .softmax_start(softmax_start),
    .output_start(output_start),
    .write_start(write_start),

    .done(done)
);

//
// Q GENERATION
//

matrix_mult #(N,D) Q_GEN (
    
    .clk(clk),
    .start(qkv_start),

    .A(X),
    .B(WQ),

    .C(Q),

    .done(qkv_done)
);

//
// K GENERATION
//

matrix_mult #(N,D) K_GEN (

    .clk(clk),
    .start(qkv_start),

    .A(X),
    .B(WK),

    .C(K),

    .done()
);

//
// V GENERATION
//

matrix_mult #(N,D) V_GEN (

    .clk(clk),
    .start(qkv_start),

    .A(X),
    .B(WV),

    .C(V),

    .done()
);

//
// SCORE UNIT
//

score_unit #(N,D) SCORE_UNIT (

    .clk(clk),
    .start(score_start),

    .Q(Q),
    .K(K),

    .SCORE(SCORE),

    .done(score_done)
);

//
// SCALING UNIT
//

scaling_unit #(N) SCALE_UNIT (

    .clk(clk),
    .start(scale_start),

    .SCORE(SCORE),

    .SCALE(SCALE),

    .done(scale_done)
);

//
// SOFTMAX APPROXIMATION
//

softmax_approx #(N) SOFTMAX_UNIT (

    .clk(clk),
    .start(softmax_start),

    .SCALE(SCALE),

    .WEIGHT(WEIGHT),

    .done(softmax_done)
);

//
// FINAL OUTPUT MAC
//

output_mac #(N,D) OUTPUT_UNIT (

    .clk(clk),
    .start(output_start),

    .W(WEIGHT),
    .V(V),

    .OUT(OUT),

    .done(output_done)
);

//
// OUTPUT FILE WRITING + DEBUG
//

always @(posedge clk or posedge rst) begin

    if(rst) begin

        finished <= 0;

    end

    else begin

        if(!finished) begin

            //
            // WRITE OUTPUT FILE
            //

            if(write_start) begin

                outfile = $fopen("output/output.txt","w");

                for(i=0;i<N;i=i+1) begin

                    for(j=0;j<D;j=j+1) begin

                        $fwrite(outfile,"%d ", OUT[i][j]);

                    end

                    $fwrite(outfile,"\n");

                end

                $fclose(outfile);

                finished <= 1;

            end

            //
            // DISPLAY Q/K/V
            //

            if(qkv_done) begin

                $display("\n========== Q MATRIX ==========");

                for(i=0;i<N;i=i+1) begin
                    for(j=0;j<D;j=j+1) begin

                        $display("Q[%0d][%0d] = %0d",
                                  i,j,Q[i][j]);

                    end
                end

                $display("\n========== K MATRIX ==========");

                for(i=0;i<N;i=i+1) begin
                    for(j=0;j<D;j=j+1) begin

                        $display("K[%0d][%0d] = %0d",
                                  i,j,K[i][j]);

                    end
                end

                $display("\n========== V MATRIX ==========");

                for(i=0;i<N;i=i+1) begin
                    for(j=0;j<D;j=j+1) begin

                        $display("V[%0d][%0d] = %0d",
                                  i,j,V[i][j]);

                    end
                end

            end

            //
            // DISPLAY SCORE
            //

            if(score_done) begin

                $display("\n========== SCORE MATRIX ==========");

                for(i=0;i<N;i=i+1) begin
                    for(j=0;j<N;j=j+1) begin

                        $display("SCORE[%0d][%0d] = %0d",
                                  i,j,SCORE[i][j]);

                    end
                end

            end

            //
            // DISPLAY SCALE
            //

            if(scale_done) begin

                $display("\n========== SCALE MATRIX ==========");

                for(i=0;i<N;i=i+1) begin
                    for(j=0;j<N;j=j+1) begin

                        $display("SCALE[%0d][%0d] = %0d",
                                  i,j,SCALE[i][j]);

                    end
                end

            end

            //
            // DISPLAY WEIGHTS
            //

            if(softmax_done) begin

                $display("\n========== SOFTMAX WEIGHTS ==========");

                for(i=0;i<N;i=i+1) begin
                    for(j=0;j<N;j=j+1) begin

                        $display("WEIGHT[%0d][%0d] = %0d",
                                  i,j,WEIGHT[i][j]);

                    end
                end

            end

            //
            // DISPLAY FINAL OUTPUT
            //

            if(output_done) begin

                $display("\n========== FINAL OUTPUT ==========");

                for(i=0;i<N;i=i+1) begin
                    for(j=0;j<D;j=j+1) begin

                        $display("OUT[%0d][%0d] = %0d",
                                  i,j,OUT[i][j]);

                    end
                end

            end

        end

    end

end

//
// WRITE DONE
//

assign write_done = write_start;

endmodule