/**
    Sen
    
    Website: https://senecaprotocol.com/
    Twitter: twitter.com/SenecaUSD
    Telegram: t.me/seneca_protocol
    Linktree: https://linktr.ee/senecaprotocol
**/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

abstract contract ERC20Burnable is Context, ERC20 {

    function burn(uint256 value) public virtual {
        _burn(_msgSender(), value);
    }

    function burnFrom(address account, uint256 value) public virtual {
        _spendAllowance(account, _msgSender(), value);
        _burn(account, value);
    }
}

import "../lib/token/oft/v2/fee/OFTWithFee.sol";
import "../lib/interfaces/UniswapAndSafeMath.sol";

/**
 * @title SEN
 * @author blockchainPhysicst
 * @notice SEN inherits from OFTWithFee, which enables SEN to create a Layer Zero bridge to other chains for the SEN token in the future
 * @notice addresses are given mint allowances, which can be used to mint SEN tokens
 */

contract SenToken is OFTWithFee {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public revShareWallet;
    address public treasuryWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    bool public blacklistRenounced = false;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => bool) blacklisted;

    uint256 public buyTotalFees;
    uint256 public buyRevShareFee;
    uint256 public buyLiquidityFee;
    uint256 public buyTreasuryFee;

    uint256 public sellTotalFees;
    uint256 public sellRevShareFee;
    uint256 public sellLiquidityFee;
    uint256 public sellTreasuryFee;

    uint256 public tokensForRevShare;
    uint256 public tokensForLiquidity;
    uint256 public tokensForTreasury;

    /******************/

    // exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    bool public preMigrationPhase = true;
    mapping(address => bool) public preMigrationTransferrable;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    /////////////////ERRORS//////////////////////////////////////////////////||
    error swapAmountError(uint256 amount, uint256 required);               //||
    error SwapAmountOutOfRange(uint256 amount, uint256 min, uint256 max);  //||
    error MaxTransactionAmountTooLow(uint256 amount, uint256 min);         //||
    error PairCannotBeRemoved(address pair, address uniswapV2Pair);        //||
    error MaxWalletAmountTooLow(uint256 amount, uint256 min);              //||
    error TransferFromZeroAddress();                                       //||
    error TransferToZeroAddress();                                         //||
    error TradingNotActive();                                              //||
    error BlacklistRightsRevoked();                                        //||
    error InvalidBlacklistAddress(address addr);                           //||
    error TransferExceedsLimit(uint256 amount, uint256 limit);             //||
    error WalletLimitExceeded(uint256 amount, uint256 limit);              //||
    error SenderBlacklisted(address sender);                               //||
    error ReceiverBlacklisted(address receiver);                           //||
    error UnauthorizedPreMigrationTransfer(address from);                  //||
    error InvalidTokenAddress(address token);                              //||
    error SellTransferExceedsLimit(uint256 amount, uint256 limit);         //||
    error SellFeeTooHigh(uint256 fee);                                     //||
    error BuyFeeTooHigh(uint256 fee);                                      //||
    error InvalidLiquidityPoolAddress(address lpAddress);                  //||
    /////////////////////////////////////////////////////////////////////////||

    event revShareWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event TreasuryWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor(address lzEndpoint) OFTWithFee("Seneca","SEN",18,lzEndpoint)  {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 _buyRevShareFee = 2;
        uint256 _buyLiquidityFee = 0;
        uint256 _buyTreasuryFee = 1;

        uint256 _sellRevShareFee = 2;
        uint256 _sellLiquidityFee = 0;
        uint256 _sellTreasuryFee = 1;

        uint256 totalSupply = 1_000_000 * 1e18;

        maxTransactionAmount = 10_000 * 1e18; // 1%
        maxWallet = 10_000 * 1e18; // 1% 
        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05% 

        buyRevShareFee = _buyRevShareFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyTreasuryFee = _buyTreasuryFee;
        buyTotalFees = buyRevShareFee + buyLiquidityFee + buyTreasuryFee;

        sellRevShareFee = _sellRevShareFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellTreasuryFee = _sellTreasuryFee;
        sellTotalFees = sellRevShareFee + sellLiquidityFee + sellTreasuryFee;

        revShareWallet = address(0x8093B910f402B906368E0E8Fc0240418DB3995c4); // set as revShare wallet
        treasuryWallet = owner(); // set as Treasury wallet

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        preMigrationTransferrable[owner()] = true;

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
        preMigrationPhase = false;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool) {

    uint256 minAmount = (totalSupply() * 1) / 100000; 
    uint256 maxAmount = (totalSupply() * 5) / 1000;

    if (newAmount < minAmount || newAmount > maxAmount) {
        revert SwapAmountOutOfRange(newAmount, minAmount, maxAmount); 
    }

    swapTokensAtAmount = newAmount;

    return true;
    }
    
    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {

    uint256 minAmount = ((totalSupply() * 5) / 1000) / 1e18;

    if (newNum < minAmount) {
        revert MaxTransactionAmountTooLow(newNum, minAmount);
    }

    maxTransactionAmount = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {

    uint256 minAmount = ((totalSupply() * 10) / 1000) / 1e18;  

    if (newNum < minAmount) {
        revert MaxWalletAmountTooLow(newNum, minAmount);
    }

    maxWallet = newNum * (10**18); 
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateBuyFees(
    uint256 _revShareFee,
    uint256 _liquidityFee, 
    uint256 _TreasuryFee
    ) external onlyOwner {
    buyRevShareFee = _revShareFee;
    buyLiquidityFee = _liquidityFee;
    buyTreasuryFee = _TreasuryFee;
    uint256 totalFees = _revShareFee + _liquidityFee + _TreasuryFee;
    if (totalFees > 5) {
        revert BuyFeeTooHigh(totalFees);
    }
    buyTotalFees = totalFees;
    }

    function updateSellFees(
    uint256 _revShareFee, 
    uint256 _liquidityFee,
    uint256 _TreasuryFee  
    ) external onlyOwner {

    sellRevShareFee = _revShareFee;
    sellLiquidityFee = _liquidityFee;
    sellTreasuryFee = _TreasuryFee;
    uint256 totalFees = _revShareFee + _liquidityFee + _TreasuryFee;
    if (totalFees > 5) {
        revert SellFeeTooHigh(totalFees);
    }
    sellTotalFees = totalFees; 
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) 
    external onlyOwner 
    {

    if (pair == uniswapV2Pair) {
        revert PairCannotBeRemoved(pair, uniswapV2Pair);
    }

    _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateRevShareWallet(address newRevShareWallet) external onlyOwner {
        emit revShareWalletUpdated(newRevShareWallet, revShareWallet);
        revShareWallet = newRevShareWallet;
    }

    function updateTreasuryWallet(address newWallet) external onlyOwner {
        emit TreasuryWalletUpdated(newWallet, treasuryWallet);
        treasuryWallet = newWallet;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklisted[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
    if (from == address(0)) {
        revert TransferFromZeroAddress();
    }

    if (to == address(0)) {
        revert TransferToZeroAddress();
    }

    if (blacklisted[from]) {
        revert SenderBlacklisted(from);
    }

    if (blacklisted[to]) {
        revert ReceiverBlacklisted(to);
    }

    if (preMigrationPhase && !preMigrationTransferrable[from]) {
        revert UnauthorizedPreMigrationTransfer(from);
    }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingActive) {
                    revert TradingNotActive(); 
                }

                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    if (amount > maxTransactionAmount) {
                        revert TransferExceedsLimit(amount, maxTransactionAmount);
                    }
                    if (amount + balanceOf(to) > maxWallet) {
                        revert WalletLimitExceeded(amount + balanceOf(to), maxWallet); 
                    }
                    }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] && 
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    if (amount > maxTransactionAmount) {
                    revert SellTransferExceedsLimit(amount, maxTransactionAmount);
                    }
                }

                else if (!_isExcludedMaxTransactionAmount[to]) {
                    if (amount + balanceOf(to) > maxWallet) {
                    revert WalletLimitExceeded(amount + balanceOf(to), maxWallet);
                    }
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForTreasury += (fees * sellTreasuryFee) / sellTotalFees;
                tokensForRevShare += (fees * sellRevShareFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForTreasury += (fees * buyTreasuryFee) / buyTotalFees;
                tokensForRevShare += (fees * buyRevShareFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForRevShare +
            tokensForTreasury;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForRevShare = ethBalance.mul(tokensForRevShare).div(totalTokensToSwap - (tokensForLiquidity / 2));
        
        uint256 ethForTreasury = ethBalance.mul(tokensForTreasury).div(totalTokensToSwap - (tokensForLiquidity / 2));

        uint256 ethForLiquidity = ethBalance - ethForRevShare - ethForTreasury;

        tokensForLiquidity = 0;
        tokensForRevShare = 0;
        tokensForTreasury = 0;

        (success, ) = address(treasuryWallet).call{value: ethForTreasury}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }

        (success, ) = address(revShareWallet).call{value: address(this).balance}("");
    }

    function withdrawStuckSen() external onlyOwner {
        uint256 balance = IERC20(address(this)).balanceOf(address(this));
        IERC20(address(this)).transfer(msg.sender, balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawStuckToken(address _token, address _to) external onlyOwner {
    if (_token == address(0)) {
        revert InvalidTokenAddress(_token); 
    }
    uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(_to, _contractBalance);
    }

    function withdrawStuckEth(address toAddr) external onlyOwner {
        (bool success, ) = toAddr.call{
            value: address(this).balance
        } ("");
        require(success);
    }

    // @dev Treasury renounce blacklist commands
    function renounceBlacklist() public onlyOwner {
        blacklistRenounced = true;
    }

    function blacklist(address _addr) external onlyOwner {

    if (blacklistRenounced) {
        revert BlacklistRightsRevoked();
    }

    if (
        _addr == address(uniswapV2Pair) || 
        _addr == address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
    ) {
        revert InvalidBlacklistAddress(_addr);
    }

    blacklisted[_addr] = true;
    }

    // @dev blacklist v3 pools; can unblacklist() down the road to suit project and community
// Errors


    function blacklistLiquidityPool(address lpAddress) external onlyOwner {

    if (blacklistRenounced) {
        revert BlacklistRightsRevoked();
    }

    if (
        lpAddress == address(uniswapV2Pair) ||
        lpAddress == address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)  
    ) {
        revert InvalidLiquidityPoolAddress(lpAddress);
    }

    blacklisted[lpAddress] = true;

    }

    // @dev unblacklist address; not affected by blacklistRenounced incase Treasury wants to unblacklist v3 pools down the road
    function unblacklist(address _addr) public onlyOwner {
        blacklisted[_addr] = false;
    }

    function setPreMigrationTransferable(address _addr, bool isAuthorized) public onlyOwner {
        preMigrationTransferrable[_addr] = isAuthorized;
        excludeFromFees(_addr, isAuthorized);
        excludeFromMaxTransaction(_addr, isAuthorized);
    }

}