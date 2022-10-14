import { ethers } from "hardhat";
import { BigNumber, Wallet } from "ethers";

export const BASE_TEN = 10

export function getBigNumber(amount: number, decimals = 18) {
    return BigNumber.from(amount).mul(BigNumber.from(BASE_TEN).pow(decimals))
}

async function main() {
    const [deployer, accoun1, accoun2] = await ethers.getSigners();

    console.log("Using account:", deployer.address);
    console.log("User account:", accoun1.address);
    console.log("Account1 Balance", await accoun1.getBalance())

    const valuitCrowdsaleAddress = "0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6";
    const SecurityTokenContractAddress = '0x0165878A594ca255338adfa4d48449f69242Eb8F'
    const mirrorContractAddress = '0x5FC8d32690cc91D4c39d9d3abcBD16989F875707'
    const userWallet = '0x70997970c51812dc3a010c7d01b50e0d17dc79c8';

    const crowdsaleContract = await ethers.getContractAt("SecurityCrowdsale", valuitCrowdsaleAddress);
    const securityToken = await ethers.getContractAt("SecurityToken", SecurityTokenContractAddress);
    const mirrorToken = await ethers.getContractAt("MirrorToken", mirrorContractAddress);

    console.log('Is Pre ICO stage', await crowdsaleContract.isPreICO())
    console.log('Is Crowdsale closed', await crowdsaleContract.hasClosed())
    // const closeTx = await crowdsaleContract.setClosingTime(1648476735)
    // closeTx.wait();
    // console.log('Is Crowdsale closed', await crowdsaleContract.hasClosed())

    // console.log(getBigNumber(10))
    // const weiVal: BigNumber = ethers.utils.parseEther("7.43");
    
    // const tx = await accoun1.sendTransaction({to: crowdsaleContract.address, value: ethers.utils.parseEther("1.0")})
    const tx = await crowdsaleContract.connect(accoun1).buyTokens(userWallet, 0, {value: ethers.utils.parseEther("1.0")})
    console.log(tx);

    console.log('Balance of Security Tokens', await securityToken.balanceOf(userWallet))
    console.log('Balance of Security Tokens', await securityToken.balanceOfByPartition("0x47616D6D61000000000000000000000000000000000000000000000000000000", userWallet))
    console.log('Balance of Mirror Tokens', await mirrorToken.balanceOf(userWallet))
}

main().catch((error) => {
    solidity: {
        overrides: {
            value: ethers.utils.parseEther("0.1")
        }
    }
    console.error(error);
    process.exitCode = 1;
});