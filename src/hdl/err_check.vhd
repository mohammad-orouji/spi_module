library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity ERROR_CHECK  is
    generic (
        constant reg_width_DATA         : integer := 8; 
        constant reg_width_errcheck     : integer := 4  
    );
    port(
        CLK1      :   in    std_logic;
        CLK2      :   in    std_logic;
        RESET_I   :   in    std_logic;
        VALID_I   :   in    std_logic;
        DATA_I    :   in    std_logic_vector(    reg_width_DATA-1 downto 0);
        ERROR_O   :   out   std_logic_vector(reg_width_errcheck-1 downto 0);
        READY_O   :   out   std_logic
    );
end ERROR_CHECK;

architecture BEHAVIORAL of ERROR_CHECK is

    signal data      : std_logic_vector(    reg_width_DATA-1 downto 0) := (others => '0');
    signal data_r    : std_logic_vector(    reg_width_DATA-1 downto 0) := (others => '0');
    signal data_r2   : std_logic_vector(    reg_width_DATA-1 downto 0) := (others => '0');
    signal error     : std_logic_vector(reg_width_errcheck-1 downto 0) := (others => '0');

    signal ready            : std_logic := '1';
    signal data_sended      : std_logic := '0';
    signal data_recieved    : std_logic := '0';

    signal req      : std_logic := '0';
    signal req_r    : std_logic := '0';
    signal req_r2   : std_logic := '0';

    signal ack      : std_logic := '0';
    signal ack_r    : std_logic := '0';
    signal ack_r2   : std_logic := '0';
    
begin


    process (CLK1)     
    begin
        if rising_edge(CLK1) then
            data        <= data;
            req         <= req;
            ack_r       <= ack;
            ack_r2      <= ack_r;
            ready       <= '1';
            if VALID_I = '1' and ready = '1' then
                data    <= DATA_I;
                req     <= '1';
                ready           <= '0';
            end if;

            if req = '1' then
                data_sended   <= '1';
                ready         <= '0';
                data          <= data;
            end if;
            
            if ack_r2 = '1' and data_sended = '1' then
                req             <= '0';
                data_sended     <= '0';
                ready           <= '1';
            end if;

            if RESET_I = '1' then
                data        <= (others => '0');
                req         <= '0';
                ack_r       <= '0';
                ack_r2      <= '0';
                ready       <= '1';
            end if;
        end if;
    end process;



    process (CLK2)     
    begin
        if rising_edge(CLK2) then
            req_r   <= req;
            req_r2  <= req_r;
            data_r  <= data_r;
            data_r2 <= data_r2;
            ack     <= '0';
            error   <= error;

            -- if ack = '1' then
            --     data_recieved <= '0';
            -- end if;


            if req_r2 = '1' then
                ack     <= '1';
                data_r  <= data;
                data_r2 <= data_r + 1;
                error   <= error;
                if(data_r /= (x"00"))then         
                    if(data_r2 /= data_r)then
                        error   <= error + 1;
                    end if;
                end if; 
            end if;

            if RESET_I = '1' then
                req_r <= '0';
                req_r2  <= '0';
                ack     <= '0';
                data_r  <= (others => '0');
                data_r2 <= (others => '0');
                error   <= (others => '0');
            end if;
        end if;
    end process;

    ERROR_O <= error;
    READY_O <= ready;
end architecture BEHAVIORAL;
