library  IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity  COUNTER is
    generic( 
        constant reg_width_data : integer := 8      
    );    
    port(
        ENABLE_I    : in  std_logic;
        RESET_I     : in  std_logic;
        CLK_I       : in  std_logic;
        READY_I     : in  std_logic;
        VALID_O     : out std_logic;
        DATA_O      : out std_logic_vector(reg_width_data-1 downto 0)
    );
end COUNTER;

architecture BEHAVIORAL  of  COUNTER is
    
    signal count      : std_logic_vector(reg_width_data-1 downto 0) := (others => '0');
    signal r_DATA_O   : std_logic_vector(reg_width_data-1 downto 0) := (others => '0');
    signal r_VALID_O  : std_logic := '0';

begin
    
    process(CLK_I) 
    begin   
        if rising_edge(CLK_I) then
            r_VALID_O   <= '1';
            r_DATA_O    <= r_DATA_O;
            if ENABLE_I = '1' then
                if r_VALID_O = '1' and READY_I = '1' then
                    count       <= count + 1; 
                    r_DATA_O    <= count; 
                end if;
            else
                r_VALID_O   <= '0';
            end if;
            if RESET_I = '1' then
                r_VALID_O   <= '0';
                count       <= (others => '0');
                r_DATA_O    <= (others => '0');
            end if;
        end if;
    end process;
    DATA_O    <= r_DATA_O;
    VALID_O   <= r_VALID_O;
      
end architecture BEHAVIORAL;

