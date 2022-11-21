----------------------------------------------------------------------------------
-- Company: Open Research Institute, Inc.
-- Engineer: Skunkwrx, Abraxas3d
-- 
-- Design Name: COBS protocol decoder
-- Module Name: decoder - Behavioral
-- Project Name: Phase 4 "Haifuraiya"
-- Target Devices: 7000 Zynq
-- Tool Versions: 2021.1
-- Description: COBS protocol decoder. 
--              https://en.wikipedia.org/wiki/Consistent_Overhead_Byte_Stuffing
-- 
-- Dependencies: 
--
-- Additional Comments: This work is Open Source and licsed using CERN OHL v2.0
-- 
----------------------------------------------------------------------------------
--Variables need to be defined after the keyword process 
--but before the keyword begin. 
--Signals are defined in the architecture before the begin statement. 
--Variables are assigned using the := assignment symbol. 
--Signals are assigned using the <= assignment symbol.





library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

--Entity Declaration
entity decoder is
    Port ( rst      : in STD_LOGIC;
           clk      : in STD_LOGIC;
           s_tdata  : in STD_LOGIC_VECTOR (7 downto 0);
           s_tlast  : in STD_LOGIC;
           s_tvalid : in STD_LOGIC;
           s_tready : out STD_LOGIC;
           m_tdata  : out STD_LOGIC_VECTOR (7 downto 0);
           m_tlast  : out STD_LOGIC;
           m_tvalid : out STD_LOGIC;
           m_tready : in STD_LOGIC);
end decoder;

--Architecture
architecture Behavioral of decoder is

--input data is the COBS encoded byte stream
--count is a variable that keeps track of the number of bytes in each code block.
--m_tdata_i is the decoded byte stream
--input_data_d_d is the COBS encoded byte stream delayed by two clock cycles

    signal input_data       : STD_LOGIC_VECTOR (7 downto 0);
    signal input_data_d     : STD_LOGIC_VECTOR (7 downto 0);
    signal input_data_d_d   : STD_LOGIC_VECTOR (7 downto 0);
    signal counter_load     : STD_LOGIC;
    signal s_tlast_i        : STD_LOGIC;
    signal s_tvalid_i       : STD_LOGIC;
    signal s_tready_i       : STD_LOGIC;
    signal output_data      : STD_LOGIC_VECTOR (7 downto 0); 
    signal m_tlast_i        : STD_LOGIC;
    signal m_tvalid_i       : STD_LOGIC;
    signal m_tready_i       : STD_LOGIC;
    signal count            : STD_LOGIC_VECTOR (7 downto 0);
    signal all_ones         : STD_LOGIC_VECTOR(input_data'range) := (others => '1');
    signal all_zeros        : STD_LOGIC_VECTOR(input_data'range) := (others => '0');

 
begin
   
        
    -- asynchronous assignments
    m_tlast_i <= '1' when input_data = all_zeros else '0';
    m_tlast <= m_tlast_i;
    m_tvalid <= m_tvalid_i;
    input_data <= s_tdata;
    m_tdata <= output_data;
    counter_load <= '1' when count = all_zeros or to_integer(unsigned(count)) = 1 else '0';

-- processes

    count_and_load : process (rst,clk)
    --variables would go here
    begin
        if rst='1' then
            count <= (others => '0');
            output_data <= (others => '0');
        -- EVERY signal assigned below must be reset here !
        elsif rising_edge(clk) then
            if counter_load = '1' then
                count <= input_data;
                output_data <= all_zeros;
            else
                count <= STD_LOGIC_VECTOR(unsigned(count) - 1);
                output_data <= input_data;
            end if;
        end if;
    end process count_and_load;
    
    
    
    
    create_mtvalid : process (rst,clk)
    --variables would go here
    begin
        if rst = '1' then
            m_tvalid_i <= '0';
            --every signal assigned below must be set here
        elsif rising_edge(clk) then
            if input_data_d_d = all_zeros then
                m_tvalid_i <= '1';
            elsif input_data = all_zeros then
                m_tvalid_i <= '0';
            end if;
        end if;
    end process create_mtvalid;
    
    
    
    
    
    versions_of_input_data : process (rst,clk)
    --variables would go here
    begin
        if rst = '1' then
            input_data_d <= all_zeros;
            input_data_d_d <= all_zeros;
            --every signal assigned below must be set here
        elsif rising_edge(clk) then
            input_data_d <= input_data;
            input_data_d_d <= input_data_d;
        end if;
    end process versions_of_input_data;


end Behavioral;


--decoder : entity work.decoder
--port map(
--    clk => clk,
--    rst => rst,
--    s_tdata => input_data,
--    s_tlast => s_tlast_i,
--    s_tvalid => s_tvalid_i,
--    s_tready => s_tready_i,
--    m_tdata => output_data,
--    m_tlast => m_tlast_i,
--    m_tvalid => m_tvalid_i,
--    m_tready => m_tready_i);

