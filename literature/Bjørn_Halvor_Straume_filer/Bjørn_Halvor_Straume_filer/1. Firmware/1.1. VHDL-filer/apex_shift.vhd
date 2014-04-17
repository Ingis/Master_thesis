LIBRARY IEEE;
	USE IEEE.std_logic_1164.ALL;
	use ieee.std_logic_unsigned.all;
	

ENTITY apex_shift IS
	generic (width : positive := 8);
	PORT (
	 ucc_apex_clk        : IN  std_logic;      --use ucc_apex_clk for rorc22(66MHz crystal)
     --ucc_apex_clk50        : IN  std_logic;  --use ucc_apex_clk50 for rorc11 (50MHz crystal)
         RXD               : in std_logic;
         TXD               : out std_logic;
         clk1            : out std_logic;
         clk10            : out std_logic;
         areset_n        : in std_logic;
         leds      : out std_logic_vector(7 downto 0);
 		 clk_ext_led	     : out std_logic;			--NY  led for å teste clk_ext
		 clk_led	     : out std_logic;			--NY  led for å teste clk_ext_int
     	 countled	: out std_logic_vector(1 downto 0)  --NY
);
		
END apex_shift;

architecture cell_level of apex_shift is
--used for test purpose only
component clk_div IS

	PORT
	(
		clock_66Mhz				: IN	STD_LOGIC;
		clock_1MHz				: OUT	STD_LOGIC;
		clock_100KHz			: OUT	STD_LOGIC;
		clock_10KHz				: OUT	STD_LOGIC;
		clock_1KHz				: OUT	STD_LOGIC;
		clock_100Hz				: OUT	STD_LOGIC;
		clock_10Hz				: OUT	STD_LOGIC;
		clock_1Hz				: OUT	STD_LOGIC);

END component;



component rx_uart is
  port (
     clk       : in  std_logic;  -- system clock signal
     areset_n  : in  std_logic;  -- Reset input
     rxd       : in  std_logic;  -- RS-232 data input
     data_av   : out std_logic;  -- Byte available
     data_out  : out std_logic_vector(7 downto 0)
     ); -- Byte received
    
 end component;

component tx_uart is
  port (
     clk       : in  std_logic;  -- system clock signal
     areset_n    : in  std_logic;  -- Reset input
     txd       : out  std_logic;  -- RS-232 data input
     data_load : in std_logic;
     tx_busy   : out std_logic;
     data_in   : in std_logic_vector(7 downto 0)); -- Byte received
    
end component;

component register_row is
	 --generic (length : positive := 10);
	 PORT (
          	clk        : IN  std_logic;
	  		areset	    : in  std_logic;    -- neg triggered
	  		in_data    : in  std_logic;
	  		d_enable   :in std_logic;
       		out_data   : out std_logic
                );
end component register_row;


-- Signals on top-level

--used for test purpose only
signal  clk1m : std_logic;
signal  clk100k : std_logic;
signal  clk10k : std_logic;
signal  clk1k : std_logic;
signal  clk100 : std_logic;

signal test_led           : std_logic;

signal clk33              : std_logic;
signal reset_shift_n            : std_logic;

signal reset_n : std_logic;

signal clk_ext_shift : std_logic;
signal data_to_pc   : std_logic_vector(7 downto 0);
signal data_from_pc : std_logic_vector(7 downto 0);
signal tx_busy : std_logic;
signal data_send_ld: std_logic;
signal clk_ext : std_logic;
signal clk_ext_int : std_logic;


signal data_out_sig1 : std_logic_vector(7 downto 0);
signal data_out_sig2 : std_logic_vector(7 downto 0);
signal data_out_sig3 : std_logic_vector(7 downto 0);
signal data_out_sig4 : std_logic_vector(7 downto 0);

signal data_in_sig1 : std_logic_vector(7 downto 0);
signal data_in_sig2 : std_logic_vector(7 downto 0);
signal data_in_sig3 : std_logic_vector(7 downto 0);
signal data_in_sig4 : std_logic_vector(7 downto 0);

signal count : std_logic_vector(1 downto 0) ;

signal send_tx	:	std_logic;
signal data_ld	:	std_logic;






type STATE is (REG1,REG2,REG3,REG4,REG_SHIFT);
signal CONTROL_STATE     :STATE;

Begin

leds <= data_from_pc;

reset_shift_n <= reset_n and areset_n;

countled <= count;  --NY

clk_led <= clk_ext_int;   --NY
clk_ext_led <= clk_ext;	--NY

send_tx <= data_send_ld or data_ld;	--kobler sammen for å sende på tx når data_from_PC = data_to_PC

clk33 <= ucc_apex_clk;
--used for test purpose only
clkdiv: clk_div

	PORT map
	(
		clock_66Mhz			=> ucc_apex_clk,
		clock_1MHz			=> clk1m,
		clock_100KHz		=> clk100k,
		clock_10KHz			=> clk10k,
		clock_1KHz			=> clk1k,
		clock_100Hz			=> clk100,
		clock_10Hz			=> clk10,
		clock_1Hz			=> clk1);
	



RECEIVER : rx_uart
port map(
          clk       => clk33,
          areset_n  => areset_n,
          rxd       => RXD,
          data_av   => clk_ext,
          data_out  => data_from_pc

     );
           
TRANSCEIVER : tx_uart
port map(
         clk         => clk33,
         areset_n    => areset_n,
         txd         => TXD,
         data_load   => send_tx,
         tx_busy     => tx_busy,
         data_in     => data_to_pc
     ); -- Byte received


		 
device_array_width : for width_index in width-1  downto 0 generate 
begin

device : register_row

	  port map ( 
 	             clk           => clk33,
	             areset        => reset_shift_n,
	             d_enable      => clk_ext_shift,
	             in_data       => data_in_sig1(width_index),
	             out_data      => data_out_sig1(width_index)
	            );
end generate device_array_width;

device_array_width2 : for width_index in width-1  downto 0 generate 
begin

device2 : register_row

	  port map ( 
 	             clk           => clk33, 
	             areset        => reset_shift_n,
	             d_enable      => clk_ext_shift,
	             in_data       => data_in_sig2(width_index),
	             out_data      => data_out_sig2(width_index)
	            );
end generate device_array_width2;

device_array_width3 : for width_index in width-1  downto 0 generate 
begin

device3 : register_row

	  port map ( 
 	             clk           => clk33, 
	             areset        => reset_shift_n,
	             d_enable      => clk_ext_shift,
	             in_data       => data_in_sig3(width_index),
	             out_data      => data_out_sig3(width_index)
	            );
end generate device_array_width3;

device_array_width4 : for width_index in width-1  downto 0 generate 
begin

device4 : register_row

	  port map (
 	             clk           => clk33, 
	             areset        => reset_shift_n,
	             d_enable      => clk_ext_shift,
	             in_data       => data_in_sig4(width_index),
	             out_data      => data_out_sig4(width_index)
	            );
end generate device_array_width4;


--         if control_data  = "0000" then    --can only to a direct loopback when in REG1 state
 --           CONTROL_STATE <= REG_RESET;
 --           data_send_ld <= '0' after 5 ns;
 --           areset <= '0' after 5 ns;
 --         elsif control_data  = "1111" then
 --           CONTROL_STATE <= REG1 after 5 ns;     --
 --           data_send_ld <= '1' after 5 ns;
 --           areset <= '1' after 5 ns;
 --         else
  --end if







state_machine : process (clk33, areset_n)

begin
   
   if ( areset_n = '0' ) then     
     
   --  reset_n <= '0' after 5 ns;
     count <= "00" after 5 ns;
     CONTROL_STATE <= REG1;
     data_send_ld <= '0' after 5 ns;
     clk_ext_shift <= '0' after 5 ns;
   
   
   elsif rising_edge(clk33) then


    case CONTROL_STATE is

      when REG1 =>

       clk_ext_shift <= '0' after 5 ns;
       if clk_ext_int = '1' then
          count <= "01" after 5 ns;
          CONTROL_STATE <= REG2;
          data_send_ld <= '1' after 5 ns;
     --     reset_n <= '1' after 5 ns;

       else
          CONTROL_STATE <= REG1;
          count <= "00" after 5 ns;
          data_send_ld <= '0' after 5 ns;
     --     reset_n <= '1' after 5 ns;
       end if;

      when REG2 =>
         clk_ext_shift <= '0' after 5 ns;

         if clk_ext_int = '1' then
            count <= "10" after 5 ns;
      --      reset_n <= '1' after 5 ns;
            CONTROL_STATE <= REG3;
            data_send_ld <= '1' after 5 ns;
         else
            count <= "01" after 5 ns;
      --      reset_n <= '1' after 5 ns;
            data_send_ld <= '0' after 5 ns;
            CONTROL_STATE <= REG2 after 5 ns;
         end if;

      when REG3 =>
	 clk_ext_shift <= '0' after 5 ns;
         if clk_ext_int = '1' then
            count <= "11" after 5 ns;
      --      reset_n <= '1' after 5 ns;
            CONTROL_STATE <= REG4;
            data_send_ld <= '1' after 5 ns;
         else
           count <= "10" after 5 ns;
     --      reset_n <= '1' after 5 ns;
           data_send_ld <= '0' after 5 ns;
           CONTROL_STATE <= REG3;
         end if;

      when REG4 =>
	  clk_ext_shift <= '0' after 5 ns;
          if clk_ext_int = '1' then
            count <= "00" after 5 ns;
     --       reset_n <= '1' after 5 ns;
            CONTROL_STATE <= REG_SHIFT;
            data_send_ld <= '1' after 5 ns;
         else
            count <= "11" after 5 ns;
            data_send_ld <= '0' after 5 ns;
      --      reset_n <= '1' after 5 ns;
            CONTROL_STATE <= REG4;
         end if;


      when REG_SHIFT =>
        count <= "00" after 5 ns;
      --  reset_n <= '1' after 5 ns;
        data_send_ld <= '0' after 5 ns;
        clk_ext_shift <= '1' after 5 ns;
        CONTROL_STATE <= REG1;
    
     
    when others =>
        count <= "00" after 5 ns;
        CONTROL_STATE <= REG1 after 5 ns;
        clk_ext_shift <= '0' after 5 ns;
        data_send_ld <= '0' after 5 ns;
        --reset_n <= '0' after 5 ns;
    end case;
      
     
  end if;
end process state_machine;


test : process (clk33, areset_n)

begin

    if ( areset_n ='0') then
      data_in_sig1 <= "00000000" after 5 ns;
      data_in_sig2 <= "00000000" after 5 ns;
      data_in_sig3 <= "00000000" after 5 ns;
      data_in_sig4 <= "00000000" after 5 ns;
      data_to_pc   <= "00000000" after 5 ns;
      clk_ext_int <= '0' after 5 ns;   --trigg shiftregister
      test_led <= '0' after 5 ns;
      reset_n <= '0' after 5 ns;
    elsif rising_edge(clk33) then
  --   control_data <= data_from_pc(7 downto 4) after 5 ns;
      
     if clk_ext = '1' then
         
         if data_from_pc(7 downto 4) = "0111" then  --7
           reset_n <= '0' after 5 ns;
           clk_ext_int <= '0' after 5 ns;   --trigg shiftregister
           data_in_sig1 <= "00000000" after 5 ns;
           data_in_sig2 <= "00000000" after 5 ns;
           data_in_sig3 <= "00000000" after 5 ns;
           data_in_sig4 <= "00000000" after 5 ns;
           data_to_pc   <= "00000000" after 5 ns;
         elsif data_from_pc(7 downto 4) = "0110" then   --6   sender rett gjennom registeret
		   data_ld <= '1' after 5 ns;		--åpner TX. Ellerport sammen med data_load
           reset_n <= '1' after 5 ns;
           data_to_pc <= data_from_pc after 5 ns;
           clk_ext_int <= '0' after 5 ns;   --trigg shiftregister
         else
           if count = 0 then
             data_to_pc <= data_out_sig1 after 5 ns;
             data_in_sig1(7 downto 4) <= data_from_pc(3 downto 0) after 5 ns;
             data_in_sig1(3 downto 0) <= data_from_pc(3 downto 0) after 5 ns;
           elsif count = 1 then
             data_to_pc <= data_out_sig2 after 5 ns;
             data_in_sig2(7 downto 4) <= data_from_pc(3 downto 0) after 5 ns;
             data_in_sig2(3 downto 0) <= data_from_pc(3 downto 0) after 5 ns;
           elsif count = 2 then
             data_to_pc <= data_out_sig3 after 5 ns;
             data_in_sig3(7 downto 4) <= data_from_pc(3 downto 0) after 5 ns;
             data_in_sig3(3 downto 0) <= data_from_pc(3 downto 0) after 5 ns;
           elsif count = 3 then
             data_to_pc <= data_out_sig4 after 5 ns;
             data_in_sig4(7 downto 4) <= data_from_pc(3 downto 0) after 5 ns;
             data_in_sig4(3 downto 0) <= data_from_pc(3 downto 0) after 5 ns;
           end if;
          clk_ext_int <= '1' after 5 ns;   --trigg shiftregister
          reset_n <= '1' after 5 ns; 

         end if;


      test_led <= not test_led after 5 ns;    

    else
      reset_n <= '1' after 5 ns;
      clk_ext_int <= '0' after 5 ns;
      data_to_pc <= data_to_pc after 5 ns;
      data_in_sig1 <= data_in_sig1 after 5 ns;
      data_in_sig2 <= data_in_sig2 after 5 ns;
      data_in_sig3 <= data_in_sig3 after 5 ns;
      data_in_sig4 <= data_in_sig4 after 5 ns;
   	  data_ld <= '0' after 5 ns;		--lukker TX. Ellerport sammen med data_load
    end if;

  

  end if;


end process test;




END cell_level;
