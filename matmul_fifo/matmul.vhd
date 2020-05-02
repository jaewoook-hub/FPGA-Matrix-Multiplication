library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity matmul is
generic(
	constant N: integer := 8
	);
	
port (
	clock: in STD_LOGIC;
	reset: in STD_LOGIC;
	x_dout: in STD_LOGIC_VECTOR (31 downto 0);
	x_empty: in STD_LOGIC;
	x_rd_en: out STD_LOGIC;
	done_o_x: out STD_LOGIC;
	y_dout: in STD_LOGIC_VECTOR (31 downto 0);
	y_empty: in STD_LOGIC;
	y_rd_en: out STD_LOGIC;
	z_din: out STD_LOGIC_VECTOR (31 downto 0);
	z_full: in STD_LOGIC;
	z_wr_en: out STD_LOGIC
	);
end entity matmul;

architecture behavioral of matmul is
	type state_type is (s0,s1);
	type state_type2 is (s0,s1,done);
	signal state,next_state: state_type2;
	signal x_state,x_state_c: state_type;
	signal y_state,y_state_c: state_type;
	signal xk,xk_c,yk,yk_c,ykk,ykk_c,zk,zk_c: integer;
	signal done_x,done_x_c: STD_LOGIC;
	signal done_y,done_y_c: STD_LOGIC;
	signal done_z,done_z_c: STD_LOGIC;
	type ARRAY_SLV32 is array (natural range <>) of STD_LOGIC_VECTOR(31 downto 0);
	type MATRIX_SLV32 is array(natural range <>) of ARRAY_SLV32(0 to N-1);
	signal x,x_c: ARRAY_SLV32(0 to N-1);
	signal y,y_c: MATRIX_SLV32(0 to N-1);
	function MATMUL_N(A:ARRAY_SLV32(0 to N-1); B:ARRAY_SLV32(0 to N-1)) return STD_LOGIC_VECTOR is
		variable c: STD_LOGIC_VECTOR (31 downto 0);
	begin
		c:= (others=>'0');
		for m in 0 to N-1 loop
			c:= STD_LOGIC_VECTOR(signed(c)+resize(signed(A(m))*signed(B(m)),32));
		end loop;
		return c;
	end MATMUL_N;
begin

read_x_process: process(x_dout,xk,x_state,done_y,done_x,x,x_empty,done_z)
	variable xk_tmp: integer;
begin
	done_x_c <= done_x;
	x_state_c <= x_state;
	x_c <= x;
	xk_c <= xk;
	x_rd_en <= '0';
	for m in 0 to N-1 loop
		x_c(m) <= x(m);
	end loop;
	case x_state is
		when s0 =>
			xk_c <= 0;
			done_x_c <= '0';
			if (x_empty='0' and done_y='1' and done_z='1') then
				x_state_c <= s1;
			end if;
		when s1=>
			x_c(xk) <= x_dout;
			xk_tmp:= xk+1;
			xk_c <= xk_tmp;
			x_rd_en <= '1';
			if (xk=N-1) then
				done_x_c <= '1';
				x_state_c <= s0;
			else
				x_state_c <= s1;
			end if;
		when OTHERS=>
			done_x_c <= 'X';
			x_state_c <= s0;
			x_c <= (others=>(others=>'X'));
	end case;
end process read_x_process;

read_y_process: process(y_dout,yk,ykk,y_state,done_y,y,y_empty)
	variable yk_tmp,ykk_tmp: integer;
begin
	yk_c <= yk;
	ykk_c <= ykk;
	y_c <= y;
	done_y_c <= done_y;
	y_state_c <= y_state;
	y_rd_en <= '0';
	case y_state is 
		when s0=>
			yk_c <= 0;
			ykk_c <= 0;
			if y_empty='0' then
				done_y_c <= '0';
				y_state_c <= s1;
			end if;
		when s1=>
			y_c(yk)(ykk) <= y_dout;
			y_rd_en <= '1';
			if (yk<N-1) then
				yk_tmp:=yk+1;
			elsif (yk=N-1) then
				if (ykk<N-1) then
					yk_tmp:=0;
					ykk_tmp:=ykk+1;
					ykk_c <= ykk_tmp;
				elsif (ykk=N-1) then
					done_y_c <= '1';
					y_state_c <= s0;
				end if;
			else
				y_state_c <= s1;
			end if;
			yk_c <= yk_tmp;
		when OTHERS=>
			done_y_c <= 'X';
			y_state_c <= s0;
			y_c <= (others => (others => (others=>'X')));
	end case;
end process read_y_process;

matmul_fsm_process: process(state,y_dout,y_empty,x_dout,x_empty,y,x,z_full,zk,done_z,done_x_c,done_y_c)
	variable c: STD_LOGIC_VECTOR(31 downto 0);
	variable zk_tmp: integer;
begin
	z_din <= X"00000000";
	z_wr_en <= '0';
	zk_c <= zk;
	done_z_c <= done_z;
	next_state <= state;
	case state is
		when s0=>
			zk_c <= 0;
			done_z_c <= '1';
			if (z_full='0' and done_x_c='1' and done_y_c='1') then
				done_z_c <= '0';
				next_state <= s1;
			end if;
		when s1=>
			z_wr_en <= '1';
			z_din <= MATMUL_N(x,y(zk));
			zk_tmp:=zk+1;
			zk_c <= zk_tmp;
			done_z_c <= '0';
			if (zk=N-1) then
				next_state <= s0;
			else
				next_state <= s1;
			end if;
		when done=>
			done_z_c <= '1';
		when OTHERS=>
			z_din <= (others=>'X');
			z_wr_en <= 'X';
			next_state <= s0;
	end case;
end process matmul_fsm_process;

matmul_reg_process: process(reset,clock)
begin
if reset='1' then
	state <= s0;
	x_state <= s0;
	xk <= 0;
	done_x <= '0';
	x <= (others=>(others=>'0'));
	y_state <= s0;
	yk <= 0;
	ykk <= 0;
	done_y <= '0';
	done_z <= '0';
	y <= (others=>(others=>(others=>'0')));
elsif rising_edge(clock) then
	state <= next_state;
	x_state <= x_state_c;
	xk <= xk_c;
	done_x <= done_x_c;
	for m in 0 to 7 loop
		x(m) <= x_c(m);
	end loop;
	y_state <= y_state_c;
	yk <= yk_c;
	ykk <= ykk_c;
	done_y <= done_y_c;
	for m in 0 to 7 loop
		y(m) <= y_c(m);
	end loop;
	zk <= zk_c;
	done_z <= done_z_c;
end if;
end process matmul_reg_process;

done_o_x <= done_x_c;

end architecture behavioral;

--  loop unrolled for matmul --
 
--	type state_type is (s0,s1);
--	signal state,next_state: state_type;
--	signal x_state,x_state_c: state_type;
--	signal y_state,y_state_c: state_type;
--	signal i,i_c,j,j_c: STD_LOGIC_VECTOR(AWIDTH-1 downto 0);
--	signal xk,xk_c,yk_yk_c: STD_LOGIC_VECTOR(AWIDTH-1 downto 0);
--	signal done_o,done_c: STD_LOGIC;
--	signal start_x,start_x_c,done_x,done_x_c: STD_LOGIC;
--	signal start_y,start_y_c,done_y,done_y_c: STD_LOGIC;
--	type ARRAY_SLV32 is array (natural range <>) of STD_LOGIC_VECTOR(31 downto 0);
--	signal x,x_c,y,y_c: ARRAY_SLV32(0 to N-1);
--	
--	function MATMUL_N(A:ARRAY_SLV32(0 to N-1); B:ARRAY_SLV32(0 to N-1)) return STD_LOGIC_VECTOR is
--		variable c: STD_LOGIC_VECTOR (31 downto 0);
--	begin
--		c:= (others=>'0');
--		for m in 0 to N-1 loop
--			c:= STD_LOGIC_VECTOR(signed(c)+resize(signed(A(m))*signed(B(m)),32));
--		end loop;
--		return c;
--	end MATMUL_N;
--begin
--
--read_x_process: process(start_x,x_dout,i,xk,x_state,done_x,x)
--	variable xk_tmp: STD_LOGIC_VECTOR(AWIDTH-1 downto 0);
--begin
--	x_addr <= (others=>'0');
--	xk_c <= xk;
--	done_x_c <= done_x;
--	x_state_c <= x_state;
--	for m in 0 to N-1 loop
--		x_c(m) <= x(m);
--	end loop;
--	case x_state is
--		when s0 =>
--			xk_c <= (others => '0');
--			x_addr <= std_logic_vector(resize(unsigned(i)*to_unsigned(N,AWIDTH),AWIDTH));
--			if start_x='1' then
--				done_x_c <= '0';
--				x_state_c <= s1;
--			else 
--				x_state_c <= s0;
--			end if;
--		when s1=>
--			x_c(to_integer(unsigned(xk))) <= x_dout;
--			xk_tmp:= STD_LOGIC_VECTOR((unsigned(xk)+to_unsigned(1,AWIDTH)) mod N);
--			x_addr <= STD_LOGIC_VECTOR(resize(unsigned(i)*to_unsigned(N,AWIDTH),AWIDTH)+unsigned(xk_tmp));
--			xk_c <= xk_tmp;
--			if (unsigned(xk)=to_unsigned(N-1,AWIDTH)) then
--				done_x_c <= '1';
--				x_state_c <= s0;
--			else
--				x_state_c <= s1;
--			end if;
--		when OTHERS=>
--			x_addr <= (others=>'X');
--			xk_c <= (others=>'X');
--			done_x_c <= 'X';
--			x_state_c <= s0;
--			x_c <= (others=>(others=>'X'));
--	end case;
--end process read_x_process;
--
--read_y_process: process(start_y,y_dout,j,yk,y_state,done_y,y)
--	variable yk_tmp: STD_LOGIC_VECTOR(AWIDTH-1 downto 0);
--begin
--	y_addr <= (others=>'0');
--	yk_c <= yk;
--	done_y_c <= done_y;
--	y_state_c <= y_state;
--	for m in 0 to N-1 loop
--		y_c(m) <= y(m);
--	end loop;
--	
--	case y_state is 
--		when s0=>
--			yk_c <= (others=>'0');
--			y_addr <= j;
--			if start_y='1' then
--				done_y_c <= '0';
--				y_state_c <= s1;
--			else
--				y_state_c <= s0;
--			end if;
--		when s1=>
--			y_c(to_integer(unsigned(yk))) <= y_dout;
--			yk_tmp:= STD_LOGIC_VECTOR((unsigned(yk)+to_unsigned(1,AWIDTH)) mod N);
--			y_addr <= STD_LOGIC_VECTOR(resize(unsigned(yk_tmp)*to_unsigned(N,AWIDTH),AWIDTH)+unsigned(j));
--			yk_c <= yk_tmp;
--			if (unsigned(yk)=to_unsigned(N-1,AWIDTH)) then
--				done_y_c <= '1';
--				y_state_c <= s0;
--			else
--				y_state_c <= s1;
--			end if;
--		when OTHERS=>
--			y_addr <= (others=>'X');
--			yk_c <= (others => 'X');
--			done_y_c <= 'X';
--			y_state_c <= s0;
--			y_c <= (others => (others => 'X'));
--	end case;
--end process read_y_process;
--
--matmul_fsm_process: process(state,x,y,i,j,done_o,start,start_x,start_y,done_x,done_y)
--	variable i_tmp,j_tmp: STD_LOGIC_VECTOR(AWIDTH-1 downto 0);
--	variable c: STD_LOGIC_VECTOR(31 downto 0);
--begin
--	z_din <= X"00000000";
--	z_wr_en <= '0';
--	z_addr <= (others=>'0');
--	i_c <= i;
--	j_c <= j;
--	done_c <= done_o;
--	next_state <= state;
--	start_x_c <= '0';
--	start_y_c <= '0';
--	case state is
--		when s0=>
--			i_c <= (others=>'0');
--			j_c <= (others=>'0');
--			if start='1' then
--				start_x_c <= '1';
--				start_y_c <= '1';
--				done_c <= '0';
--				next_state <= s1;
--			end if;
--		when s1=>
--			if (start_x='0' and done_x='1' and start_y='0' and done_y='1') then
--				next_state <= s1;
--				j_c <= std_logic_vector((unsigned(j)+to_unsigned(1,AWIDTH)) mod N);
--				z_din <= MATMUL_N(x,y);
--				z_addr <= STD_LOGIC_VECTOR(resize(unsigned(i)*to_unsigned(N,AWIDTH),AWIDTH)+unsigned(j));
--				z_wr_en <= '1';
--				start_y_c <= '1';
--				if (unsigned(j)=to_unsigned(N-1,AWIDTH)) then
--					i_c <= STD_LOGIC_VECTOR((unsigned(i)+to_unsigned(1,AWIDTH)) mod N);
--					start_x_c <= '1';
--					if (unsigned(i)=to_unsigned(N-1,AWIDTH)) then
--						done_c <= '1';
--						next_state <= s0;
--					end if;
--				end if;
--			end if;
--		when OTHERS=>
--			z_din <= (others=>'X');
--			z_wr_en <= 'X';
--			z_addr <= (others=>'X');
--			i_c <= (others=>'X');
--			j_c <= (others=>'X');
--			done_c <= 'X';
--			next_state <= s0;
--	end case;
--end process matmul_fsm_process;
--
--matmul_reg_process: process(reset,clock)
--begin
--if reset='1' then
--	state <= s0;
--	i <= (others=>'0');
--	j <= (others=>'0');
--	done_o <= '0';
--	start_x <= '0';
--	start_y <= '0';
--	x_state <= s0;
--	xk <= (others=>'0');
--	done_x <= '0';
--	x <= (others=>(others=>'0'));
--	y_state <= s0;
--	yk <= (others=>'0');
--	done_y <= '0';
--	y <= (others=>(others=>'0'));
--elsif rising_edge(clock) then
--	state <= next_state;
--	i <= i_c;
--	j <= j_c;
--	done_o <= done_c;
--	start_x <= start_x_c;
--	start_y <= start_y_c;
--	x_state <= x_state_c;
--	xk <= xk_c;
--	done_x <= done_x_c;
--	for m in 0 to 7 loop
--		x(m) <= x_c(m);
--	end loop;
--	y_state <= y_state_c;
--	yk <= yk_c;
--	done_y <= done_y_c;
--	for m in 0 to 7 loop
--		y(m) <= y_c(m);
--	end loop;
--end if;
--end process matmul_reg_process;
--done <= done_o;
