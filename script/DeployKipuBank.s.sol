// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {KipuBankV2} from "../src/KipuBankV2.sol";

/**
 * @title DeployKipuBank
 * @author Barba - 77 Innovation Labs
 * @notice Script para deploy do contrato KipuBankV2 com configuração inicial do Chainlink
 * @dev Configura o contrato com limite inicial de 1000 ETH e price feed ETH/USD
 */
contract DeployKipuBank is Script {
    function run() external {
        // Configuração do limite máximo do banco (1000 ETH)
        uint256 bankCap = 1000 ether;
        
        console.log("Deploying KipuBankV2...");
        console.log("Bank Cap:", bankCap / 1 ether, "ETH");
        
        vm.startBroadcast();
        
        // Deploy do contrato
        KipuBankV2 kipuBank = new KipuBankV2(bankCap);
        
        vm.stopBroadcast();
        
        console.log("KipuBankV2 deployed successfully!");
        console.log("Contract Address:", address(kipuBank));
        console.log("Deployer:", msg.sender);
        
        // Verificar configurações iniciais
        console.log("Initial Contract Balance:", kipuBank.contractBalance() / 1 ether, "ETH");
        console.log("Deposits Counter:", kipuBank.depositsCounter());
        console.log("Withdrawals Counter:", kipuBank.withdrawsCounter());
        
        // Verificar roles do deployer
        console.log("Deployer has DEFAULT_ADMIN_ROLE:", kipuBank.hasRole(kipuBank.DEFAULT_ADMIN_ROLE(), msg.sender));
        console.log("Deployer has PAUSER_ROLE:", kipuBank.hasRole(kipuBank.PAUSER_ROLE(), msg.sender));
        console.log("Deployer has TREASURER_ROLE:", kipuBank.hasRole(kipuBank.TREASURER_ROLE(), msg.sender));
        console.log("Deployer has ORACLE_ROLE:", kipuBank.hasRole(kipuBank.ORACLE_ROLE(), msg.sender));
        
        // Configurar Chainlink Price Feed (ETH/USD Sepolia)
        console.log("Configuring Chainlink Price Feed...");
        
        vm.startBroadcast();
        
        // ETH/USD Sepolia: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        address ethUsdPriceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        kipuBank.configurePriceFeed("ETH", ethUsdPriceFeed, "ETH / USD");
        
        vm.stopBroadcast();
        
        console.log("Chainlink ETH/USD Price Feed configured!");
        console.log("Price Feed Address:", ethUsdPriceFeed);
        
        // Testar o price feed
        try kipuBank.getLatestPrice("ETH") returns (uint256 price) {
            console.log("Current ETH Price (8 decimals):", price);
            console.log("Current ETH Price (USD):", price / 1e8);
        } catch {
            console.log("Failed to get ETH price - price feed may not be active yet");
        }
    }
}
