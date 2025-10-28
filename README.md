# KipuBankV2 🏦

Um contrato inteligente bancário avançado desenvolvido em Solidity que demonstra padrões modernos de DeFi, controle de acesso baseado em papéis e integração com oráculos.

## 📋 Visão Geral

O KipuBankV2 é uma evolução do contrato bancário original, implementando funcionalidades avançadas seguindo as melhores práticas da indústria DeFi. O contrato oferece um sistema completo de banking com controle de acesso granular, sistema de juros, integração com oráculos e recursos de segurança robustos.

## 🚀 Principais Melhorias Implementadas

### 1. **Controle de Acesso Baseado em Papéis (RBAC)**
- **DEFAULT_ADMIN_ROLE**: Gerencia todos os outros papéis
- **PAUSER_ROLE**: Pode pausar/despausar operações críticas
- **TREASURER_ROLE**: Pode fazer saques de emergência quando pausado
- **ORACLE_ROLE**: Pode atualizar dados de preços dos oráculos

### 2. **Declarações de Tipos Avançadas**
```solidity
struct UserAccount {
    uint256 totalDeposits;
    uint256 totalWithdrawals;
    uint256 lastDepositTime;
    uint256 lastWithdrawalTime;
    bool isActive;
    uint256 creditScore;
}

enum TransactionType {
    DEPOSIT,
    WITHDRAWAL,
    EMERGENCY_WITHDRAWAL,
    INTEREST_PAYMENT
}
```

### 3. **Integração com Oráculo Chainlink**
- Sistema de preços em tempo real usando `AggregatorV3Interface`
- Configuração flexível de múltiplos price feeds
- Cache de preços para otimização de gas
- Conversão automática ETH ↔ USD

### 4. **Variáveis Constantes Otimizadas**
- `DECIMAL_PRECISION`: Precisão decimal (18 casas)
- `MIN_DEPOSIT`: Depósito mínimo (0.001 ETH)
- `DAILY_WITHDRAWAL_LIMIT`: Limite diário de saque (10 ETH)
- `INTEREST_RATE_BPS`: Taxa de juros (0.5%)

### 5. **Mappings Aninhados Complexos**
```solidity
mapping(address user => mapping(uint256 day => uint256 amount)) public dailyWithdrawals;
mapping(address user => mapping(uint256 index => Transaction)) public userTransactions;
```

### 6. **Funções de Conversão de Decimais**
- `convertWeiToEth()`: Converte wei para ETH com precisão
- `convertEthToWei()`: Converte ETH para wei

## 🛠️ Funcionalidades Principais

### **Operações Bancárias**
- **Depósito**: Com validação de valor mínimo e limite do banco
- **Saque**: Com limites diários e validações de saldo
- **Sistema de Juros**: Cálculo automático de juros simples
- **Histórico de Transações**: Rastreamento completo de todas as operações

### **Recursos de Segurança**
- **Pausa de Emergência**: Capacidade de pausar operações em situações críticas
- **Saques de Emergência**: Resgate de fundos quando o contrato está pausado
- **Limites Diários**: Controle de saques por usuário por dia
- **Sistema de Crédito**: Pontuação de crédito para usuários

### **Integração Completa com Chainlink Oracle**
- **Configuração Dinâmica**: Sistema flexível para múltiplos price feeds usando `AggregatorV3Interface`
- **Validação Robusta**: Implementa TODAS as melhores práticas recomendadas pela Chainlink
- **Monitoramento de Saúde**: Verificação completa de dados stale, rounds inválidos e faixas de preço razoáveis
- **Dados Históricos**: Acesso completo a preços históricos para backtesting e análise
- **Cache Inteligente**: Sistema de cache para otimização de gas com validação temporal
- **Conversões Automáticas**: ETH ↔ USD usando preços validados do Chainlink com precisão decimal
- **Configuração Automática**: Deploy script configura automaticamente ETH/USD para Sepolia testnet
- **Suporte Multi-Rede**: Preparado para diferentes redes (Sepolia, Mainnet) com endereços específicos

## 📦 Instalação e Deploy

### **Pré-requisitos**
- Foundry (forge)
- Node.js (opcional, para scripts)
- Conta Ethereum com ETH para deploy

### **Instalação**
```bash
# Clone o repositório
git clone https://github.com/seu-usuario/KipuBankV2.git
cd KipuBankV2

# Instale as dependências
forge install OpenZeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std
forge install smartcontractkit/chainlink

# Compile o contrato
forge build
```

### **Deploy**
```bash
# Deploy em testnet (ex: Sepolia)
forge script script/DeployKipuBank.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify

# Deploy em mainnet
forge script script/DeployKipuBank.s.sol --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

### **Script de Deploy**
```solidity
// script/DeployKipuBank.s.sol
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {KipuBankV2} from "../src/KipuBankV2.sol";

contract DeployKipuBank is Script {
    function run() external {
        uint256 bankCap = 1000 ether; // Limite máximo do banco
        
        vm.startBroadcast();
        KipuBankV2 kipuBank = new KipuBankV2(bankCap);
        vm.stopBroadcast();
        
        console.log("KipuBankV2 deployed at:", address(kipuBank));
    }
}
```

## 🔧 Interação com o Contrato

### **Operações Básicas**
```solidity
// Depositar ETH
kipuBank.deposit{value: 1 ether}();

// Sacar ETH
kipuBank.withdraw(0.5 ether);

// Verificar saldo do contrato
uint256 balance = kipuBank.contractBalance();

// Calcular juros
uint256 interest = kipuBank.calculateInterest(userAddress);
```

### **Operações Administrativas**
```solidity
// Pausar contrato (apenas PAUSER_ROLE)
kipuBank.pause();

// Despausar contrato (apenas PAUSER_ROLE)
kipuBank.unpause();

// Saque de emergência (apenas TREASURER_ROLE quando pausado)
kipuBank.emergencyWithdraw(treasuryAddress, amount);

// Atualizar preço do Chainlink (apenas ORACLE_ROLE)
kipuBank.configurePriceFeed("ETH", "0x694AA1769357215DE4FAC081bf1f309aDC325306", "ETH / USD");

// Obter preço atual do Chainlink com validação completa
uint256 ethPrice = kipuBank.getLatestPrice("ETH");

// Monitorar saúde do price feed
(bool isHealthy, uint256 lastUpdate, uint256 price) = kipuBank.monitorPriceFeedHealth("ETH");

// Verificar se dados estão frescos (últimas 2 horas)
bool isFresh = kipuBank.isPriceFeedFresh("ETH", 2 hours);

// Obter dados históricos
(uint256 historicalPrice, uint256 timestamp) = kipuBank.getHistoricalPrice("ETH", roundId);

// Obter informações do price feed
(string memory description, uint8 decimals) = kipuBank.getPriceFeedInfo("ETH");

// Converter ETH para USD com validação
uint256 usdValue = kipuBank.convertEthToUsd(1 ether, "ETH");
```

### **Consultas**
```solidity
// Informações da conta do usuário
UserAccount memory account = kipuBank.getUserAccount(userAddress);

// Histórico de transações
Transaction memory tx = kipuBank.getUserTransaction(userAddress, 0);

// Saques diários
uint256 dailyAmount = kipuBank.getDailyWithdrawal(userAddress, today);
```

## 🔗 **Implementação Completa do Chainlink Oracle**

### **Arquitetura do Sistema Oracle**
Nosso contrato implementa uma integração completa e robusta com os Chainlink Data Feeds, seguindo todas as melhores práticas da documentação oficial:

#### **Componentes Implementados**
- **Consumer Contract**: KipuBankV2 como consumidor dos dados
- **Proxy Contract**: Interface para o aggregator atual (configurável)
- **Aggregator Contract**: Armazena dados agregados onchain
- **Price Feed Configuration**: Sistema dinâmico para múltiplos tokens
- **Data Validation**: Validação completa de todos os dados recebidos
- **Health Monitoring**: Monitoramento contínuo da saúde dos feeds

#### **Estruturas de Dados Oracle**
```solidity
struct PriceFeedConfig {
    AggregatorV3Interface priceFeed;
    string description;
    bool isActive;
}

struct PriceData {
    uint256 price;
    uint64 timestamp;
    bool isValid;
}
```

### **Validação de Dados Implementada**
Baseado na [documentação oficial do Chainlink](https://docs.chain.link/data-feeds), implementamos TODAS as validações recomendadas:

#### **1. Verificação de Dados Stale**
```solidity
// Verifica se dados são recentes (máximo 2 horas)
if (block.timestamp - updatedAt > staleThreshold) {
    revert KipuBank_InvalidPriceFeedData();
}
```

#### **2. Validação de Round ID**
```solidity
// Garante que a resposta é do round atual
if (answeredInRound < roundId) {
    revert KipuBank_InvalidPriceFeedData();
}
```

#### **3. Verificação de Faixas de Preço**
```solidity
// ETH/USD entre $100 e $50,000 (8 decimals)
uint256 minPrice = 100 * 10**8;
uint256 maxPrice = 50000 * 10**8;
```

#### **4. Monitoramento de Saúde**
```solidity
// Função completa de monitoramento
function monitorPriceFeedHealth(string calldata token) external view returns (
    bool isHealthy,
    uint256 lastUpdate,
    uint256 price
)
```

### **Funções Oracle Implementadas**

#### **Configuração e Gerenciamento**
- `configurePriceFeed()`: Configura novos price feeds dinamicamente
- `updateCachedPrice()`: Atualiza cache de preços com validação
- `getCachedPrice()`: Recupera preços do cache com verificação de validade

#### **Obtenção de Dados**
- `getLatestPrice()`: Obtém preço mais recente com validação completa
- `getHistoricalPrice()`: Acessa dados históricos por round ID
- `getLatestRoundId()`: Obtém ID do round mais recente
- `getPriceFeedInfo()`: Informações sobre descrição e decimais

#### **Monitoramento e Saúde**
- `monitorPriceFeedHealth()`: Verificação completa de saúde do feed
- `getPriceFeedConfig()`: Configurações de heartbeat e desvio
- `_validatePriceFeedData()`: Validação interna robusta

#### **Conversões de Moeda**
- `convertEthToUsd()`: Converte ETH para USD usando preços Chainlink
- `convertUsdToEth()`: Converte USD para ETH usando preços Chainlink

### **Componentes do Data Feed**
- **Consumer**: Nosso contrato KipuBankV2
- **Proxy Contract**: Aponta para o aggregator atual
- **Aggregator Contract**: Armazena dados agregados onchain

### **Benefícios da Nossa Implementação**
- 🛡️ **Segurança Máxima**: Implementa TODAS as validações recomendadas pela Chainlink
- ⚡ **Performance Otimizada**: Sistema de cache inteligente reduz chamadas desnecessárias
- 🔄 **Flexibilidade Total**: Configuração dinâmica para múltiplos tokens e redes
- 📊 **Monitoramento Completo**: Health checks e métricas detalhadas
- 🎯 **Precisão Garantida**: Validação de ranges de preço e dados stale
- 🚀 **Deploy Simplificado**: Configuração automática para Sepolia testnet

### **Uso Recomendado**
1. **Sempre use o proxy**: Nunca chame o aggregator diretamente
2. **Monitore timestamps**: Verifique se dados são recentes
3. **Valide ranges**: Implemente limites razoáveis para preços
4. **Trate erros**: Use try/catch para operações críticas
5. **Cache quando possível**: Reduza chamadas desnecessárias
6. **Use nossa implementação**: Já inclui todas as melhores práticas!

### **Configuração para Sepolia Testnet**
Nosso contrato está **perfeitamente configurado** para a rede Sepolia, ideal para aprendizado e testes:

#### **Configuração Automática no Deploy**
```solidity
// script/DeployKipuBank.s.sol
// ETH/USD Sepolia: 0x694AA1769357215DE4FAC081bf1f309aDC325306
address ethUsdPriceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
kipuBank.configurePriceFeed("ETH", ethUsdPriceFeed, "ETH / USD");
```

#### **Validações Específicas para Sepolia**
- ✅ **Endereço Oficial**: Usa o endereço oficial do Chainlink para Sepolia
- ✅ **Configuração Automática**: Script de deploy configura automaticamente
- ✅ **Teste Integrado**: Verifica se o price feed está funcionando após deploy
- ✅ **Limites Adequados**: Limite de 1000 ETH perfeito para testes
- ✅ **Validações Robustas**: Todas as validações de segurança implementadas

#### **Deploy na Sepolia**
```bash
# Deploy com configuração automática do Chainlink
forge script script/DeployKipuBank.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

### **Endereços de Referência**
- **ETH/USD Sepolia**: `0x694AA1769357215DE4FAC081bf1f309aDC325306` ✅ **OFICIAL**
- **ETH/USD Mainnet**: `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419`
- **Mais endereços**: [Chainlink Data Feeds Addresses](https://docs.chain.link/data-feeds/price-feeds/addresses)

## 🏗️ Arquitetura e Decisões de Design

### **Padrões Implementados**
1. **Access Control Pattern**: Controle granular de acesso usando OpenZeppelin
2. **Pausable Pattern**: Capacidade de pausar operações em emergências
3. **Oracle Pattern**: Integração com dados externos (simulada)
4. **State Machine Pattern**: Estados controlados para diferentes operações

### **Trade-offs Considerados**

#### **Gas vs. Funcionalidade**
- **Prós**: Funcionalidades ricas com controle granular
- **Contras**: Maior consumo de gas devido à complexidade
- **Decisão**: Priorizar segurança e funcionalidade sobre otimização extrema de gas

#### **Centralização vs. Descentralização**
- **Prós**: Controle administrativo para emergências
- **Contras**: Dependência de roles administrativos
- **Decisão**: Balancear autonomia com capacidade de resposta a emergências

#### **Simplicidade vs. Robustez**
- **Prós**: Sistema robusto com múltiplas camadas de segurança
- **Contras**: Maior complexidade para desenvolvedores
- **Decisão**: Priorizar robustez para aplicações DeFi reais

### **Considerações de Segurança**
1. **Reentrancy Protection**: Uso de padrões CEI (Checks-Effects-Interactions)
2. **Access Control**: Múltiplas camadas de controle de acesso
3. **Input Validation**: Validação rigorosa de todos os inputs
4. **Emergency Procedures**: Procedimentos claros para situações de emergência

## 🧪 Testes

```bash
# Executar todos os testes
forge test

# Executar testes com verbosidade
forge test -vvv

# Executar testes específicos
forge test --match-test testDeposit
```

## 📊 Métricas e Monitoramento

### **Eventos Importantes**
- `KipuBank_SuccessfullyDeposited`: Depósitos realizados
- `KipuBank_SuccessfullyWithdrawn`: Saques realizados
- `KipuBank_InterestPaid`: Juros pagos
- `KipuBank_OraclePriceUpdated`: Atualizações de preço
- `KipuBank_CreditScoreUpdated`: Atualizações de crédito

### **Métricas Disponíveis**
- Total de depósitos realizados
- Total de saques realizados
- Total de juros pagos
- Número de atualizações de oráculo
- Contadores por usuário

## 🔒 Segurança

### **Auditoria Recomendada**
- Revisão de código por especialistas em segurança
- Testes de penetração
- Análise de vulnerabilidades automatizada
- Testes de stress e carga

### **Considerações de Produção**
- Deploy gradual com limites baixos inicialmente
- Monitoramento ativo de eventos e métricas
- Procedimentos de emergência bem definidos
- Backup e recuperação de dados críticos

## 📝 Licença

MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 👥 Contribuição

Contribuições são bem-vindas! Por favor:
1. Faça um fork do projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📞 Contato

- **Autor**: Barba - 77 Innovation Labs
- **Social**: anySocial/i3arba
- **Projeto**: Ethereum Developer Pack / Brazil

---

**⚠️ Aviso**: Este contrato é para fins educacionais e de demonstração. Não use em produção sem auditoria completa e testes extensivos.