import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Insurance.sol";

contract TestInsurance {

	uint8   public constant decimals = 18;

	function testConstructor() {
		Insurance isr = Insurance(DeployedAddresses.Insurance());

		uint256 ROUND_TRIP_LP_REWARD = 30 * (10 ** uint256(decimals));

		uint256 expectedBalance = ROUND_TRIP_LP_REWARD * 10;

		Assert.equal(isr.balanceOf(tx.origin), expectedBalance, "Owner should have some minted coins");
	}
}