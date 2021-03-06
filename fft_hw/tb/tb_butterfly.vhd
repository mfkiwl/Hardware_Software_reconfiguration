----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/15/2021 10:12:13 AM
-- Design Name: 
-- Module Name: tb_butterfly - beh
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.env.finish;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_butterfly is
--  Port ( );
end tb_butterfly;

architecture beh of tb_butterfly is
    signal s_a, s_b, s_twiddle, s_out1, s_out2 : std_logic_vector(63 downto 0) := (others => '0');
begin

    dut: entity work.butterfly
         port map(  i_a => s_a,
                    i_b => s_b,
                    i_twiddle => s_twiddle,
                    o_out1 => s_out1,
                    o_out2 => s_out2);
                    
    tb_proc: process
    begin 
        s_b <= "0011100000000000000000000000000000000000000000000000000000000000";
        s_twiddle <= "0001011010100000100111100110011000010110101000001001111001100110";
        s_a <= "0001010000000000000000000000000000000000000000000000000000000000";
        wait for 10 ns;
        finish;
    end process;

end beh;
