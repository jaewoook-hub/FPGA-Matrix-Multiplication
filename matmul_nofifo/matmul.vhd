library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity matmul is
	generic (
		constant N : integer := 8;
		constant AWIDTH : integer := 6
	);
	port (
		signal clock : in std_logic;
		signal reset : in std_logic;
		signal start : in std_logic;
		signal done : out std_logic;		
		signal x_dout : in std_logic_vector (31 downto 0);
		signal y_dout : in std_logic_vector (31 downto 0);
		signal z_din : out std_logic_vector (31 downto 0);
		signal x_rd_addr : out std_logic_vector (AWIDTH-1 downto 0);
		signal y_rd_addr : out std_logic_vector (AWIDTH-1 downto 0);
		signal z_wr_addr : out std_logic_vector (AWIDTH-1 downto 0);		
		signal z_wr_en : out std_logic_vector (3 downto 0)
	);
end entity matmul;

architecture behavior of matmul is

	TYPE state_type is (s0,s1);
	signal state : state_type;
	signal next_state : state_type;
	signal i, i_c, j, j_c, k, k_c : std_logic_vector(AWIDTH-1 downto 0);
	signal z, z_c : std_logic_vector(31 downto 0);
	signal done_o, done_c : std_logic;
	
begin

matmul_reg_process : process(reset, clock)
begin
	if ( reset = '1' ) then
		state <= s0;
		i <= (others => '0');
		j <= (others => '0');
		k <= (others => '0');
		z <= (others => '0');
		done_o <= '0';
	elsif ( rising_edge(clock) ) then
		state <= next_state;
		i <= i_c;
		j <= j_c;
		k <= k_c;
		z <= z_c;
		done_o <= done_c;
	end if;
end process matmul_reg_process;

-------------------------------------------------------------------------------

matmul_fsm_process : process(state, y_dout, x_dout, i, j, k, z, done_o, start )

	variable i_tmp, j_tmp, k_tmp : std_logic_vector(AWIDTH-1 downto 0);
	variable z_tmp : std_logic_vector(31 downto 0);
	
begin

	z_din <= X"00000000";
	z_wr_en <= (others => '0');
	z_wr_addr <= (others => '0');
	x_rd_addr <= (others => '0');
	y_rd_addr <= (others => '0');
	i_c <= i; j_c <= j;
	k_c <= k; z_c <= z;
	done_c <= done_o;
	next_state <= state;
	
case ( state ) is
when s0 => 
		i_c <= (others => '0'); 
		j_c <= (others => '0'); 
		k_c <= (others => '0');
		x_rd_addr <= (others => '0'); 
		y_rd_addr <= (others => '0');	   
		if ( start = '1' ) then
			done_c <= '0';
			next_state <= s1;
		end if;
	
when s1 => 
		next_state <= s1;
		z_tmp := std_logic_vector(signed(z) + resize(signed(y_dout) * signed(x_dout), 32));
		k_tmp := std_logic_vector((unsigned(k) + to_unsigned(1,AWIDTH))mod N);
		j_tmp := j;
		i_tmp := i;
		   
		if ( unsigned(k) = to_unsigned(N-1,AWIDTH) ) then
			j_tmp := std_logic_vector((unsigned(j) + to_unsigned(1,AWIDTH)) mod N);
			z_din <= z_tmp;
			z_wr_addr <= std_logic_vector(resize(unsigned(i) * to_unsigned(N,AWIDTH),AWIDTH) + unsigned(j));
			z_wr_en <= "1111";
			z_tmp := (others => '0');
			if ( unsigned(j) = to_unsigned(N-1,AWIDTH) ) then
				i_tmp := std_logic_vector((unsigned(i) + to_unsigned(1,AWIDTH)) mod N);
				if ( unsigned(i) = to_unsigned(N-1,AWIDTH) ) then
					done_c <= '1';
					next_state <= s0;
				end if;
			end if;
		end if;
		i_c <= i_tmp;
		j_c <= j_tmp;
		k_c <= k_tmp;
		z_c <= z_tmp;
		x_rd_addr <= std_logic_vector(resize(unsigned(i_tmp) * to_unsigned(N,AWIDTH),AWIDTH) + unsigned(k_tmp));
		y_rd_addr <= std_logic_vector(resize(unsigned(k_tmp) * to_unsigned(N,AWIDTH),AWIDTH) + unsigned(j_tmp));

when OTHERS =>
	z_din <= (others => 'X');
	z_wr_addr <= (others => 'X');
	done_c <= 'X';
	next_state <= s0;

end case;
end process matmul_fsm_process;

done <= done_o;

end architecture behavior;