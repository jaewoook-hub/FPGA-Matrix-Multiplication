library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity matmul_top is
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
end entity;

architecture behavioral of matmul_top is
    signal x_dout, y_dout, z_din : std_logic_vector (DWIDTH - 1 downto 0);
    signal x_rd_addr, y_rd_addr, z_wr_addr : std_logic_vector (AWIDTH - 1 downto 0);
    signal z_wr_en : std_logic_vector (3 downto 0);
    signal z_wr_en_vec : std_logic_vector (NUM_BLOCKS - 1 downto 0);
begin

    mat_1 : component bram_block
    generic map 
    (
        SIZE => N ** 2,
        DWIDTH => DWIDTH,
        AWIDTH => AWIDTH
    )
    port map 
    (
        clock => clock,
        rd_addr => x_rd_addr,
        wr_addr => x_wr_addr,
        dout => x_dout,
        din => x_din,
        wr_en => x_wr_en 
    );

    mat_2 : component bram_block
    generic map 
    (
        SIZE => N ** 2,
        DWIDTH => DWIDTH,
        AWIDTH => AWIDTH
    )
    port map 
    (
        clock => clock,
        rd_addr => y_rd_addr,
        wr_addr => y_wr_addr,
        dout => y_dout,
        din => y_din,
        wr_en => y_wr_en 
    );

    mat_3 : component bram_block
    generic map 
    (
        SIZE => N ** 2,
        DWIDTH => DWIDTH,
        AWIDTH => AWIDTH
    )
    port map 
    (
        clock => clock,
        rd_addr => z_rd_addr,
        wr_addr => z_wr_addr,
        dout => z_dout,
        din => z_din, 
        wr_en => z_wr_en_vec
    );

    mat_mult : component matmul
    generic map
    (
        AWIDTH => AWIDTH,
        N => N
    )
    port map
    (
        clock => clock, 
        reset => reset, 
        start => start,
        done => done,
        x_dout => x_dout,
        y_dout => y_dout,
        z_din => z_din,
        x_rd_addr => x_rd_addr,
        y_rd_addr => y_rd_addr,
        z_wr_addr => z_wr_addr,
        z_wr_en => z_wr_en
    );

    z_wr_en_vec <= z_wr_en; 

end architecture;