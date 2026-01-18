// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
}

interface ITokenMessenger {
    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken
    ) external returns (uint64 nonce);
}

interface IMessageTransmitter {
    function receiveMessage(
        bytes calldata message,
        bytes calldata attestation
    ) external returns (bool);
}

contract CCTPAdapter {
    address public immutable tokenMessenger;
    address public immutable messageTransmitter;
    address public immutable usdc;

    constructor(address _tm, address _mt, address _usdc) {
        tokenMessenger = _tm;
        messageTransmitter = _mt;
        usdc = _usdc;
    }

    function burnUSDCAndSend(
        uint256 amount,
        uint32 destinationDomain,
        address recipient
    ) external returns (uint64 nonce) {
        IERC20(usdc).transferFrom(msg.sender, address(this), amount);
        IERC20(usdc).approve(tokenMessenger, amount);

        nonce = ITokenMessenger(tokenMessenger).depositForBurn(
            amount,
            destinationDomain,
            bytes32(uint256(uint160(recipient))),
            usdc
        );
    }

    function receiveUSDC(
        bytes calldata message,
        bytes calldata attestation
    ) external {
        IMessageTransmitter(messageTransmitter).receiveMessage(
            message,
            attestation
        );
    }
}
