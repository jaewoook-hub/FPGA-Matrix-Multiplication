library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mat_mul_top is
generic(
	DATA_WIDTH : integer := 32;
	FIFO_BUFFER_SIZE : integer := 16;
	N : integer := 8
	);
port(
	clock: in STD_LOGIC;
	reset: in STD_LOGIC;
	x_wr_en: in STD_LOGIC;
	x_full: out STD_LOGIC;
	x_din: in STD_LOGIC_VECTOR (31 downto 0);
	done_x: out STD_LOGIC;
	y_wr_en: in STD_LOGIC;
	y_full: out STD_LOGIC;
	y_din: in STD_LOGIC_VECTOR (31 downto 0);
	z_rd_en: in STD_LOGIC;
	z_empty: out STD_LOGIC;
	z_dout: out STD_LOGIC_VECTOR (31 downto 0)
	);
end entity mat_mul_top;

architecture behavioral of mat_mul_top is
	component fifo is
	generic (
		constant FIFO_DATA_WIDTH : integer := 32;
		constant FIFO_BUFFER_SIZE : integer := 32
	);
	port(
		signal rd_clk : in std_logic;
		signal wr_clk : in std_logic;
		signal reset : in std_logic;
		signal rd_en : in std_logic;
		signal wr_en : in std_logic;
		signal din : in std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
		signal dout : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
		signal full : out std_logic;
		signal empty : out std_logic
	);
	end component fifo;
	
	component matmul is
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
	end component matmul;
	
	signal x_dout: STD_LOGIC_VECTOR(31 downto 0);
	signal x_empty: STD_LOGIC;
	signal x_rd_en: STD_LOGIC;
	signal y_dout: STD_LOGIC_VECTOR(31 downto 0);
	signal y_empty: STD_LOGIC;
	signal y_rd_en: STD_LOGIC;
	signal z_din: STD_LOGIC_VECTOR(31 downto 0);
	signal z_full: STD_LOGIC;
	signal z_wr_en: STD_LOGIC;

begin

matmul_inst: component matmul
generic map(
	N => N
	)
port map(
	clock	 => clock,
	reset 	 => reset,
	x_dout 	 => x_dout,
	x_empty  => x_empty,
	done_o_x => done_x,
	x_rd_en	 => x_rd_en,
	y_dout	 => y_dout,
	y_empty	 => y_empty,
	y_rd_en	 => y_rd_en,
	z_din	 => z_din,
	z_full	 => z_full,
	z_wr_en	 => z_wr_en
	);

x_inst: component fifo
generic map(
	FIFO_BUFFER_SIZE=>FIFO_BUFFER_SIZE,
	FIFO_DATA_WIDTH=>DATA_WIDTH
	)
port map(
	rd_clk	=> clock,
	wr_clk	=> clock,
	reset	=> reset,
	rd_en	=> x_rd_en,
	wr_en	=> x_wr_en,
	din		=> x_din,
	dout	=> x_dout,
	full	=> x_full,
	empty	=> x_empty
	);

y_inst: component fifo
generic map(
	FIFO_BUFFER_SIZE => FIFO_BUFFER_SIZE,
	FIFO_DATA_WIDTH => DATA_WIDTH
	)
port map(
	rd_clk	=> clock,
	wr_clk	=> clock,
	reset	=> reset,
	rd_en	=> y_rd_en,
	wr_en	=> y_wr_en,
	din		=> y_din,
	dout	=> y_dout,
	full	=> y_full,
	empty	=> y_empty
	);

z_inst: component fifo
generic map(
	FIFO_BUFFER_SIZE => FIFO_BUFFER_SIZE,
	FIFO_DATA_WIDTH => DATA_WIDTH
	)
port map(
	rd_clk	=> clock,
	wr_clk	=> clock,
	reset	=> reset,
	rd_en	=> z_rd_en,
	wr_en	=> z_wr_en,
	din		=> z_din,
	dout	=> z_dout,
	full	=> z_full,
	empty	=> z_empty
	);
	
end architecture behavioral;