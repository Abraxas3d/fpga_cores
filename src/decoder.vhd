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
    signal counter_load_d   : STD_LOGIC;
    signal s_tlast_i        : STD_LOGIC;
    signal s_tvalid_i       : STD_LOGIC;
    signal s_tvalid_i_d     : STD_LOGIC;
    signal s_tvalid_i_d_d   : STD_LOGIC;
    signal s_tready_i       : STD_LOGIC;
    signal saved_data       : STD_LOGIC_VECTOR (7 downto 0);
    signal output_data      : STD_LOGIC_VECTOR (7 downto 0); 
    signal m_tlast_i        : STD_LOGIC;
    signal pre_tvalid       : STD_LOGIC;
    signal m_tvalid_i       : STD_LOGIC;
    signal m_tready_i       : STD_LOGIC;
    signal m_tready_i_d     : STD_LOGIC;
    signal count            : STD_LOGIC_VECTOR (7 downto 0);
    signal all_ones         : STD_LOGIC_VECTOR(input_data'range) := (others => '1');
    signal all_zeros        : STD_LOGIC_VECTOR(input_data'range) := (others => '0');
    signal case_255         : STD_LOGIC;
    signal frame_sep        : STD_LOGIC;
    signal frame_sep_d      : STD_LOGIC;
    signal save_en          : STD_LOGIC;
    signal use_saved        : STD_LOGIC;
 
begin
   
        
    -- asynchronous assignments
    frame_sep <= '1' when input_data_d = all_zeros and s_tvalid_i_d = '1' else '0';
    m_tlast <= frame_sep;
    counter_load <= '1' when (input_data_d /= all_zeros and frame_sep_d = '1' and s_tvalid_i_d = '1') or (to_integer(unsigned(count)) = 1 and s_tvalid_i_d = '1') else '0';
    m_tvalid <= pre_tvalid and s_tvalid_i_d_d;
    s_tready <= m_tready_i;
    save_en <= m_tready_i_d and not m_tready_i;
    m_tdata <= output_data;
    input_data <= s_tdata;
    s_tvalid_i <= s_tvalid;
    m_tready_i <= m_tready;
    
    
-- processes



    set_case_255 : process (rst, clk)
    begin
        if rst = '1' then
            case_255 <= '0';
        elsif rising_edge(clk) then
            if counter_load = '1' and input_data_d = all_ones then
                case_255 <= '1';
            elsif counter_load = '1' and input_data_d /= all_ones then
                case_255 <= '0';
            end if;
        end if;
    end process set_case_255;


    
    delay_s_tvalid : process (rst, clk)
    begin
        if rst = '1' then
            s_tvalid_i_d <= '0';
            s_tvalid_i_d_d <= '0';
        elsif rising_edge(clk) then
            s_tvalid_i_d <= s_tvalid_i;
            s_tvalid_i_d_d <= s_tvalid_i_d;
        end if;
    end process delay_s_tvalid;
    
    
    
    create_pre_tvalid : process (rst, clk)
    begin
        if rst = '1' then
            counter_load_d <= '0';
            pre_tvalid <= '0';
        elsif rising_edge(clk) then
            if s_tvalid_i_d = '1' then
                counter_load_d <= counter_load;
                if counter_load_d = '1' then
                    pre_tvalid <= '1';
                end if;    
            end if;
            if frame_sep = '1' then 
                pre_tvalid <= '0';
            end if;
            if counter_load = '1' and case_255 = '1' then
                pre_tvalid <= '0';
            end if;
        end if;
    end process create_pre_tvalid;
     
     
    
    create_saved_and_used_data : process (rst, clk)
    begin
        if rst = '1' then
            saved_data <= (others => '0');
            use_saved <= '0';
        elsif rising_edge(clk) then
            if save_en = '1' then
                saved_data <= input_data_d;
                use_saved <= '1';
            elsif m_tready_i = '1' then
                use_saved <= '0';
            end if;
        end if;
    end process create_saved_and_used_data;
    
    
    
    delay_m_tready_i : process (rst, clk)
    begin
        if rst = '1' then
            m_tready_i_d <= '0';
        elsif rising_edge(clk) then
            m_tready_i_d <= m_tready_i;
        end if;
    end process delay_m_tready_i;
    


    set_counter : process (rst,clk)
    --variables would go here
    begin
        if rst = '1' then
            count <= (others => '0');
            frame_sep_d <= '0';
            --every signal we assign must be reset here
        elsif rising_edge(clk) then
            if s_tvalid_i_d = '1' then
                frame_sep_d <= frame_sep;
                if counter_load = '1' then
                    count <= input_data_d;
                elsif count /= all_zeros then
                    count <= STD_LOGIC_VECTOR(unsigned(count) - 1);
                end if;
            end if;
        end if;
    end process set_counter;
    
    
    
    create_output : process (rst, clk)
    begin
        if rst = '1' then
            output_data <= (others => '0');
        elsif rising_edge(clk) then
            if use_saved = '1' and m_tready_i = '1' then
                output_data <= saved_data;
            elsif counter_load = '1' then
                output_data <= all_zeros;
            else 
                output_data <= input_data_d;
            end if;
        end if;
    end process create_output;
    
  
    
    selective_delay_of_input_data : process (rst,clk)
    --variables would go here
    begin
        if rst = '1' then
            input_data_d <= all_zeros;
            --every signal assigned below must be set here
        elsif rising_edge(clk) then
            if s_tvalid_i = '1' then
                input_data_d <= input_data;
            end if;    
        end if;
    end process selective_delay_of_input_data;


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

