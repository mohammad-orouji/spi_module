library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi is
    generic (
        input_reg_width : integer   := 8;
        SYS_CLOCK       : integer   := 10;   --100 MHz 
        SPI_CLOCK       : integer   := 100;  --10 MHz 
        CPOL            : std_logic := '0';
        CPHA            : std_logic := '0'
        -- MSB_first       : integer := 1; 
        -- LSB_first       : integer := 0
    );
    port (
        CLK_I           : in  std_logic;
        RESET_I         : in  std_logic;
        -- SCLK_EN_O       : out std_logic;
        SCLK            : in std_logic;
        MOSI            : out std_logic;
        MISO            : in  std_logic;
        SS              : out std_logic;
        ------------------------------------
        SEND_DATA_I     : in  std_logic_vector(input_reg_width-1 downto 0);
        START_SEND_I    : in  std_logic;
        READY_O         : out std_logic;
        VALID_I         : in  std_logic
        ------------------------------------
        -- RECEIVE_DATA_O  : out std_logic_vector(input_reg_width-1 downto 0)  
        -- READY_I         : in  std_logic;
        -- VALID_O         : out std_logic
    );
end entity spi;

architecture rtl of spi is
    
    constant T1 : natural := input_reg_width;
    signal   t  : natural range 0 to T1;

    -- time half period sclk for PHAS(clock edge) = 1
    constant half_period_spi      : natural := (SPI_CLOCK / sys_CLOCK) /2 ;
    signal   t2                   : natural range 0 to half_period_spi := 0 ;

    signal req      : std_logic := '0';
    signal req_r    : std_logic := '0';
    signal req_r2   : std_logic := '0';

    signal ack      : std_logic := '0';
    signal ack_r    : std_logic := '0';
    signal ack_r2   : std_logic := '0';

    signal ready_CDC        : std_logic;
    signal data_recieved    : std_logic;
    signal data_sended      : std_logic;
    signal ready_spi        : std_logic;
    signal r_READY_O        : std_logic;

    signal lal        : std_logic;

    type state is (idle, wait_for_start_send, determining_the_CPAH, TX_RX_state_cpha_0, TX_RX_state_cpha_1, half_priod_cpha_0, half_priod_cpha_0_1);
    signal present_state : state := idle;
    signal next_state    : state := idle;

    signal SEND_DATA_I_r        : std_logic_vector(input_reg_width-1 downto 0);
    signal SEND_DATA_I_r2       : std_logic_vector(input_reg_width-1 downto 0);
    signal SEND_DATA_I_r3       : std_logic_vector(input_reg_width-1 downto 0);
    signal SEND_DATA_I_r4       : std_logic_vector(input_reg_width-1 downto 0);
    
    signal START_SEND_I_r       : std_logic;
    
    signal falling_launch_en     : std_logic;
    signal risiing_launch_en     : std_logic;
    
    -- signal recive_data      : std_logic_vector(input_reg_width-1 downto 0);
    -- signal recive_data_r    : std_logic_vector(input_reg_width-1 downto 0);

    signal MOSI_r   : std_logic;
    signal MOSI_r2  : std_logic;
    signal MISO_r   : std_logic;
    signal SS_r     : std_logic;
    signal SS_r2    : std_logic;

    signal SPI_MODE : std_logic_vector(1 downto 0);
    signal cpah     : std_logic := CPHA;

begin

    SPI_MODE    <= cpah & CPOL;

    r_READY_O   <= ready_CDC and data_recieved and ready_spi;
    READY_O     <= r_READY_O;
    process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            SEND_DATA_I_r   <= SEND_DATA_I_r;
            req             <= req;
            ack_r           <= ack;
            ack_r2          <= ack_r;

            ready_CDC       <= '0';
            data_recieved   <= '1';
            if ack_r2 = '0' and req = '0' then
                ready_CDC     <= '1' ;
            end if;

            if VALID_I = '1' and r_READY_O = '1' then
                SEND_DATA_I_r   <= SEND_DATA_I;
                req             <= '1';
                data_recieved   <= '0';
            end if;

            if req = '1' then
                data_sended     <= '1';
                data_recieved   <= '0';
                SEND_DATA_I_r   <= SEND_DATA_I_r;
            end if;
            
            if ack_r2 = '1' and data_sended = '1' then
                req             <= '0';
                data_sended     <= '0';
                data_recieved   <= '1';
            end if;

            if RESET_I = '1' then
                SEND_DATA_I_r   <= (others => '0');
                req             <= '0';
                ack_r           <= '0';
                ack_r2          <= '0';
                ready_CDC       <= '0';
                data_recieved   <= '0';
                data_sended     <= '0';
            end if;

            case SPI_MODE is
                when "00" =>            -- MODE 00
                    falling_launch_en <= '1'; 
                    -- risiing_launch_en <= '0';
                when "10" =>            -- MODE 10
                    falling_launch_en <= '0';           -- launch data in rising_edge
                    -- risiing_launch_en <= '1';
                when "01" =>            -- MODE 01
                    falling_launch_en <= '0';           -- launch data in rising_edge
                    -- risiing_launch_en <= '1';
                when "11" =>            -- MODE 11
                    falling_launch_en <= '1';
                    -- risiing_launch_en <= '0';
                when others =>          -- MODE 00
                    falling_launch_en <= '1';
                    -- risiing_launch_en <= '0';
            end case;

            if present_state /= next_state then -- counter for rnumber of bit data in spi
                t2 <= 0;
            elsif t2 /= 2 * half_period_spi - 1 then -- MSB first 
                t2 <= t2 + 1;
            end if;

        end if;
    end process; 

    process(SCLK)
    begin
        if falling_launch_en = '1' then
            if falling_edge(SCLK) then
                START_SEND_I_r  <= START_SEND_I;
                req_r           <= req;
                req_r2          <= req_r;
                SEND_DATA_I_r2  <= SEND_DATA_I_r2;
                ack             <= '0';
    
                if req_r2 = '1' then
                    ack             <= '1';
                    SEND_DATA_I_r2  <= SEND_DATA_I_r;
                end if;
        
                if RESET_I = '1' then
                    req_r           <= '0';
                    req_r2          <= '0';
                    ack             <= '0';
                    SEND_DATA_I_r2  <= (others => '0');
                    START_SEND_I_r  <= '0';
                end if;

                present_state   <= next_state;
                SEND_DATA_I_r4  <= SEND_DATA_I_r3;  -- output FSM register
                MOSI_r2         <= MOSI_r;          -- output FSM register  
                -- MOSI            <= MOSI_r2;
                if CPHA = '1' then
                    MOSI_r2         <= MOSI_r;          -- output FSM register  
                    -- MOSI            <= MOSI_r;
                end if;
                SS_r2           <= SS_r;            -- output FSM register  
                -- SS              <= SS_r2;   
                MISO_r          <= MISO;
                -- recive_data_r   <= recive_data;

                if present_state /= next_state then -- counter for rnumber of bit data in spi
                    t <= T1;
                elsif t /= 0 then -- MSB first 
                    t <= t - 1;
                end if;

                if RESET_I = '1' then
                    SEND_DATA_I_r4  <= (others => '0');
                    MOSI_r2         <= '0';
                    SS_r2           <= '0';
                    MISO_r          <= '0';
                    -- recive_data_r   <= (others => '0');
                    t               <= T1;
                    present_state   <= idle; 
                end if;
            end if;

        elsif rising_edge(SCLK) then
                START_SEND_I_r  <= START_SEND_I;
                req_r           <= req;
                req_r2          <= req_r;
                SEND_DATA_I_r2  <= SEND_DATA_I_r2;
                ack             <= '0';

                if req_r2 = '1' then
                    ack             <= '1';
                    SEND_DATA_I_r2  <= SEND_DATA_I_r;
                end if;
        
                present_state   <= next_state;
                SEND_DATA_I_r4  <= SEND_DATA_I_r3;  -- output FSM register
                MOSI_r2         <= MOSI_r;          -- output FSM register  
                -- MOSI            <= MOSI_r2;
                if CPHA = '1' then
                    MOSI_r2         <= MOSI_r;          -- output FSM register  
                    -- MOSI            <= MOSI_r;
                end if;
                SS_r2           <= SS_r;            -- output FSM register  
                -- SS              <= SS_r2;   
                MISO_r          <= MISO;
                -- recive_data_r   <= recive_data;

                if present_state /= next_state then -- counter for rnumber of bit data in spi
                    t <= T1;
                elsif t /= 0 then -- MSB first 
                    t <= t - 1;
                end if;
                
                if RESET_I = '1' then
                    req_r           <= '0';
                    req_r2          <= '0';
                    ack             <= '0';
                    SEND_DATA_I_r2  <= (others => '0');
                    START_SEND_I_r  <= '0';
                    ------------------------------------
                    SEND_DATA_I_r4  <= (others => '0');
                    MOSI_r2         <= '0';
                    SS_r2           <= '0';
                    MISO_r          <= '0';
                    -- recive_data_r   <= (others => '0');
                    t               <= T1;
                    present_state   <= idle; 
                end if;
        end if;
    end process;

    process(all)
    begin
        case present_state is
            when idle =>
                SEND_DATA_I_r3  <= (others => '0');
                ready_spi       <= '1';
                MOSI_r          <= 'Z';
                SS_r            <= '1';
                -- recive_data     <= (others => '0');
                next_state      <= wait_for_start_send;
            when wait_for_start_send =>
                MOSI_r          <= 'Z';
                SS_r            <= '1';
                -- recive_data     <= (others => '0');
                SEND_DATA_I_r3  <= SEND_DATA_I_r3;
                ready_spi       <= '1';
                next_state      <= wait_for_start_send;
                if START_SEND_I_r = '1' and ack = '1' then
                    SEND_DATA_I_r3  <= SEND_DATA_I_r2;
                    ready_spi       <= '0';
                    next_state      <= determining_the_CPAH;
                    if CPHA = '0' then
                        next_state      <= TX_RX_state_cpha_0;
                    end if;
                end if;
            when TX_RX_state_cpha_0 =>
                SEND_DATA_I_r3  <= SEND_DATA_I_r4;
                ready_spi       <= '0';
                MOSI_r          <= SEND_DATA_I_r3(t -1);
                SS_r            <= '0';
                next_state      <= TX_RX_state_cpha_0;
                cpah            <= '0';
                if t = 1 then
                    next_state  <= half_priod_cpha_0;
                    cpah        <= '1';
                end if;
            when half_priod_cpha_0 =>
                cpah    <= '1';
                SS_r    <= '0';
                -- MOSI_r  <= '0';
                if t2 = 2 * half_period_spi - 1 then
                    next_state  <= half_priod_cpha_0_1;
                    SS_r    <= '1';
                end if;
            when half_priod_cpha_0_1 =>
                cpah    <= '0';
                SS_r    <= '1';
                MOSI_r  <= 'Z';
                next_state  <= wait_for_start_send;    
            when determining_the_CPAH =>
                cpah    <= '0';
                SS_r    <= '0';
                MOSI_r  <= '0';
                if t2 =  half_period_spi - 1 then
                    next_state  <= TX_RX_state_cpha_1;
                end if;
            when TX_RX_state_cpha_1 =>
                cpah    <= '1';
                SEND_DATA_I_r3  <= SEND_DATA_I_r4;
                ready_spi       <= '0';
                if t = 0 then
                    MOSI_r          <= MOSI_r2;
                    SS_r            <= '1';
                    next_state      <= wait_for_start_send; 
                else
                    MOSI_r      <= SEND_DATA_I_r3(t-1);
                    SS_r        <= '0';
                    next_state  <= TX_RX_state_cpha_1;
                end if;
        end case;
    end process;

    MOSI    <= MOSI_r when CPHA = '0' else MOSI_r2;
    SS      <= SS_r   when CPHA = '0' else SS_r2;

end architecture rtl;
