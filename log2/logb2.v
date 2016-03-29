function integer logb2(input integer num);
	begin
		logb2 = 0;
		num = num-1;
		if(num)begin
			for(logb2=1;num>1;logb2=logb2+1)
			num =num>>1;
				end
	end
endfunction	