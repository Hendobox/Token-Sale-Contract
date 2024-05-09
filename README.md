# Interview Project: Token Sale Contract

<a href="https://github.com/new?owner=Leggo-Build&template_name=interview-token-sale&template_owner=Leggo-Build" target="_blank" rel="noopener noreferrer">
  <img src="https://img.shields.io/:Use_This_Template-238636.svg?logo=github&logoColor=whitesmoke" height="30px" />
</a>

## Features
- Allow admin to set the token price in USD
- Allow token prices to increase at certain time frames
- Linear Vest of the tokens bought
- Accept ETH (should use Supra price oracles to do the ETH to USD conversion)
- Vest should start at end of TGE
- Vest should be represented as an NFT

## Criteria
- Readable code
- Use of interfaces
- Use of Solidity NatSpec comments
- E2E tests
  - Test parameters should be 
    - 1 month vest
    - 9 day sale
      - $10/first 3 days
      - $15/next 3 days
      - $20/last 3 days
    - Have users make varying sales during the 3 time frames
    - Simulate vesting
    - Ensure transfering the Vest NFT works appropriately for the receiving user
   
## Getting Started
1. Use this project as a template  
    <a href="https://github.com/new?owner=Leggo-Build&template_name=interview-token-sale&template_owner=Leggo-Build" target="_blank" rel="noopener noreferrer">
      <img src="https://img.shields.io/:Use_This_Template-238636.svg?logo=github&logoColor=whitesmoke" />
    </a>
  
2. Make changes to your repo
3. Submit a link to your repo to us
