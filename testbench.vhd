library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tb is
end entity uart_tb;

architecture simulation of uart_tb is

    constant CLK_FREQ  : integer := 1000000;
    constant BAUD_RATE : integer := 100000;

    signal clk       : std_logic := '0';
    signal reset     : std_logic := '1';

    signal tx_start  : std_logic := '0';
    signal tx_data   : std_logic_vector(7 downto 0) := (others => '0');

    signal tx        : std_logic;
    signal tx_busy   : std_logic;

    signal rx        : std_logic;
    signal rx_data   : std_logic_vector(7 downto 0);
    signal rx_valid  : std_logic;

    signal finished  : boolean := false;

begin

    ------------------------------------------------
    -- Clock: 1 MHz
    ------------------------------------------------
    clock_process : process
    begin
        while not finished loop
            clk <= '0';
            wait for 500 ns;

            clk <= '1';
            wait for 500 ns;
        end loop;

        wait;
    end process;


    ------------------------------------------------
    -- Loopback connection
    -- Transmitter output connected to receiver input
    ------------------------------------------------
    rx <= tx;


    ------------------------------------------------
    -- UART DUT
    ------------------------------------------------
    DUT : entity work.uart
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk       => clk,
            reset     => reset,

            tx_start  => tx_start,
            tx_data   => tx_data,
            tx        => tx,
            tx_busy   => tx_busy,

            rx        => rx,
            rx_data   => rx_data,
            rx_valid  => rx_valid
        );


    ------------------------------------------------
    -- Test process
    ------------------------------------------------
    test_process : process
    begin

        -- Reset
        reset <= '1';
        wait for 5 us;

        reset <= '0';
        wait for 5 us;

        ------------------------------------------------
        -- Send hexadecimal A5
        ------------------------------------------------
        tx_data  <= x"A5";
        tx_start <= '1';

        wait until rising_edge(clk);

        tx_start <= '0';

        ------------------------------------------------
        -- Wait for transmission to complete
        ------------------------------------------------
        wait until tx_busy = '0';

        ------------------------------------------------
        -- Give receiver time to finish
        ------------------------------------------------
        wait for 5 us;

        ------------------------------------------------
        -- Check received data
        ------------------------------------------------
        assert rx_valid = '1'
            report "ERROR: RX valid signal was not detected."
            severity error;

        assert rx_data = x"A5"
            report "ERROR: Received data is incorrect."
            severity error;

        report "SUCCESS: UART transmitted and received 0xA5 correctly."
            severity note;

        ------------------------------------------------
        -- End simulation
        ------------------------------------------------
        finished <= true;

        wait;

    end process;

end architecture simulation;
