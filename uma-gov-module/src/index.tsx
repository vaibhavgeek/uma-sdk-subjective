import React, { useState } from 'react'
import { ethers, BrowserProvider } from 'ethers'
import contractABI from './abi/abi.json';

// Delete me
interface ThingProps {
  yesText?: string;
  noText?: string;
  Content?: string;
  criteria: string;
}

export const Thing: React.FC<ThingProps> = ({ yesText, noText, Content, criteria }): JSX.Element => {
  const [isWalletConnected, setIsWalletConnected] = useState(false)
  const [provider, setProvider] = useState<any>(null)
  const [signer, setSigner] = useState<any>(null)
  const [account, setAccount] = useState<string | null>(null)
  console.log(isWalletConnected);
  console.log(provider);
  console.log(account);
  console.log(signer);
  async function callContractWriteMethod(contractAddress: string, abi: any[], methodName: string, args: any[], signerf: ethers.Signer) {
    try {
      // Create a new instance of the contract
      const contract = new ethers.Contract(contractAddress, abi, signerf);
      console.log("what is contract?",contract);
      // Call the write method
      console.log(contract['assertContent'])
      const tx = await contract['assertContent']("0x1cfebf380af3bc2947a0e53fec728694d2d33fb8773e74d80a8e16a1a84fbd25", "NOT FAKE");
  
      // Wait for the transaction to be mined
      await tx.wait();
  
      console.log('Transaction successful:', tx);
    } catch (error) {
      console.error('Transaction failed:', error);
    }
  }

  async function callMeOnRun() {
    alert("26w");
    console.log("somitshit");
    console.log(contractABI);
    console.log(callContractWriteMethod);
    const contractAddress = '0x99bda3309830ddC444D8Fc82423675b0613a446F';
    const abi : any= contractABI["abi"];
    const methodName = 'assertContest';
    const args : any  = ["0xab8b7dd0799f177a88b1f07a739441e5a3a4b87995600bb0ffb5cff5f0ac458f", "SILLY"];
  
    // Call the function
    await callContractWriteMethod(contractAddress, abi, methodName, args, signer);
  }

  const connectMetaMask = async () => {
    if ((window as any).ethereum) {
      try {
        const newProvider = new BrowserProvider((window as any).ethereum)

        setProvider(newProvider)
        const newSigner = await newProvider.getSigner()
        setSigner(newSigner)
        const accounts = await newProvider.send('eth_requestAccounts', [])
        setAccount(accounts[0])
        setIsWalletConnected(true)
      } catch (error) {
        console.error('Could not get accounts', error)
      }
    } else {
      console.error('Please install MetaMask!')
    }
  }
 

  return   <div>
  <div style={{ "padding": "10px"}}>
      <h3>{criteria}</h3>
  </div>
  <div style={{"width":"100%","height":"150px","backgroundColor":"#f0f0f0"}}>
      {Content}
  </div>
  <div>
      <button type="button" onClick={connectMetaMask} 
     >{noText}</button>
      <button type="button" onClick={() => callMeOnRun()} >{yesText}</button>
  </div>
  <div className="post-content">
      {/* Add post content here (e.g., captions, comments) */}
  </div>
</div>
};
