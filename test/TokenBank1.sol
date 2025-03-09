// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {Test} from "forge-std/Test.sol";
import {TokenBank} from "../src/TokenBank.sol";
import {TestToken} from "../src/TestToken.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

contract TokenBankTest1 is Test {
    // 定义 Permit2 所需的常量
    bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );

    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256(
        "TokenPermissions(address token,uint256 amount)"
    );

    // 定义结构体
    struct TokenPermissions {
        address token;
        uint256 amount;
    }

    struct PermitTransferFrom {
        TokenPermissions permitted;
        address spender;
        uint256 nonce;
        uint256 deadline;
    }

    TokenBank public bank;
    TestToken public token;
    IPermit2 public permit2;

    address public user;
    uint256 public userPrivateKey;

    function setUp() public {
        // 设置测试账户
        user = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        userPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        // 部署测试代币
        token = TestToken(0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9);

        // 部署 TokenBank 合约
        bank = TokenBank(0x5FC8d32690cc91D4c39d9d3abcBD16989F875707);

        // 使用已部署的 Permit2 地址（或根据需要部署）
        permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);

        // 给测试账户铸造代币
        vm.startPrank(user);
        token.mint(1000 ether);

        // 授权 Permit2 合约
        token.approve(address(permit2), type(uint256).max);
        vm.stopPrank();
    }

    function _hashTokenPermissions(TokenPermissions memory permissions) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            _TOKEN_PERMISSIONS_TYPEHASH,
            permissions.token,
            permissions.amount
        ));
    }

    function _hashPermitTransferFrom(PermitTransferFrom memory permit) internal pure returns (bytes32) {
        bytes32 tokenPermissionsHash = _hashTokenPermissions(permit.permitted);
        return keccak256(abi.encode(
            _PERMIT_TRANSFER_FROM_TYPEHASH,
            tokenPermissionsHash,
            permit.spender,
            permit.nonce,
            permit.deadline
        ));
    }

    function _getMessageHash(PermitTransferFrom memory permit, IPermit2 permit2Contract) internal view returns (bytes32) {
        bytes32 structHash = _hashPermitTransferFrom(permit);
        return keccak256(abi.encodePacked(
            "\x19\x01",
            permit2Contract.DOMAIN_SEPARATOR(),
            structHash
        ));
    }

    function testDepositWithPermit2() public {
        uint256 depositAmount = 100 ether;
        uint256 nonce = 0;
        uint256 deadline = block.timestamp + 1 hours;

        TokenPermissions memory permitted = TokenPermissions({
            token: address(token),
            amount: depositAmount
        });

        PermitTransferFrom memory permit = PermitTransferFrom({
            permitted: permitted,
            spender: address(bank),
            nonce: nonce,
            deadline: deadline
        });

        // 计算签名消息哈希
        bytes32 messageHash = _getMessageHash(permit, permit2);

        // 使用私钥签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // 调用存款函数
        vm.startPrank(user);
        bank.depositWithPermit2(depositAmount, nonce, deadline, signature);
        vm.stopPrank();

        // 验证存款结果
        assertEq(bank.getDepositByToken(user), depositAmount);
    }
}