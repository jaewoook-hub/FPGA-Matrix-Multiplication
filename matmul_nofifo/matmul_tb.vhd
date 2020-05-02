library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.constants.all;

entity matmul_tb is 
generic(
	constant X_NAME : string (5 downto 1) := "x.txt";
	constant Y_NAME : string (5 downto 1) := "y.txt";
	constant Z_NAME : string (5 downto 1) := "z.txt";
	constant CLOCK_PERIOD : time := 2 ns;
	constant DATA_SIZE : integer := 64);
end entity matmul_tb;

architecture behavior of matmul_tb is 
--clock, reset signals
	signal clock : std_logic:= '1';
	signal reset : std_logic:= '0';
	signal start : std_logic:= '0';
	signal done : std_logic:= '0';
--memory ports
	signal x_din: std_logic_vector(31 downto 0) := X"00000000";
	signal x_dout: std_logic_vector(31 downto 0) := X"00000000";
	signal x_rd_addr: std_logic_vector(5 downto 0) := B"000000";
	signal x_wr_addr: std_logic_vector(5 downto 0) := B"000000";
	signal x_wr_en: std_logic_vector(3 downto 0) := X"0";
	signal y_din: std_logic_vector(31 downto 0) := X"00000000";
	signal y_dout: std_logic_vector(31 downto 0) := X"00000000";
	signal y_rd_addr: std_logic_vector(5 downto 0) := B"000000";
	signal y_wr_addr: std_logic_vector(5 downto 0) := B"000000";
	signal y_wr_en: std_logic_vector(3 downto 0) := X"0";
	signal z_din: std_logic_vector(31 downto 0) := X"00000000";
	signal z_dout: std_logic_vector(31 downto 0) := X"00000000";
	signal z_rd_addr: std_logic_vector(5 downto 0) := B"000000";
	signal z_wr_addr: std_logic_vector(5 downto 0) := B"000000";
	signal z_wr_en: std_logic_vector(3 downto 0) := X"0";
--process sync signals
	signal hold_clock: std_logic:= '0';
	signal x_write_done: std_logic:= '0';
	signal y_write_done: std_logic:= '0';
	signal z_read_done: std_logic:= '0';
	signal z_errors: integer := 0;
	
begin
	matmul_top_inst: component matmul_top
	port map(
		clock => clock,
		reset => reset,
		start => start,
		done => done,
		x_wr_addr => x_wr_addr,
		x_wr_en=> x_wr_en,
		x_din => x_din,
		y_wr_addr => y_wr_addr,
		y_wr_en => y_wr_en,
		y_din => y_din,
		z_rd_addr => z_rd_addr,
		z_dout=> z_dout
		);
		
	clock_process: process 
	begin
		clock <= '1';
		wait for  (CLOCK_PERIOD / 2);
		clock <= '0';
		wait for  (CLOCK_PERIOD / 2);
		if ( hold_clock= '1' ) then
			wait;
		end if;
	end process clock_process;
	
	reset_process: process
	begin 
		reset <= '0';
		wait until (clock = '0');
		wait until (clock = '1');
		reset <= '1';
		wait until (clock = '0');
		wait until (clock = '1');
		reset <= '0';
		wait;
		end process reset_process;
		
	x_write_process: process 
		file x_file: text;
		variable rdx: std_logic_vector(31 downto 0);
		variable ln1, ln2 : line;
		variable x : integer := 0;
	begin
		wait until (reset = '1');
		wait until (reset = '0');
		write(ln1, string'("@ "));
		write(ln1, NOW);
		write(ln1, string'(": Loading file "));
		write(ln1, X_NAME);
		write(ln1, string'("..."));
		writeline(output, ln1);
		file_open( x_file, X_NAME, read_mode);
		
	for x in 0 to (DATA_SIZE -1) loop
		wait until (clock = '1');
		readline (x_file, ln2);
		hread(ln2, rdx);
		x_din <= std_logic_vector(rdx);
		x_wr_addr <= std_logic_vector(to_unsigned(x,6));
		x_wr_en<= "1111";
		wait until (clock = '0');
	end loop;
		wait until  (clock = '1');
		x_wr_en<= "0000";
		file_close( x_file);
		x_write_done<= '1';
		wait;
	end process x_write_process;
	
	y_write_process: process 
		file y_file: text;
		variable rdy: std_logic_vector(31 downto 0);
		variable ln1, ln2 : line;
		variable y : integer := 0;
	begin
		wait until (reset = '1');
		wait until (reset = '0');
		write(ln1, string'("@ "));
		write(ln1, NOW);
		write(ln1, string'(": Loading file "));
		write(ln1, y_NAME);
		write(ln1, string'("..."));
		writeline(output, ln1);
		file_open( y_file, y_NAME, read_mode);
		
	for y in 0 to (DATA_SIZE -1) loop
		wait until (clock = '1');
		readline (y_file, ln2);
		hread(ln2, rdy);
		y_din <= std_logic_vector(rdy);
		y_wr_addr <= std_logic_vector(to_unsigned(y,6));
		y_wr_en<= "1111";
		wait until (clock = '0');
	end loop;
		wait until  (clock = '1');
		y_wr_en<= "0000";
		file_close( y_file);
		y_write_done<= '1';
		wait;
	end process y_write_process;
	
	z_read_process: process 
		file z_file: text;
		variable rdz: std_logic_vector(31 downto 0);
		variable ln1, ln2 : line;
		variable z : integer := 0;
		variable z_data_read : std_logic_vector(31 downto 0);
		variable z_data_cmp : std_logic_vector(31 downto 0);
	begin
		wait until (reset = '1');
		wait until (reset = '0');
		wait until  (done = '1');
		wait until  (clock = '1');
		wait until  (clock = '0');
		write(ln1, string'("@ "));
		write(ln1, NOW);
		write(ln1, string'(": Comparing file "));
		write(ln1, Z_NAME);
		writeline(output, ln1);
		file_open(z_file, Z_NAME, read_mode);
		for z in 0 to (DATA_SIZE -1) loop
			wait until (clock = '0');
			z_rd_addr <= std_logic_vector(to_unsigned(z,6));
			wait until (clock = '1');
			wait until (clock = '0');
			readline(z_file, ln2);
			hread(ln2, rdz);
			z_data_cmp := std_logic_vector(rdz);
			z_data_read := z_dout;
			if (to_01(unsigned(z_data_read)) /= to_01(unsigned(z_data_cmp))) then 
				z_errors<= z_errors+ 1;
				write(ln2, string'("@ "));
				write(ln2, NOW);
				write(ln2, string'(": "));
				write(ln2, Z_NAME);
				write(ln2, string'("("));
				write(ln2, z + 1);
				write(ln2, string'("): ERROR: "));
				hwrite(ln2, z_data_read);
				write(ln2, string'(" != "));
				hwrite(ln2, z_data_cmp);
				write(ln2, string'(" at address 0x"));
				hwrite(ln2, std_logic_vector(to_unsigned(z,32)));
				write(ln2, string'("."));
				writeline(output, ln2);
			end if;
				wait until (clock = '1');
		end loop;
		file_close( z_file);z_read_done<= '1';
		wait;
	end process z_read_process;
	
	tb_process: process
		variable errors : integer := 0;
		variable warnings : integer := 0;
		variable start_time:  time;
		variable end_time:  time;
		variable ln1, ln2, ln3, ln4 : line;
	begin
		wait until (reset = '1');
		wait until (reset = '0');
		wait until ((x_write_done= '1') and (y_write_done= '1'));
		wait until (clock = '0');
		wait until (clock = '1');
		start_time:= NOW;
		write(ln1, string'("@ "));
		write(ln1, start_time);
		write(ln1, string'(": Beginning simulation..."));
		writeline(output, ln1);
		start <= '1';
		wait until (clock = '0');
		wait until (clock = '1');
		start <= '0';
		wait until (done = '1');
		end_time:= NOW;
		write(ln2, string'("@ "));
		write(ln2, end_time);
		write(ln2, string'(": Simulation completed."));
		writeline(output, ln2);
		wait until (z_read_done= '1');
		errors := z_errors;
		write(ln3, string'("Total simulation cycle count: "));
		write(ln3, (end_time-start_time) / CLOCK_PERIOD);
		writeline(output, ln3);
		write(ln4, string'("Total error count: "));
		write(ln4, errors);
		writeline(output, ln4);
		hold_clock<= '1';
		wait;
	end process tb_process;
end architecture; 