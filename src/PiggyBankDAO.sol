// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract PiggyBankDAO{

    uint256 daoCounter = 0;

    mapping (address => mapping(uint256 => bool)) isMember;

    mapping (uint256 => uint256) memberCount;

    mapping (uint256 => mapping(address => uint256)) transferredTotal;

    mapping (uint256 => mapping(address => mapping(address => uint256))) withdrawnTotal;

    mapping (uint256 => address[]) tokensList;

    mapping (address => uint256[]) memberOfList;

    error NoMembership();

    error IncorrectTokenAmount();

    error DAONotYetOpened();

    error NoMembersInList();

    error ZeroAddressNotAllowed();

    function counter() public view returns(uint256) {
        return daoCounter;
     }

    function memberOf(address user) public view returns (uint256[] memory) {
        return memberOfList[user];
    }

    function balanceOf(uint256 id, address token) public view returns (uint256) {
        return transferredTotal[id][token];
    }

    function membersCount(uint256 id) public view returns (uint256){
        return memberCount[id];
    }

    function tokensListOf(uint256 id) public view returns (address[] memory) {
        return tokensList[id];
    }

    function tokensWithdrawn(uint256 id, address user, address token) public view returns (uint256) {
        return withdrawnTotal[id][user][token];
    }

    function openDAO(address[] memory members) public returns (uint256){
        if (members.length == 0) {
            revert NoMembersInList();
        }
        uint256 newId = ++daoCounter;
        uint256 memberCounter = members.length;
        for (uint i = 0; i < members.length; i++) {
            if (isMember[members[i]][newId]) {
                memberCounter -= 1;
            } else {
                isMember[members[i]][newId] = true;
                memberOfList[members[i]].push(newId);
            }  
        }
        if (isMember[address(0)][newId]) {
            revert ZeroAddressNotAllowed();
        }
        memberCount[newId] = memberCounter;
        return newId;
    }

    function transfer(uint256 id, uint256 amount, IERC20 token) public {
        if (id > daoCounter) {
            revert DAONotYetOpened();
        }
        token.transferFrom(msg.sender, address(this), amount);
        transferredTotal[id][address(token)] += amount;
        bool isNewToken = true;
        for (uint i = 0; i < tokensList[id].length; i++) {
            if (tokensList[id][i] == address(token)) {
                isNewToken = false;
                break;
            }
        }
        if (isNewToken) {
            tokensList[id].push(address(token));
        }
    }

    function withdraw(uint256 id, uint256 amount, IERC20 token, address receiver) public {
        if (id > daoCounter) {
            revert DAONotYetOpened();
        }
        if (!isMember[msg.sender][id]) {
            revert NoMembership();
        }
        if (receiver == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        withdrawnTotal[id][msg.sender][address(token)] += amount;
        if (withdrawnTotal[id][msg.sender][address(token)] * memberCount[id] > transferredTotal[id][address(token)]) {
            revert IncorrectTokenAmount();
        }
        token.transfer(receiver, amount);
    }
}