pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import {ICustodian} from './libraries/Interfaces.sol';
import {Owned} from './Owned.sol';

contract Governance is Owned {
  struct ContractUpgrade {
    bool exists;
    address newContract;
    uint256 blockThreshold;
  }

  uint256 immutable blockDelay;
  ICustodian custodian;
  ContractUpgrade internal currentExchangeUpgrade;
  ContractUpgrade internal currentGovernanceUpgrade;

  constructor(uint256 _blockDelay) Owned() public {
    blockDelay = _blockDelay;
  }

  function setCustodian(ICustodian _custodian) external onlyAdmin {
    require(custodian == ICustodian(0x0), 'Custodian can only be set once');
    custodian = _custodian;
  }

  /*** Exchange upgrade ***/

  function initiateExchangeUpgrade(address newExchange) external onlyAdmin {
    require(newExchange != address(0x0), 'Invalid address');
    require(!currentExchangeUpgrade.exists, 'Exchange upgrade already in progress');
    currentExchangeUpgrade = ContractUpgrade(
      true,
      newExchange,
      block.number + blockDelay
    );
  }

  function cancelExchangeUpgrade() external onlyAdmin {
    require(currentExchangeUpgrade.exists, 'No Exchange upgrade in progress');
    delete currentExchangeUpgrade;
  }

  function finalizeExchangeUpgrade(address newExchange) external onlyAdmin {
    require(currentExchangeUpgrade.exists, 'No Exchange upgrade in progress');
    require(currentExchangeUpgrade.newContract == newExchange, 'Address mismatch');
    require(block.number >= currentExchangeUpgrade.blockThreshold, 'Block threshold not yet reached');

    delete currentExchangeUpgrade;
    custodian.setExchange(newExchange);
  }

  /*** Governance upgrade ***/

  function initiateGovernanceUpgrade(address newGovernance) external onlyAdmin {
    require(newGovernance != address(0x0), 'Invalid address');
    require(!currentGovernanceUpgrade.exists, 'Governance upgrade already in progress');
    currentGovernanceUpgrade = ContractUpgrade(
      true,
      newGovernance,
      block.number + blockDelay
    );
  }

  function cancelGovernanceUpgrade() external onlyAdmin {
    require(currentGovernanceUpgrade.exists, 'No Governance upgrade in progress');
    delete currentGovernanceUpgrade;
  }

  function finalizeGovernanceUpgrade(address newGovernance) external onlyAdmin {
    require(currentGovernanceUpgrade.exists, 'No Governance upgrade in progress');
    require(currentGovernanceUpgrade.newContract == newGovernance, 'Address mismatch');
    require(block.number >= currentGovernanceUpgrade.blockThreshold, 'Block threshold not yet reached');

    delete currentGovernanceUpgrade;
    custodian.setGovernance(newGovernance);
  }
}