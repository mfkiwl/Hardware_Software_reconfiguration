library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.all;

entity tb_fft is
end tb_fft;

architecture Behavioral of tb_fft is

    COMPONENT blk_mem_gen_0 
        PORT (
            --Inputs - Port A
            ENA            : IN STD_LOGIC;  --opt port
            WEA            : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            ADDRA          : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
            DINA           : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
            DOUTA          : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
            CLKA           : IN STD_LOGIC;
            
            --Inputs - Port B
            ENB            : IN STD_LOGIC;  --opt port
            WEB            : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            ADDRB          : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
            DINB           : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
            DOUTB          : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
            CLKB           : IN STD_LOGIC 
        );
    END COMPONENT;
    
    signal start_flag, stop_flag : std_logic := '0';    
    signal s_clk, s_rst, o_bram_en, s_start_op, s_start_stage, s_end_op, s_stage_fin, s_ena : std_logic := '0';
    signal s_wea, o_bram_wen : std_logic_vector(0 downto 0) := "0";
    signal s_addra : std_logic_vector(11 downto 0) := (others => '0');
    signal s_dina, s_douta : std_logic_vector(63 downto 0) := (others => '0');
    signal i_bram_data, o_bram_data, s_bram_data : std_logic_vector(63 downto 0) := (others => '0');
    signal o_bram_addr, s_start_addr : std_logic_vector(23 downto 0) := (others => '0');
    signal s_arm_data_muxsel : std_logic_vector(23 downto 0) := (others => '0');
    signal s_arm_twiddle_muxsel : std_logic_vector(11 downto 0) := (others => '0');
    signal s_wait_cycles, s_stage_num : integer := 1;
    
begin

    dut: entity work.fft_hw_sw 
         port map(  clk => s_clk,
                    rst => s_rst,
                    o_bram_addr => o_bram_addr,
                    i_bram_data => i_bram_data,
                    o_bram_data => o_bram_data,
                    o_bram_en => o_bram_en,
                    o_bram_wen => o_bram_wen(0),
                    i_start_addr => s_start_addr,
                    i_arm_data_muxsel => s_arm_data_muxsel,
                    i_arm_twiddle_muxsel => s_arm_twiddle_muxsel,
                    i_start_op => s_start_op,
                    i_start_stage => s_start_stage,
                    i_end_op => s_end_op,
                    o_stage_fin => s_stage_fin);
                    
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
                    addrb => o_bram_addr(11 downto 0), 
                    dinb => o_bram_data,
                    doutb => i_bram_data);
                    
                    
    clk_gen: process
    begin
        s_clk <= '0';
        wait for 1ns;
        s_clk <= '1';
        wait for 1ns;
    end process clk_gen;
    
    tb_proc: process(s_clk)
    begin
        if rising_edge(s_clk) then
            if start_flag = '0' then
                s_start_addr <= (others => '0');
                s_start_op <= '1';
                start_flag <= '1';
                s_stage_num <= 1;
                s_wait_cycles <= 1;
            elsif s_wait_cycles < 11 then
                s_wait_cycles <= s_wait_cycles + 1; 
            elsif s_stage_num < 4 then
                if s_stage_num = 1 then
                    s_arm_data_muxsel <= "111" & "110" & "101" & "100" & "011" & "010" & "001" & "000";
                    s_arm_twiddle_muxsel <= "000" & "000" & "000" & "000";
                    s_stage_num <= s_stage_num + 1;
                elsif s_stage_num = 2 then
                    s_arm_data_muxsel <= "111" & "101" & "110" & "100" & "011" & "001" & "010" & "000";
                    s_arm_twiddle_muxsel <= "010" & "000" & "010" & "000";
                    s_stage_num <= s_stage_num + 1;
                elsif s_stage_num = 3 then
                    s_arm_data_muxsel <= "111" & "011" & "101" & "001" & "110" & "010" & "100" & "000";
                    s_arm_twiddle_muxsel <= "011" & "010" & "001" & "000";
                    s_stage_num <= s_stage_num + 1;
                    s_end_op <= '1';
                end if;
            elsif stop_flag = '0' then    
               s_end_op <= '1';
               stop_flag <= '1';
            else    
                s_start_op <= '0';
                start_flag <= '1';
                stop_flag <= '1';
            end if;
        end if;
    end process tb_proc;

end Behavioral;
