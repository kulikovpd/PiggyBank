// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/PiggyBankDAO.sol";
import "forge-std/Vm.sol";
import "forge-std/StdCheats.sol";

contract PiggyBankDAOTest is Test {
    
    PiggyBankDAO public dao;

    IERC20 DAI = IERC20(0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60);
    IERC20 UNI = IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);

    address[] members = [0x824BE4F4Db966FF6a28428f6f665185211cA813A, address(this)];
    address[] empty;
    address[] bigArray;
    address[] zero = [address(0)];
    address[] repeatableMembers = [address(this), address(this), address(this)];

    uint256 public constant MULTIPLIER = 10 ** 18;

    uint256 numOfBurners = 100;

    function giveTokenToDAO(uint256 id, address receiver, IERC20 token, uint256 amount) public {
        deal(address(token), receiver, amount * MULTIPLIER, true);
        token.approve(address(dao),  amount * MULTIPLIER);
        dao.transfer(id, amount * MULTIPLIER, token);
    }

    function setUp() public {
        dao = new PiggyBankDAO();
        for (uint i = 1; i < numOfBurners + 1; i++){
            bigArray.push(vm.addr(i));
        }
    }

    // openDao

    

    function testOpenDAO() public {
        dao.openDAO(members);
        dao.openDAO(members);
        dao.openDAO(members);
        dao.memberOf(address(this));
        dao.counter();
    }

    function testOpenDAORepeatable() public {
        uint256 id = dao.openDAO(repeatableMembers);
        dao.membersCount(id);
        dao.memberOf(address(this));
    }

    function testFailOpenDAONoMembersInList() public {
        dao.openDAO(empty);
        vm.expectRevert(PiggyBankDAO.NoMembersInList.selector);
    }
    
    function testFailOpenDAOZeroAddressNotAllowed() public {
        dao.openDAO(zero);
        vm.expectRevert(PiggyBankDAO.ZeroAddressNotAllowed.selector);
    }

    // transfer

    function testTransfer() public{
        uint256 id = dao.openDAO(members);
        giveTokenToDAO(id, address(this), DAI, numOfBurners);
        giveTokenToDAO(id, address(this), UNI, 1);
        dao.tokensListOf(id);
        giveTokenToDAO(id, address(this), UNI, 1);
        dao.tokensListOf(id);
        dao.balanceOf(id, address(UNI));
    }

    function testFailTransferDAONotYetOpened() public{
        giveTokenToDAO(1, address(this), DAI, numOfBurners);
        dao.transfer(1, 1 * MULTIPLIER, DAI);
        vm.expectRevert(PiggyBankDAO.DAONotYetOpened.selector);
    }

    function testFailTransferIncorrectTokenAmount() public{
        uint256 id = dao.openDAO(members);
        deal(address(DAI), address(this), 101 * MULTIPLIER, true);
        DAI.approve(address(dao),  100 * MULTIPLIER);
        dao.transfer(id, 100 * MULTIPLIER + 1, DAI);
    }

    // withdraw

    function testWithdraw() public{
        uint256 id = dao.openDAO(members);
        giveTokenToDAO(id, address(this), DAI, numOfBurners);
        dao.balanceOf(id, address(DAI));
        dao.withdraw(id, 1 * MULTIPLIER, DAI, msg.sender);
        giveTokenToDAO(id, address(this), UNI, 1);
        dao.withdraw(id, 1 * 10 ** 17, UNI, address(this));
        DAI.balanceOf(msg.sender);
        dao.membersCount(id);
        dao.tokensWithdrawn(id, address(this), address(UNI));
        assertEq(dao.tokensWithdrawn(id, address(this), address(DAI)), 1 * MULTIPLIER);
    }

    function testFailWithdrawIncorrectTokenAmount() public{
        uint256 id = dao.openDAO(members);
        giveTokenToDAO(id, address(this), DAI, numOfBurners);
        dao.withdraw(id, 50 * MULTIPLIER + 1, DAI, msg.sender);
        vm.expectRevert(PiggyBankDAO.IncorrectTokenAmount.selector);
    }

    function testFailWithdrawZeroAddressNotAllowed() public{
        uint256 id = dao.openDAO(members);
        giveTokenToDAO(id, address(this), DAI, numOfBurners);
        dao.withdraw(id, 50 * MULTIPLIER, DAI, address(0));
        vm.expectRevert(PiggyBankDAO.ZeroAddressNotAllowed.selector);
    }

    function testFailWithdrawDAONotYetOpened() public{
        uint256 id = dao.openDAO(members);
        giveTokenToDAO(id, address(this), DAI, numOfBurners);
        dao.withdraw(id + 1, 50 * MULTIPLIER, DAI, address(this));
        vm.expectRevert(PiggyBankDAO.DAONotYetOpened.selector);
    }

    function testFailWithdrawNoMembership() public{
        uint256 id = dao.openDAO(members);
        giveTokenToDAO(id, address(this), DAI, numOfBurners);
        vm.prank(0xE2A09565167D4e3F826ADeC6bEF82B97e0A4383f);
        dao.withdraw(id, 50 * MULTIPLIER, DAI, address(this));
        vm.expectRevert(PiggyBankDAO.NoMembership.selector);
    }

    function testMultipleWithdraw() public{
        uint256 id = dao.openDAO(bigArray);
        giveTokenToDAO(id, address(this), DAI, numOfBurners);
        for (uint i = 0; i < numOfBurners; i++){
            vm.prank(bigArray[i]);
            dao.withdraw(id, 1 * MULTIPLIER, DAI, msg.sender);
        }
    }

    function testFailMultipleWithdraw() public{
        uint256 id = dao.openDAO(bigArray);
        giveTokenToDAO(id, address(this), DAI, numOfBurners);
        for (uint i = 0; i < numOfBurners; i++){
            vm.prank(bigArray[i]);
            if (i == 33){
                dao.withdraw(id, 1 * MULTIPLIER + 1, DAI, msg.sender);
            } else {
                dao.withdraw(id, 1 * MULTIPLIER, DAI, msg.sender);
            }
        }
        vm.expectRevert(PiggyBankDAO.IncorrectTokenAmount.selector);
    }
}