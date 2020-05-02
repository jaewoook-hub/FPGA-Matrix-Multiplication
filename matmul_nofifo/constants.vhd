library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package constants is
	component matmul is
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
	end component matmul;

	component bram_block is 
	generic (
		constant SIZE : integer := 1024;
		constant DWIDTH : integer := 32;
		constant AWIDTH : integer := 10 );
	port (
		signal clock : in std_logic;
		signal rd_addr: in std_logic_vector((AWIDTH -1) downto 0);
		signal wr_addr: in std_logic_vector((AWIDTH -1) downto 0);
		signal wr_en: in std_logic_vector(((DWIDTH / 8) -1) downto 0);
		signal dout : out std_logic_vector((DWIDTH -1) downto 0);
		signal din : in std_logic_vector((DWIDTH -1) downto 0) );
	end component;
	
	component bram is
	generic
	(
		constant SIZE : integer := 1024;
		constant AWIDTH : integer := 10;
		constant DWIDTH : integer := 32
	);
	port
	(
		signal clock : in std_logic;
		signal rd_addr : in std_logic_vector ((AWIDTH - 1) downto 0);
		signal wr_addr : in std_logic_vector ((AWIDTH - 1) downto 0);
		signal wr_en : in std_logic;
		signal dout : out std_logic_vector ((DWIDTH - 1) downto 0);
		signal din : in std_logic_vector ((DWIDTH - 1) downto 0)
	);
	end component bram;
	
	component matmul_top is
    generic 
    (
        DWIDTH : natural := 32;
        AWIDTH : natural := 6;
        N : natural := 8;
        NUM_BLOCKS : natural := 4
    );
    port 
    (
        signal clock : in std_logic;
        signal reset : in std_logic;
        signal start : in std_logic;
        signal done : out std_logic;
		signal x_wr_addr : in std_logic_vector (AWIDTH - 1 downto 0);
        signal x_wr_en : in std_logic_vector (NUM_BLOCKS - 1 downto 0);
        signal x_din : in std_logic_vector (DWIDTH - 1 downto 0);
		signal y_wr_addr : in std_logic_vector (AWIDTH - 1 downto 0);
        signal y_wr_en : in std_logic_vector (NUM_BLOCKS - 1 downto 0);
        signal y_din : in std_logic_vector (DWIDTH - 1 downto 0);
        signal z_rd_addr : in std_logic_vector (AWIDTH - 1 downto 0);
        signal z_dout : out std_logic_vector (DWIDTH - 1 downto 0)
	);
	end component;

end package;