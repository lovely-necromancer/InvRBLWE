`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    07:42:27 02/07/2018 
// Design Name: 
// Module Name:    encrypt 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
`define q 256 
`define log_q 8
`define n 256
`define nq 2048 //N * LOG Q
module encrypt(input [`nq-1:0]a, 
					input [`nq-1:0]p,
					input [`n-1:0]e1, 
					input [`n-1:0]e2, 
					input [`n-1:0]e3, 
					input [`n-1:0]m, 
					input clk, 
					input rst, 
					output reg [`nq-1:0]c1,
					output reg Valid	
					);

	reg [`log_q-1:0]in1[`n-1:0];
	reg [`log_q-1:0]in2[`n-1:0];
	reg [`log_q-1:0]out1[`n-1:0];
//	reg [`log_q-1:0]w1[`n-1:0];
	reg [`log_q-1:0]w2;
	wire [`log_q-1:0]w3;

	
	reg [`log_q-1:0]res[`n-1:0];
	reg [1:0] state, next_state;
	reg [`log_q-1:0] counter;
	reg [1:0] sel;
	reg [`n-1:0] e1_temp;
	
	
	parameter idle 			= 3'b000;
	parameter c1_mul 			= 3'b001;
	parameter c1_add 			= 3'b010;
	parameter wait_c2			= 3'b011;
	parameter c2_mul 			= 3'b100;
	parameter c2_add1 		= 3'b101;
	parameter c2_add2 		= 3'b110;
	
	
		always @* begin: mux4
		integer i;
		for (i=0; i<`n; i=i+1) begin
			if(sel == 2'b00) begin
				if(state == c1_mul) begin
					in1[i][0] = a[i*`log_q]& e1_temp[`n-1];
					in1[i][1] = a[i*`log_q + 1]& e1_temp[`n-1];
					in1[i][2] = a[i*`log_q + 2]& e1_temp[`n-1];
					in1[i][3] = a[i*`log_q + 3]& e1_temp[`n-1];
					in1[i][4] = a[i*`log_q + 4]& e1_temp[`n-1];
					in1[i][5] = a[i*`log_q + 5]& e1_temp[`n-1];
					in1[i][6] = a[i*`log_q + 6]& e1_temp[`n-1];
					in1[i][7] = a[i*`log_q + 7]& e1_temp[`n-1];
				end
				else begin
					in1[i][0] = p[i*`log_q]& e1_temp[`n-1];
					in1[i][1] = p[i*`log_q + 1]& e1_temp[`n-1];
					in1[i][2] = p[i*`log_q + 2]& e1_temp[`n-1];
					in1[i][3] = p[i*`log_q + 3]& e1_temp[`n-1];
					in1[i][4] = p[i*`log_q + 4]& e1_temp[`n-1];
					in1[i][5] = p[i*`log_q + 5]& e1_temp[`n-1];
					in1[i][6] = p[i*`log_q + 6]& e1_temp[`n-1];
					in1[i][7] = p[i*`log_q + 7]& e1_temp[`n-1];
				end
			end
			else begin
				in1[i][0] = 0;
				in1[i][1] = 0;
				in1[i][2] = 0;
				in1[i][3] = 0;
				in1[i][4] = 0;
				in1[i][5] = 0;
				in1[i][6] = 0;
				in1[i][7] = 0;
			end
				if(sel == 2'b01)
					in1[i][7] = e2[i];
				if(sel == 2'b10) 
					in1[i][7] = e3[i];
				else
					in1[i][0] = m[i];
		end
	end

	always @* begin: xor_input
		integer i;
		for (i=1; i<`n; i=i+1)
			in2[i] = res[i-1];
	end


	always @* begin
		if (sel == 0) begin
			in2[0][0] = ~res[`n-1][0];
			in2[0][1] = ~res[`n-1][1];
			in2[0][2] = ~res[`n-1][2];
			in2[0][3] = ~res[`n-1][3];
			in2[0][4] = ~res[`n-1][4];
			in2[0][5] = ~res[`n-1][5];
			in2[0][6] = ~res[`n-1][6];
			in2[0][7] = ~res[`n-1][7];
			end
		else
			in2[0] = res[`n-1];
	end
	
	
	always @* begin
		if (sel == 2'b00)
				out1[0] = in1[0] - in2[0];
		else
				out1[0] = in1[`n-1] + in2[0];
	end


	always @* begin: adder
		integer i;
		for (i=1; i<`n; i=i+1)
			out1[i] = in1[i-1] + in2[i];
	end


	always @* begin: outputing_cipher
		integer i;
		for (i=1; i<`n; i=i+1) begin
			c1[(i-1)*`log_q + 0] = res[i-1][0];
			c1[(i-1)*`log_q + 1] = res[i-1][1];
			c1[(i-1)*`log_q + 2] = res[i-1][2];
			c1[(i-1)*`log_q + 3] = res[i-1][3];
			c1[(i-1)*`log_q + 4] = res[i-1][4];
			c1[(i-1)*`log_q + 5] = res[i-1][5];
			c1[(i-1)*`log_q + 6] = res[i-1][6];
			c1[(i-1)*`log_q + 7] = res[i-1][7];
		end
	end
					
	
	always @(posedge clk) begin : registering
		integer i;
		for(i=0; i<`n; i=i+1) begin
			if(rst || state==idle || state==wait_c2)
				res[i][`log_q-1:0] = `log_q'b0;
			else 
				res[i][`log_q-1:0] = out1[i][`log_q-1:0];
			end
		if (state==idle || state == wait_c2) begin
			counter = 8'b0;
			e1_temp = e1;
			end
		else begin
			counter = counter + 1;
			e1_temp[`n-1:1] = e1_temp[`n-2:0];
			end
	end
	
	always @(posedge clk) begin
		if(rst)
			state <= idle;
		else
			state <= next_state;
	end
	
	always @* begin: FSM
		next_state = state;
		sel = 2'b00;
		case(state)
			idle: begin
				if(~rst)
					next_state = c1_mul;
				Valid = 0;
			end
			c1_mul: begin
				sel = 2'b00;
				if(counter == 8'b11111111)begin /// STATIC LOG N
					next_state = c1_add;
				end
				Valid = 0;
			end
			c1_add: begin
				sel = 2'b01;
				Valid = 0;
				
				next_state = wait_c2;
			end
			wait_c2: begin
				Valid = 1;
				if(rst)
					next_state = idle;
				else
					next_state = c2_mul;
			end
			c2_mul: begin
				sel = 2'b00;
				Valid = 0;
				if(counter == 8'b11111111) begin /// STATIC LOG N
					next_state = c2_add1;
				end
			end
			c2_add1: begin
				sel = 2'b10;
				next_state = c2_add2;
				Valid = 0;
			end
			c2_add2: begin
				sel = 2'b11;
				next_state = wait_c2;
				
				Valid = 0;
			end
			
		endcase
	end


endmodule


