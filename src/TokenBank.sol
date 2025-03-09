// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./TestToken.sol";
import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";
import { ISignatureTransfer } from "permit2/src/interfaces/ISignatureTransfer.sol";
import { IPermit2 } from "permit2/src/interfaces/IPermit2.sol";

contract TokenBank {
    TestToken public testToken;
    IPermit2 public permit2;

    mapping(address => mapping(address => uint256)) public tokenBalanceOf; //用户地址 -- 币种地址 ---> 币种余额

    event Deposit(address tokenAddress, address indexed user, uint256 amount); //存款事件

    constructor(TestToken _tokenAddress, address _permit2) {
        testToken = _tokenAddress;
        permit2 = IPermit2(_permit2);
    }

    function depositWithPermit2(uint256 amount, uint256 nonce, uint256 deadline, bytes calldata signature) public {
        //通过签名直接转走代币
        permit2.permitTransferFrom(
            ISignatureTransfer.PermitTransferFrom({ permitted: ISignatureTransfer.TokenPermissions({ token: address(testToken), amount: amount }), nonce: nonce, deadline: deadline }),
            ISignatureTransfer.SignatureTransferDetails({ to: address(this), requestedAmount: amount }),
            msg.sender,
            signature
        );
        tokenBalanceOf[msg.sender][address(testToken)] += amount;
        emit Deposit(address(testToken), msg.sender, amount);
    }

    function getDepositByToken(address userAddress) external view returns (uint256) {
        return tokenBalanceOf[userAddress][address(testToken)];
    }
}