## 内容

### 1. 通过forge安装Uniswap的Permit2合约仓库,并部署到本地Anvil测试网
### 2. 部署TestToken合约(ERC20代币)
### 3. 部署TokenBank合约 构造函数为permit2合约地址,token地址
### 4. 将TestToken通过Approve授权给Permit2合约
### 5. 测试TokenBank合约的存款函数depositWithPermit2