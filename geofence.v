module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output valid;
output is_inside;

parameter IDLE=3'd0,
          SORT=3'd1,
          ANALYZE=3'd2,
          DONE=3'd3;

reg [2:0] state, n_state;
reg [3:0] counter, next_counter;
reg [9:0] obj_x, obj_y;
reg [9:0] x0, x1, x2, x3, x4, x5;
reg [9:0] y0, y1, y2, y3, y4, y5;

reg [9:0] t0_x, t0_y;
reg [9:0] t1_x, t1_y;
reg [9:0] t2_x, t2_y;

reg count;
reg [5:0] check;

reg [10:0] vec1_x, vec2_x;
reg [10:0] vec1_y, vec2_y;
reg [21:0] tmp0, tmp1;
reg [22:0] cross_result;

wire read, sort, analyze_en;


// output signal
assign valid=(state==DONE)?1'b1:1'b0;
assign is_inside=(check==6'b111111||6'b000000)?1'b1:1'b0;

assign read=(state==IDLE)?1'b1:1'b0;
assign sort=(state==SORT)?1'b1:1'b0;
assign analyze_en=(state==ANALYZE)?1'b1:1'b0;


// FSM
always@(posedge clk or posedge reset)begin
    if(reset)begin
        state<=IDLE;
    end
    else begin
        state<=n_state;
    end
end
always@(*)begin
    case(state)
        IDLE:begin
            if(counter==4'd6)begin
                n_state=SORT;
            end
            else begin
                n_state=state;
            end
        end
        SORT:begin
            if(counter==4'd9)begin
                n_state=ANALYZE;
            end
            else begin
                n_state=state;
            end
        end
        ANALYZE:begin
            if(counter==4'd5)begin
                n_state=DONE;
            end
            else begin
                n_state=state;
            end
        end
        DONE:begin
            n_state=IDLE;
        end
        default:begin
            n_state=IDLE;
        end
    endcase
end

// count control
always@(*)begin
    case(state)
        IDLE:count=1'b1;
        SORT:count=1'b1;
        ANALYZE:count=1'b1;
        DONE:count=1'b0;
        default:count=1'b0;
    endcase
end
always@(posedge clk or posedge reset)begin
    if(reset)begin
        counter<=4'd0;
    end
    else if(count)begin
        counter<=next_counter;
    end
    else begin
    end
end
always@(*)begin
    if(count)begin
        if(state==IDLE)begin
            if(counter==4'd6)begin
                next_counter=4'd0;
            end
            else begin
                next_counter=counter+4'd1;
            end
        end
        else if(state==SORT)begin
            if(counter==4'd9)begin
                next_counter=4'd0;
            end
            else begin
                next_counter=counter+4'd1;
            end
        end
        else if(state==ANALYZE)begin
            if(counter==4'd5)begin
                next_counter=4'd0;
            end
            else begin
                next_counter=counter+4'd1;
            end
        end
        else begin
            next_counter=counter;
        end
    end
    else begin
        next_counter=4'd0;
    end
end

// READ
always@(posedge clk or posedge reset)begin
    if(reset)begin
        obj_x<=10'd0;
        obj_y<=10'd0;
        x0<=10'd0;
        y0<=10'd0;
        x1<=10'd0;
        y1<=10'd0;
        x2<=10'd0;
        y2<=10'd0;
        x3<=10'd0;
        y3<=10'd0;
        x4<=10'd0;
        y4<=10'd0;
        x5<=10'd0;
        y5<=10'd0;
    end
    else if(read)begin
        case(counter)
            4'd0:begin
                obj_x<=X;
                obj_y<=Y;
            end
            4'd1:begin
                x0<=X;
                y0<=Y;
            end
            4'd2:begin
                x1<=X;
                y1<=Y;
            end
            4'd3:begin
                x2<=X;
                y2<=Y;
            end
            4'd4:begin
                x3<=X;
                y3<=Y;
            end
            4'd5:begin
                x4<=X;
                y4<=Y;
            end
            4'd6:begin
                x5<=X;
                y5<=Y;
            end
            default:begin
            end
        endcase
    end
// sorting
    else if(sort)begin
        if(cross_result[22]==1'b0)begin //swap when cross result > 0.
            case(counter)
                4'd0:begin
                    x1<=x2;
                    y1<=y2;
                    x2<=x1;
                    y2<=y1;
                end
                4'd1:begin
                    x1<=x3;
                    y1<=y3;
                    x3<=x1;
                    y3<=y1;
                end
                4'd2:begin
                    x1<=x4;
                    y1<=y4;
                    x4<=x1;
                    y4<=y1;
                end
                4'd3:begin
                    x1<=x5;
                    y1<=y5;
                    x5<=x1;
                    y5<=y1;
                end
                4'd4:begin
                    x2<=x3;
                    y2<=y3;
                    x3<=x2;
                    y3<=y2;
                end
                4'd5:begin
                    x2<=x4;
                    y2<=y4;
                    x4<=x2;
                    y4<=y2;
                end
                4'd6:begin
                    x2<=x5;
                    y2<=y5;
                    x5<=x2;
                    y5<=y2;
                end
                4'd7:begin
                    x3<=x4;
                    y3<=y4;
                    x4<=x3;
                    y4<=y3;
                end
                4'd8:begin
                    x3<=x5;
                    y3<=y5;
                    x5<=x3;
                    y5<=y3;
                end
                4'd9:begin
                    x4<=x5;
                    y4<=y5;
                    x5<=x4;
                    y5<=y4;
                end
                default:begin
                end
            endcase
        end
        else begin
        end
    end
    else begin
    end
end

// cross
always@(*)begin
    if(state==SORT)begin
        vec1_x = t1_x - t0_x;
        vec1_y = t1_y - t0_y;
        vec2_x = t2_x - t0_x;
        vec2_y = t2_y - t0_y;
    end
    else if(state==ANALYZE)begin
        vec1_x = t1_x - t0_x;
        vec1_y = t1_y - t0_y;
        vec2_x = t2_x - t1_x;
        vec2_y = t2_y - t1_y;
    end
    else begin
        vec1_x = 11'd0;
        vec1_y = 11'd0;
        vec2_x = 11'd0;
        vec2_y = 11'd0;
    end
    tmp0 = $signed(vec1_x) * $signed(vec2_y);
    tmp1 = $signed(vec2_x) * $signed(vec1_y);
    cross_result = $signed(tmp0) - $signed(tmp1);
end

// set cross point

always@(*)begin
// bubble sort
    if(sort)begin            
        t0_x=x0;
        t0_y=y0;
        case(counter)
            4'd0:begin
                t1_x=x1;
                t1_y=y1;
                t2_x=x2;
                t2_y=y2;
            end
            4'd1:begin
                t1_x=x1;
                t1_y=y1;
                t2_x=x3;
                t2_y=y3;
            end
            4'd2:begin
                t1_x=x1;
                t1_y=y1;
                t2_x=x4;
                t2_y=y4;
            end
            4'd3:begin
                t1_x=x1;
                t1_y=y1;
                t2_x=x5;
                t2_y=y5;
            end
            4'd4:begin
                t1_x=x2;
                t1_y=y2;
                t2_x=x3;
                t2_y=y3;
            end
            4'd5:begin
                t1_x=x2;
                t1_y=y2;
                t2_x=x4;
                t2_y=y4;
            end
            4'd6:begin
                t1_x=x2;
                t1_y=y2;
                t2_x=x5;
                t2_y=y5;
            end
            4'd7:begin
                t1_x=x3;
                t1_y=y3;
                t2_x=x4;
                t2_y=y4;
            end
            4'd8:begin
                t1_x=x3;
                t1_y=y3;
                t2_x=x5;
                t2_y=y5;
            end
            4'd9:begin
                t1_x=x4;
                t1_y=y4;
                t2_x=x5;
                t2_y=y5;
            end
            default:begin
                t1_x=10'd0;
                t1_y=10'd0;
                t2_x=10'd0;
                t2_y=10'd0;
            end
        endcase
    end
// analyze
    else if(analyze_en)begin
        t0_x=obj_x;
        t0_y=obj_y;
        case(counter)
            4'd0:begin
                t1_x=x0;
                t1_y=y0;
                t2_x=x1;
                t2_y=y1;
            end
            4'd1:begin
                t1_x=x1;
                t1_y=y1;
                t2_x=x2;
                t2_y=y2;
            end
            4'd2:begin
                t1_x=x2;
                t1_y=y2;
                t2_x=x3;
                t2_y=y3;
            end
            4'd3:begin
                t1_x=x3;
                t1_y=y3;
                t2_x=x4;
                t2_y=y4;
            end
            4'd4:begin
                t1_x=x4;
                t1_y=y4;
                t2_x=x5;
                t2_y=y5;
            end
            4'd5:begin
                t1_x=x5;
                t1_y=y5;
                t2_x=x0;
                t2_y=y0;
            end
            default:begin
                t1_x=10'd0;
                t1_y=10'd0;
                t2_x=10'd0;
                t2_y=10'd0;
            end
        endcase
    end
    else begin
        t0_x=10'd0;
        t0_y=10'd0;
        t1_x=10'd0;
        t1_y=10'd0;
        t2_x=10'd0;
        t2_y=10'd0;
    end
end

always@(posedge clk or posedge reset)begin
    if(reset)begin
        check<=6'd0;
    end
    else if(analyze_en)begin
        check[counter]<=cross_result[22];
    end
    else begin
        check<=6'd0;
    end
end



endmodule

