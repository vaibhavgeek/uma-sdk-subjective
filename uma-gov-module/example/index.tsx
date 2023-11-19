import 'react-app-polyfill/ie11';
import React, { useEffect, useState } from 'react'
import * as ReactDOM from 'react-dom';
import {Thing} from './../src/index';
import { Tabs, Tab } from './tabs';
// import { ethers, BrowserProvider } from 'ethers'

const App = () => {
  const [isWalletConnected, setIsWalletConnected] = useState(false)
  const [provider, setProvider] = useState<any>(null)
  const [signer, setSigner] = useState<any>(null)
  const [account, setAccount] = useState<string | null>(null)
  
  // async function callContractWriteMethod(contractAddress: string, abi: any[], methodName: string, args: any[], signer: ethers.Signer) {
  //   try {
  //     // Create a new instance of the contract
  //     const contract = new ethers.Contract(contractAddress, abi, signer);
  
  //     // Call the write method
  //     const tx = await contract[methodName](...args);
  
  //     // Wait for the transaction to be mined
  //     await tx.wait();
  
  //     console.log('Transaction successful:', tx);
  //   } catch (error) {
  //     console.error('Transaction failed:', error);
  //   }
  // }

  // const fact = async () => {
  //   const contractAddress = 'YOUR_CONTRACT_ADDRESS';
  //   const abi = [/* ...contract ABI... */];
  //   const methodName = 'yourMethodName';
  //   const args = [/* ...method arguments... */];
  
  //   // Call the function
  //   await callContractWriteMethod(contractAddress, abi, methodName, args, signer);
  // }
  // const connectMetaMask = async () => {
  //   if ((window as any).ethereum) {
  //     try {
  //       const newProvider = new BrowserProvider((window as any).ethereum)

  //       setProvider(newProvider)
  //       const newSigner = await newProvider.getSigner()
  //       setSigner(newSigner)
  //       const accounts = await newProvider.send('eth_requestAccounts', [])
  //       setAccount(accounts[0])
  //       setIsWalletConnected(true)
  //     } catch (error) {
  //       console.error('Could not get accounts', error)
  //     }
  //   } else {
  //     console.error('Please install MetaMask!')
  //   }
  // }

  return (
    <div>
      <button>Connect Metamask</button>
    <div style={{"border":"1px solid #dbdbdb","borderRadius":"10px","width":"300px","margin":"20px auto","backgroundColor":"white"}}>
      <div>
      <Tabs>
      <Tab label="Fact or Opinion">
        <Thing criteria='Criteria: All Fact' Content={"The Earth orbits the Sun."} yesText={"Fact"} noText={"Opinion"} />
        <Thing criteria='Criteria: 3/5 Facts and 2/5 Opinion' Content={"Coffee is Derived from Coffee Beans, Coffee is One of the Most Popular Beverages Worldwide, Caffeine is a Major Component of Coffee, Coffee Tastes Best When Freshly Brewed,Adding Sugar Ruins the True Flavor of Coffee"} yesText={"According to Criteria"} noText={"Not According"} />

      </Tab>

      <Tab label="Funny or Not">
        <Thing criteria='Criteria: Chuckle Laughter' Content={"Why don't scientists trust atoms? Because they make up everything!"} yesText={"Funny"} noText={"Not Funny"} />
        <Thing criteria='Criteria: ROFL' Content={"Why did the scarecrow win an award? Because he was outstanding in his field!"} yesText={"Funny"} noText={"Not Funny"} />
        <Thing criteria='Criteria: Smile' Content={"What do you call fake spaghetti? An impasta!"} yesText={"Funny"} noText={"Not Funny"} />

      </Tab>
        
      <Tab label="Deepfake or Real">
          Content for Tab 3
      </Tab>
      </Tabs>
    </div>
      
    </div></div>
  );
};

ReactDOM.render(<App />, document.getElementById('root'));
