// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Source is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WARDEN_ROLE = keccak256("BRIDGE_WARDEN_ROLE");
	mapping( address => bool) public approved;
	address[] public tokens;

	event Deposit( address indexed token, address indexed recipient, uint256 amount );
	event Withdrawal( address indexed token, address indexed recipient, uint256 amount );
	event Registration( address indexed token );

    constructor( address admin ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(WARDEN_ROLE, admin);

    }

	function deposit(address _token, address _recipient, uint256 _amount ) public {
		require(isRegistered[_token], "token not registered");
        require(_amount > 0, "amount = 0");
        require(_recipient != address(0), "bad recipient");
        bool ok = IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        require(ok, "transferFrom failed");

// 3) 发出存款事件，供桥监听
        emit Deposit(_token, msg.sender, _recipient, _amount);
	}

	function withdraw(address _token, address _recipient, uint256 _amount ) onlyRole(WARDEN_ROLE) public {
		require(isRegistered[_token], "token not registered");
        require(_amount > 0, "amount = 0");
        require(_recipient != address(0), "bad recipient");
        // 将真实资产从保管合约转给接收者
        bool ok = IERC20(_token).transfer(_recipient, _amount);
        require(ok, "transfer failed");

        emit Withdrawl(_token, _recipient, _amount);
	}

	function registerToken(address _token) onlyRole(ADMIN_ROLE) public {
		require(_token != address(0), "bad token");
        require(!isRegistered[_token], "already registered");
        isRegistered[_token] = true;

        emit Registration(_token);
	}


}


