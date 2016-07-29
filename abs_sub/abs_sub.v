function [17:0] abs_sub;
input [17:0] a;
input [17:0] b;
abs_sub = (a>b)?(a-b):(b-a);
endfunction