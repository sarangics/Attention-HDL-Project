module controller_fsm(

    input clk,
    input rst,

    // done signals from modules
    input load_done,
    input qkv_done,
    input score_done,
    input scale_done,
    input softmax_done,
    input output_done,
    input write_done,

    // control signals to modules
    output reg load_start,
    output reg qkv_start,
    output reg score_start,
    output reg scale_start,
    output reg softmax_start,
    output reg output_start,
    output reg write_start,

    output reg done
);

//
// STATE DEFINITIONS
//

parameter IDLE     = 3'd0;
parameter LOAD     = 3'd1;
parameter GEN_QKV  = 3'd2;
parameter SCORE    = 3'd3;
parameter SCALE    = 3'd4;
parameter SOFTMAX  = 3'd5;
parameter OUTPUT   = 3'd6;
parameter WRITE    = 3'd7;

//
// STATE REGISTERS
//

reg [2:0] current_state;
reg [2:0] next_state;

//
// STATE UPDATE
//

always @(posedge clk or posedge rst) begin

    if(rst)
        current_state <= IDLE;

    else
        current_state <= next_state;

end

//
// NEXT STATE LOGIC
//

always @(*) begin

    next_state = current_state;

    case(current_state)

    //--------------------------------
    IDLE:
    begin
        next_state = LOAD;
    end

    //--------------------------------
    LOAD:
    //--------------------------------
    begin
        if(load_done)
            next_state = GEN_QKV;
    end

    //--------------------------------
    GEN_QKV:
    //--------------------------------
    begin
        if(qkv_done)
            next_state = SCORE;
    end

    //--------------------------------
    SCORE:
    //--------------------------------
    begin
        if(score_done)
            next_state = SCALE;
    end

    //--------------------------------
    SCALE:
    //--------------------------------
    begin
        if(scale_done)
            next_state = SOFTMAX;
    end

    //--------------------------------
    SOFTMAX:
    //--------------------------------
    begin
        if(softmax_done)
            next_state = OUTPUT;
    end

    //--------------------------------
    OUTPUT:
    //--------------------------------
    begin
        if(output_done)
            next_state = WRITE;
    end

    //--------------------------------
    WRITE:
    //--------------------------------
    begin
        //if(write_done)
            //next_state = IDLE;
        

        if(write_done)
            next_state = WRITE;

   
        
    end

    default:
        next_state = IDLE;

endcase
end

//
// OUTPUT CONTROL LOGIC
//

always @(*) begin

    // default outputs

    load_start     = 0;
    qkv_start      = 0;
    score_start    = 0;
    scale_start    = 0;
    softmax_start  = 0;
    output_start   = 0;
    write_start    = 0;

    done           = 0;

    case(current_state)

    //--------------------------------
    // IDLE
    //--------------------------------
    IDLE:
    begin
        done = 0;
    end

    //--------------------------------
    // LOAD
    //--------------------------------
    LOAD:
    begin
        load_start = 1;
    end

    //--------------------------------
    // GEN_QKV
    //--------------------------------
    GEN_QKV:
    begin
        qkv_start = 1;
    end

    //--------------------------------
    // SCORE
    //--------------------------------
    SCORE:
    begin
        score_start = 1;
    end

    //--------------------------------
    // SCALE
    //--------------------------------
    SCALE:
    begin
        scale_start = 1;
    end

    //--------------------------------
    // SOFTMAX
    //--------------------------------
    SOFTMAX:
    begin
        softmax_start = 1;
    end

    //--------------------------------
    // OUTPUT
    //--------------------------------
    OUTPUT:
    begin
        output_start = 1;
    end

    //--------------------------------
    // WRITE
    //--------------------------------
    WRITE:
    begin
        //write_start = 1;
        write_start <= 0;
        @(posedge clk);
        write_start <= 1;
        @(posedge clk);
        write_start <= 0;
        done = 1;
    end

endcase
end

endmodule