LIBRARY IEEE;

	USE IEEE.std_logic_1164.ALL;

	use ieee.std_logic_unsigned.all;



ENTITY register_row IS

	generic (length : positive := 60);			-- lengden på shiftregisteret som genereres

	PORT (

		clk	        : IN  std_logic;
	    areset		: in std_logic;
	    in_data     : in std_logic;
	    d_enable    : in std_logic;
		out_data    : out std_logic);

		

END register_row;

architecture cell_level of register_row is

component shift_register
	 port( areset       : in std_logic; 
               clk          : in std_logic;
              in_data      : in std_logic;
               d_enable     : in std_logic;
               out_data     : out std_logic
               );

end component;


signal data_internal    : std_logic_vector(length-1 downto 0);

BEGIN

out_data <= data_internal(length-1);

device : shift_register

	  port map (
 	  clk           => clk,
	  areset        => areset,
	  in_data       => in_data,
	  d_enable      => d_enable,
	  out_data      => data_internal(0)
	  );

device_array_length : for length_index in 1 to length-1 generate

   begin

   device : shift_register

	  port map (
	  clk           => clk,
	  areset        => areset,
	  d_enable      => d_enable,
	  in_data       => data_internal(length_index-1),
	  out_data      => data_internal(length_index)
	  );

   end generate device_array_length;



END cell_level;