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
    signal s_clk, s_rst : std_logic := '0';
    signal s_a, s_b, s_twiddle, s_out1, s_out2 : std_logic_vector(63 downto 0) := (others => '0');
begin

    dut: entity work.butterfly
         port map(  clk => s_clk,
                    rst => s_rst,
                    i_a => s_a,
                    i_b => s_b,
                    i_twiddle => s_twiddle,
                    o_out1 => s_out1,
                    o_out2 => s_out2);
                    
    clk_proc: process
    begin
        s_clk <= '0';
        wait for 5ns;
        s_clk <= '1';
        wait for 5ns;
    end process clk_proc;   
                 
    tb_proc: process
    begin 
        s_rst <= '1';
        wait for 20ns;
        s_rst <= '0';
        s_b <= x"0b504f340b504f34";
        s_twiddle <= x"e95f619ae95f619a";
        s_a <= x"0000000010000000";
        wait for 500 ns;
        finish;
    end process;

end beh;
