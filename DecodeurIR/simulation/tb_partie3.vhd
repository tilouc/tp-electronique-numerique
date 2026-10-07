-- ============================================================================
-- tb_partie3.vhd : banc de test du paragraphe 3.2 (verification par simulation)
--
-- Equivalent du sim_partie3.do de ModelSim pour GHDL : horloge 50 MHz sur
-- MainClk, comparateur Comp_MaxValue regle sur 4 (simulation/partie3), on
-- observe MainClk et la sortie du comparateur SamplingClk (1 impulsion de
-- 20 ns toutes les 5 periodes d'horloge, cf. figure page 10 du sujet).
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_partie3 is
end entity tb_partie3;

architecture sim of tb_partie3 is

	signal MainClk : std_logic := '1';
	signal IR_RX   : std_logic := '1';
	signal fin     : boolean := false;

begin

	dut : entity work.DecodeurIR
		port map (
			MainClk => MainClk,
			IR_RX   => IR_RX
		);

	MainClk <= not MainClk after 10 ns when not fin else '0';

	process
	begin
		wait for 400 ns;
		report "FIN DE SIMULATION";
		fin <= true;
		wait;
	end process;

end architecture sim;
