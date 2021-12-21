library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_fft is
end tb_fft;

architecture Behavioral of tb_fft is
    type reg_32 is array(0 to 15) of std_logic_vector(31 downto 0);

--    impure function init_ip_reg return reg_32 is
--        file ip_file : text open read_mode is "fft_ip.txt";
--        variable ip_line : line;
--        variable reg_content : reg32;
--    begin
--        for i in 0 to 15 
--    end function; 

--    component blk_mem_gen_0 IS
--        PORT (
--            clka : IN STD_LOGIC;
--            ena : IN STD_LOGIC;
--            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--            addra : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--            dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--            douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--            clkb : IN STD_LOGIC;
--            enb : IN STD_LOGIC;
--            web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--            addrb : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
--            dinb : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
--            doutb : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
--          );
--    END component;
    COMPONENT blk_mem_gen_0 
        PORT (
            --Inputs - Port A
            ENA            : IN STD_LOGIC;  --opt port
            WEA            : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            ADDRA          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            DINA           : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            DOUTA          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            CLKA       : IN STD_LOGIC;
            
            --Inputs - Port B
            ENB            : IN STD_LOGIC;  --opt port
            WEB            : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            ADDRB          : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            DINB           : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
            DOUTB          : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
            CLKB           : IN STD_LOGIC
            
        );
    
    END COMPONENT;
    
    signal start_flag : std_logic := '0';
    signal write_count : integer := 0;
    
    signal s_clk, s_rst, o_bram_en, i_start_op, s_ena : std_logic := '0';
    signal s_wea, o_bram_wen : std_logic_vector(0 downto 0) := "0";
    signal s_addra : std_logic_vector( 3 downto 0) := (others => '0');
    signal s_dina, s_douta : std_logic_vector(31 downto 0) := (others => '0');
    signal i_bram_data, o_bram_data, s_bram_data : std_logic_vector(63 downto 0) := (others => '0');
    signal o_bram_addr, s_start_addr : std_logic_vector(31 downto 0) := (others => '0');
    
--    signal tb_ip_reg : reg_32 := (); 
begin

    i_bram_data <= s_bram_data(31 downto 0) & s_bram_data(63 downto 32);

    dut: entity work.fft_dit 
         port map(  clk => s_clk,
                    rst => s_rst,
                    o_bram_addr => o_bram_addr,
                    i_bram_data => i_bram_data,
                    o_bram_data => o_bram_data,
                    o_bram_en => o_bram_en,
                    o_bram_wen => o_bram_wen(0),
                    i_start_addr => s_start_addr, 
                    i_start_op => i_start_op);
                    
    bram: blk_mem_gen_0 
          port map( clka => s_clk,
                    ena => s_ena,
                    wea => s_wea,
                    addra => s_addra,
                    dina => s_dina, 
                    douta => s_douta,
                    clkb => s_clk,
                    enb => o_bram_en, 
                    web => o_bram_wen, 
                    addrb => o_bram_addr(2 downto 0), 
                    dinb => o_bram_data,
                    doutb => s_bram_data);
                    
                    
    clk_gen: process
    begin
        s_clk <= '0';
        wait for 0.5ns;
        s_clk <= '1';
        wait for 0.5ns;
    end process clk_gen;
    
    tb_proc: process(s_clk)
    begin
        if rising_edge(s_clk) then
            if start_flag = '0' then
--                if write_count < 8 then
--                    s_addra <= s_addra + 1;
--                    s_dina <= tb_ip_reg(write_count);
--                    write_count <= write_count + 1;
--                else
--                    write_fin_flag <= '1';
--                end if;
                s_start_addr <= (others => '0');
                i_start_op <= '1';
                start_flag <= '1';
            else
                i_start_op <= '0';    
            end if;
        end if;
    end process tb_proc;

end Behavioral;
