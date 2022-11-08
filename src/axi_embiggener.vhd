--
-- FPGA core library
--
-- Copyright 2014-2021 by Andre Souto (suoto)
-- Embiggened by Skunkwrx and Abraxas3d
--
-- This source describes Open Hardware and is licensed under the CERN-OHL-W v2
--
-- You may redistribute and modify this documentation and make products using it
-- under the terms of the CERN-OHL-W v2 (https:/cern.ch/cern-ohl).This
-- documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,
-- INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A
-- PARTICULAR PURPOSE. Please see the CERN-OHL-W v2 for applicable conditions.
--
-- Source location: https://github.com/suoto/fpga_cores
--
-- As per CERN-OHL-W v2 section 4.1, should You produce hardware based on these
-- sources, You must maintain the Source Location visible on the external case
-- of the FPGA Cores or other product you make using this documentation.


---------------
-- Libraries --
---------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.common_pkg.all;
------------------------
-- Entity declaration --
------------------------
entity axi_embiggener is
  generic (
    INPUT_DATA_WIDTH    : natural := 32;
    OUTPUT_DATA_WIDTH   : natural := 128;
    IGNORE_TKEEP        : boolean := False);
  port (
    -- Usual ports
    clk      : in  std_logic;
    rst      : in  std_logic;
    -- AXI stream input
    s_tready : out std_logic;
    s_tdata  : in  std_logic_vector(INPUT_DATA_WIDTH - 1 downto 0);
    s_tkeep  : in  std_logic_vector((INPUT_DATA_WIDTH + 7) / 8 - 1 downto 0) := (others => 'U');
    s_tvalid : in  std_logic;
    s_tlast  : in  std_logic;
    -- AXI stream output
    m_tready : in  std_logic;
    m_tdata  : out std_logic_vector(OUTPUT_DATA_WIDTH - 1 downto 0);
    m_tvalid : out std_logic);
    -- There are other signals we do not know how to handle yet
    -- dma_xfer_req : out std_logic;
    -- m_tlast : out std_logic; -- encoder outputs this signal, but do we really need it?
end axi_embiggener;

architecture axi_embiggener of axi_embiggener is

  ---------------
  -- Constants --
  ---------------
  constant INPUT_BYTE_WIDTH  : natural := (INPUT_DATA_WIDTH + 7) / 8;
  constant OUTPUT_BYTE_WIDTH : natural := (OUTPUT_DATA_WIDTH + 7) / 8;
  -- TKEEP is only supported if tdata is multiple of 8 bits and wider than 8 bits
  constant HANDLE_TKEEP      : boolean := not IGNORE_TKEEP and           -- Force no tkeep handling
                                          INPUT_DATA_WIDTH mod 8 = 0 and -- tdata must be a multiple of 8 bits
                                          INPUT_DATA_WIDTH > 8;          -- tdata must be wider than 8 bits

  ------------------
  -- Sub programs --
  ------------------
  -- Sets the appropriate tkeep bits so that it representes the specified number of bytes,
  -- where bytes are in the LSB of tdata
  function get_tkeep ( constant valid_bytes : natural ) return std_logic_vector is
    variable result : std_logic_vector(OUTPUT_BYTE_WIDTH - 1 downto 0) := (others => '0');
  begin
    for i in 0 to result'length - 1 loop
      if i < valid_bytes then
        result(i) := '1';
      else
        result(i) := '0';
      end if;
    end loop;
    return result;
  end;

  -- function tkeep_to_byte_count ( constant tkeep : std_logic_vector ) return unsigned is
  --   variable candidate : std_logic_vector(tkeep'length - 1 downto 0) := (others => '0');
  -- begin
  --   candidate(0) := '1';

  --   for i in 0 to INPUT_BYTE_WIDTH - 1 loop
  --     if tkeep = candidate then
  --       -- (INPUT_BYTE_WIDTH - 1 downto i + 1 => '0') & (i downto 0 => '1') then
  --       return to_unsigned(i + 1, numbits(2*INPUT_BYTE_WIDTH));
  --     end if;

  --     candidate := candidate(tkeep'length - 2 downto 0) & '1';
  --   end loop;
  --   return (numbits(2*INPUT_BYTE_WIDTH) - 1 downto 0 => 'U');
  -- end function;

  function tkeep_to_byte_count ( constant tkeep : std_logic_vector ) return unsigned is
    variable result : unsigned(numbits(2*INPUT_BYTE_WIDTH) - 1 downto 0) := (others => '0');
  begin
    -- When tkeep is all ones we have INPUT_BYTE_WIDTH valid bytes
    if tkeep = (tkeep'range => '1') then
      result := result or to_unsigned(INPUT_BYTE_WIDTH, numbits(2*INPUT_BYTE_WIDTH));
    end if;
    -- Check for intermediate values
    for i in 0 to INPUT_BYTE_WIDTH - 2 loop
      if tkeep = (INPUT_BYTE_WIDTH - 1 downto i + 1 => '0') & (i downto 0 => '1') then
        result := result or to_unsigned(i + 1, numbits(2*INPUT_BYTE_WIDTH));
      end if;
    end loop;

    -- If result is all zeros we failed to convert, so return unknown instead
    if and(not result) then
      return (numbits(2*INPUT_BYTE_WIDTH) - 1 downto 0 => 'U');
    end if;
    return result;
  end function;

  -----------
  -- Types --
  -----------

  -------------
  -- Signals --
  -------------
  signal s_data_valid : std_logic;
  signal m_data_valid : std_logic;
  signal m_tdata_i    : std_logic_vector(OUTPUT_DATA_WIDTH - 1 downto 0);
  signal s_tready_i   : std_logic;
  signal m_tvalid_i   : std_logic;











begin

  g_not_upsize : if INPUT_DATA_WIDTH >= OUTPUT_DATA_WIDTH or INPUT_DATA_WIDTH mod 8 /= 0 or OUTPUT_DATA_WIDTH mod INPUT_DATA_WIDTH /= 0 generate -- {{
    assert False
      report "Conversion from " & integer'image(INPUT_DATA_WIDTH) & " to " & integer'image(OUTPUT_DATA_WIDTH) & " is not currently supported"
      severity Failure;
  end generate g_not_upsize; -- }}


  g_upsize : if INPUT_DATA_WIDTH < OUTPUT_DATA_WIDTH generate -- {{
    -- AI abraxas3d to find out more about generate - thinking it's always with a test
    
    signal big_buffer           : std_logic_vector(OUTPUT_DATA_WIDTH - 1 downto 0);
    signal input_valid_bytes    : unsigned(numbits(2*INPUT_BYTE_WIDTH) - 1 downto 0);
    signal big_buffer_next      : std_logic_array_t(0 to OUTPUT_DATA_WIDTH/INPUT_DATA_WIDTH - 1)(INPUT_DATA_WIDTH - 1 downto 0);
    -- AI abraxas3d can we have mixed types of indices in the std_logic_array_t? hmm?


  begin


    -- Generate the number of bytes valid depending on the value of TKEEP
    input_valid_bytes <= tkeep_to_byte_count(s_tkeep) when s_tvalid and s_tlast else (others => 'U');


    ---------------
    -- Processes --
    ---------------
    process(clk)
      variable tmp_bit_buffer : std_logic_vector(bit_buffer'range);
      variable tmp_size       : natural range 0 to tmp_bit_buffer'length;
      variable tmp_flush_req  : boolean;
    begin
      if rising_edge(clk) then

        tmp_bit_buffer := bit_buffer;
        tmp_size       := to_integer(size);
        tmp_flush_req  := flush_req;

        -- De-assert tvalid when data in being sent and no more data, except when we're
        -- flushing the output buffer
        if m_tready = '1' and (tmp_size >= OUTPUT_DATA_WIDTH or tmp_flush_req) then
          if m_tlast_i = '1' then
            tmp_flush_req := False;
          end if;
          m_tvalid_i <= '0';
          m_tlast_i  <= '0';
        end if;

        -- Handling incoming data
        if s_data_valid = '1' then
          s_tready_i <= '0'; -- Each incoming word will generate at least 1 output word

          -- Add the incoming data to the relevant bit buffer
          -- Need to assign data before tmp_size (it's a variable)
          assert tmp_size <= OUTPUT_DATA_WIDTH;
          tmp_bit_buffer := bit_buffer_next(tmp_size);
          tmp_size       := tmp_size + input_valid_bits;

          dbg_write_bit_buffer <= tmp_bit_buffer;
          dbg_write_size       <= tmp_size;

          -- Upon receiving the last input word, clear the flush request
          if s_tlast = '1' then
            tmp_flush_req := True;
          end if;

        end if;

        if m_data_valid = '1' then
          -- Consume the data we wrote
          tmp_bit_buffer := (OUTPUT_DATA_WIDTH - 1 downto 0 => 'U') & tmp_bit_buffer(tmp_bit_buffer'length - 1 downto OUTPUT_DATA_WIDTH);
          m_tkeep        <= (others => '0');

          -- Clear up for the next frame
          if m_tlast_i = '1' then
            tmp_size      := 0;
            tmp_flush_req := False;
          else
            tmp_size      := tmp_size - OUTPUT_DATA_WIDTH;
          end if;

          dbg_read_bit_buffer <= tmp_bit_buffer;
          dbg_read_size       <= tmp_size;
        end if;

        if tmp_size >= OUTPUT_DATA_WIDTH or tmp_flush_req then
          m_tvalid_i <= '1';
          m_tdata_i  <= tmp_bit_buffer(OUTPUT_DATA_WIDTH - 1 downto 0);
          m_tkeep    <= (others => '0');

          -- Work out if the next word will be the last and fill in the bit mask
          -- appropriately
          if tmp_size <= OUTPUT_DATA_WIDTH and tmp_flush_req then
            m_tlast_i <= '1';
            if OUTPUT_DATA_WIDTH < 8 then
              m_tkeep <= (others => '1');
            elsif HANDLE_TKEEP then
              m_tkeep <= get_tkeep((tmp_size + 7) / 8);
            end if;
          end if;
        end if;

        -- Input should always be ready if there's room for data to be received, unless
        -- we're flushing the buffer. In this case, accepting more data will mess up with
        -- the tracking of how much data we still have to write
        if tmp_bit_buffer'length - tmp_size >= INPUT_DATA_WIDTH and not tmp_flush_req then
          s_tready_i <= '1';
        end if;

        bit_buffer       <= tmp_bit_buffer;
        size <= to_unsigned(tmp_size, size'length);
        flush_req <= tmp_flush_req;

        if rst = '1' then
          s_tready_i     <= '0';
          m_tvalid_i     <= '0';
          m_tlast_i      <= '0';
          dbg_write_size <= 0;
          dbg_read_size  <= 0;
          size           <= (others => '0');
          flush_req      <= False;
        end if;
      end if;
    end process;

  end generate g_upsize; -- }}





  ------------------------------
  -- Asynchronous assignments --
  ------------------------------
  s_data_valid <= s_tready_i and s_tvalid and not rst;
  m_data_valid <= m_tready and m_tvalid_i and not rst;

  m_tdata      <= m_tdata_i when m_tvalid_i = '1' else (others => 'U');
  s_tready     <= s_tready_i;
  m_tvalid     <= m_tvalid_i;


  -- ---------------
  -- -- Processes --
  -- ---------------
  -- -- First word flagging is common
  -- process(clk, rst)
  -- begin
  --   if rst = '1' then
  --     s_first_word <= '1';
  --   elsif rising_edge(clk) then

  --     if s_data_valid = '1' then
  --       s_first_word <= s_tlast;
  --     end if;

  --   end if;
  -- end process;

end axi_embiggener;

-- vim: set foldmethod=marker foldmarker=--\ {{,--\ }} :

