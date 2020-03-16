--
-- DVB IP
--
-- Copyright 2019 by Suoto <andre820@gmail.com>
--
-- This file is part of the DVB IP.
--
-- DVB IP is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- DVB IP is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with DVB IP.  If not, see <http://www.gnu.org/licenses/>.

use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;

library osvvm;
use osvvm.RandomPkg.all;

library str_format;
use str_format.str_format_pkg.all;

library fpga_cores;
use fpga_cores.common_pkg.all;

package testbench_utils_pkg is

  shared variable rand   : RandomPType;

  impure function counter ( constant length : integer ) return byte_array_t;
  impure function random ( constant length : integer ) return byte_array_t;

  procedure push(msg : msg_t; value : std_logic_vector_2d_t);
  impure function pop(msg : msg_t) return std_logic_vector_2d_t;

  impure function reinterpret ( constant v : std_logic_vector_2d_t; constant width : natural ) return std_logic_vector_2d_t;

end testbench_utils_pkg;

package body testbench_utils_pkg is

  procedure push(msg : msg_t; value : std_logic_vector_2d_t) is
  begin
    push(msg, value'low);
    push(msg, value'high);

    for i in value'low to value'high loop
      push(msg, value(i));
    end loop;

  end;

  impure function pop(msg : msg_t) return std_logic_vector_2d_t is
    constant low    : integer := pop(msg);
    constant high   : integer := pop(msg);
    constant first  : std_logic_vector := pop(msg);
    constant width  : integer := first'length;
    variable result : std_logic_vector_2d_t(low to high)(width - 1 downto 0);
  begin

    result(0) := first;

    for i in low to high - 1 loop
      result(i + 1) := pop(msg);
    end loop;

    return result;
  end;

  ------------------------------------------------------------------------------------
  impure function counter ( constant length : integer ) return byte_array_t is
    variable result : byte_array_t(0 to length - 1);
  begin
    for i in 0 to length - 1 loop
      result(i) := std_logic_vector(to_unsigned(i, 8));
    end loop;
    return result;
  end;

  ------------------------------------------------------------------------------------
  impure function random ( constant length : integer ) return byte_array_t is
    variable result : byte_array_t(0 to length - 1);
  begin
    -- return counter(length);
    for i in 0 to length - 1 loop
      result(i) := rand.RandSlv(8);
    end loop;
    return result;
  end;

  impure function reinterpret ( constant v : std_logic_vector_2d_t; constant width : natural ) return std_logic_vector_2d_t is
    constant in_length  : natural := v'length;
    constant in_width   : natural := v(v'low)'length;
    constant out_length : natural := (in_length * in_width + width - 1) / width;
    variable result     : std_logic_vector_2d_t(0 to out_length - 1)(width - 1 downto 0);
    variable bit_cnt    : natural := 0;
    variable ptr        : natural := 0;
    variable tmp        : std_logic_vector(in_width + width - 1 downto 0);
  begin
    -- info(sformat("Converting %d x %d => %d x %d", fo(in_length), fo(in_width), fo(out_length), fo(width)));

    for i in v'range loop
      tmp(in_width + bit_cnt - 1 downto bit_cnt) := v(i);
      bit_cnt                                    := bit_cnt + in_width;

      while bit_cnt >= width loop
        result(ptr) := tmp(width - 1 downto 0);
        tmp         := (width - 1 downto 0 => 'U') & tmp(tmp'length - 1 downto width);
        bit_cnt     := bit_cnt - width;
        ptr         := ptr + 1;

      end loop;
    end loop;

    if bit_cnt /= 0 then
      result(ptr) := tmp(width - 1 downto 0);
    end if;

    return result;
  end;


end package body;
