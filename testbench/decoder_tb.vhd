----------------------------------------------------------------------------------
-- Company: Open Research Institute, Inc.
-- Engineer: Skunkwrx and Abraxas3d
-- 
-- Design Name: 
-- Module Name: decoder_tb - Behavioral
-- Project Name: Phase 4, Haifuraiya
-- Target Devices: 
-- Tool Versions: Vivado 2021.1
-- Description: 
-- 
-- Dependencies: 
-- 
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- In order to read test vectors in from a file
use std.textio.all;

entity decoder_tb is
--  Port ( );
end decoder_tb;

architecture Behavioral of decoder_tb is

component decoder is
   port(
   rst      : in STD_LOGIC;
   clk      : in STD_LOGIC;
   s_tdata  : in STD_LOGIC_VECTOR (7 downto 0);
   s_tlast  : in STD_LOGIC;
   s_tvalid : in STD_LOGIC;
   s_tready : out STD_LOGIC;
   m_tdata  : out STD_LOGIC_VECTOR (7 downto 0);
   m_tlast  : out STD_LOGIC;
   m_tvalid : out STD_LOGIC;
   m_tready : in STD_LOGIC);
end component decoder;

    signal rst : STD_LOGIC;
    signal clk : STD_LOGIC := '0';
    signal input_data : STD_LOGIC_VECTOR (7 downto 0);
    signal s_tlast : STD_LOGIC;
    signal s_tvalid : STD_LOGIC := '1';
    signal s_tready : STD_LOGIC;
    signal output_data : STD_LOGIC_VECTOR (7 downto 0);
    signal m_tlast : STD_LOGIC;
    signal m_tvalid : STD_LOGIC;
    signal m_tready : STD_LOGIC;
    


begin

DUT : decoder 

port map(
    clk => clk,
    rst => rst,
    s_tdata => input_data,
    s_tlast => s_tlast,
    s_tvalid => s_tvalid,
    s_tready => s_tready,
    m_tdata => output_data,
    m_tlast => m_tlast,
    m_tvalid => m_tvalid,
    m_tready => m_tready);

--clk <= not(clk) after 1ns;
--rst <= '1' after 1ns, '0' after 3 ns;
--input_data <= x"00" after 1 ns, 
--              x"03" after 17 ns,
--              x"A5" after 19 ns,
--              x"5A" after 21 ns,
--              x"05" after 23 ns,
--              x"DE" after 25 ns,
--              x"AD" after 27 ns,
--              x"BE" after 29 ns,
--              x"EF" after 31 ns,
--              x"01" after 33 ns,
--              x"00" after 35 ns;
--s_tvalid <= '0' after 0 ns,
--            '1' after 3 ns,
--            '0' after 37 ns;
            
   
-- from the friendly people at 
-- https://surf-vhdl.com/read-from-file-in-vhdl-using-textio-library/

p_read : process
--------------------------------------------------------------------------------------------------
file test_vector                : text open read_mode is "cobs-test.txt";
variable row                    : line;
variable v_data_read            : integer := 0;
variable validity               : integer := 0;
variable readiness              : integer := 0;
variable resetting              : integer := 0;


begin
    
    -- read from input file in "row" variable
    -- input data, s_tvalid, s_tready, rst
    while not endfile(test_vector) loop
    readline(test_vector, row);
    -- Skip empty lines and single-line comments
    if row.all'length = 0 or row.all(1) = '-' then
        next;
    end if;

    read(row,v_data_read);
    input_data <= STD_LOGIC_VECTOR(TO_UNSIGNED(v_data_read,8));


    --because s_tvalid is a std_logic (not a vector). 
    --To solve this, all you need to do is select 
    --the 0th bit of the output of the conversion 
    --function to unsigned(because it is an array 
    --of std_logic) 
    --s_tvalid := to_unsigned(validity, 1)(0); 
    
    read(row, validity);
    s_tvalid <= to_unsigned(validity,1)(0);
    
    read(row, readiness);
    s_tready <= to_unsigned(readiness,1)(0);
    
    read(row, resetting);
    rst <= to_unsigned(resetting,1)(0);
    
    clk <= '1';
    wait for 1 NS;
    clk <= '0';
    wait for 1 NS;
    
    end loop;

end process p_read;       

end Behavioral;



