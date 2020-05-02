library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.constants.all;

entity bram_block is
generic
(
	constant SIZE : integer := 1024;
	constant DWIDTH : integer := 32;
	constant AWIDTH : integer := 10
);
port
(
	signal clock : in std_logic;
	signal rd_addr : in std_logic_vector ((AWIDTH - 1) downto 0);
	signal wr_addr : in std_logic_vector ((AWIDTH - 1) downto 0);
	signal wr_en : in std_logic_vector (((DWIDTH / 8) - 1) downto 0);
	signal dout : out std_logic_vector ((DWIDTH - 1) downto 0);
	signal din : in std_logic_vector ((DWIDTH - 1) downto 0)
);
end entity bram_block;


architecture structure of bram_block is 

	constant NUM_BYTES : integer := DWIDTH / 8;

	component bram
	generic
	(
		constant SIZE : integer := 1024;
		constant AWIDTH : integer := 10;
		constant DWIDTH : integer := 32
	);
	port
	(
		signal clock : in std_logic;
		signal din : in std_logic_vector ((DWIDTH - 1) downto 0);
		signal rd_addr : in std_logic_vector ((AWIDTH - 1) downto 0);
		signal wr_addr : in std_logic_vector ((AWIDTH - 1) downto 0);
		signal wr_en : in std_logic;
		signal dout : out std_logic_vector ((DWIDTH - 1) downto 0)
	);
	end component;

begin

	bram_blocks : for i in 0 to (NUM_BYTES - 1) generate

		bram_instance : component bram
		generic map
		(
			SIZE => SIZE,
			AWIDTH => AWIDTH,
			DWIDTH => 8
		)
		port map
		(
			clock => clock,
			din => din(((8 * (i + 1)) - 1) downto (8 * i)),
			rd_addr => rd_addr((AWIDTH - 1) downto 0),
			wr_addr => wr_addr((AWIDTH - 1) downto 0),
			wr_en => wr_en(i),
			dout => dout(((8 * (i + 1)) - 1) downto (8 * i))
		);

	end generate bram_blocks;


end architecture structure;
