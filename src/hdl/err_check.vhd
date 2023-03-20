library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity ERROR_CHECK  is
    generic (
        constant number_of_bit_DATA_I   : integer := 8;  -- data in number of bit
        constant number_of_bit_ERROR_O  : integer := 4   -- error out number of bit
    );
    port(
        CLK_I     :   in    std_logic;
        RESET_I   :   in    std_logic;
        VALID_I   :   in    std_logic;
        DATA_I    :   in    std_logic_vector( number_of_bit_DATA_I-1 downto 0);
        ERROR_O   :   out   std_logic_vector(number_of_bit_ERROR_O-1 downto 0);
        READY_O   :   out   std_logic
    );
end ERROR_CHECK;

architecture behavioral of ERROR_CHECK is

    signal data     : std_logic_vector( number_of_bit_DATA_I-1 downto 0) := (others => '0');
    signal data_R   : std_logic_vector( number_of_bit_DATA_I-1 downto 0) := (others => '0');
    signal error    : std_logic_vector(number_of_bit_ERROR_O-1 downto 0) := (others => '0');
    
    signal r_READY_O : std_logic;
    
begin

    READY_O <= r_READY_O;
    ERROR_O <= error;
    process (CLK_I)     
    begin
        if rising_edge(CLK_I) then
            r_READY_O <= '1';
            if r_READY_O = '1' and VALID_I = '1' then
                data    <= DATA_I;
                data_R  <= data + 1;  
                if(data /= (x"00"))then         
                    if(data_R /= data)then
                        error   <= error + 1;
                    end if;
                end if; 
            end if;
            if(RESET_I = '1')then 
                r_READY_O   <= '0';
                data        <= (others => '0');
                data_R      <= (others => '0');
                error       <= (others => '0');
            end if;
        end if;
    end process;

end architecture behavioral;
