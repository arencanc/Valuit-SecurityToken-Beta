import { ethers } from "hardhat";
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

export async function deployDiamond() {
  const networkName = (await ethers.provider.getNetwork()).name;
  const chainid = (await ethers.provider.getNetwork()).chainId;
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Network name=", networkName);
  console.log("Network chain id=", chainid);

  // deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
  const diamondCutFacet = await DiamondCutFacet.deploy()
  await diamondCutFacet.deployed()
  console.log('DiamondCutFacet deployed:', diamondCutFacet.address)

  // deploy DiamondCutFacet
  const DiamondLoupeFacet = await ethers.getContractFactory('DiamondLoupeFacet')
  const diamondLoupeFacet = await DiamondLoupeFacet.deploy()
  await diamondLoupeFacet.deployed()
  console.log('diamondLoupeFacet deployed:', diamondLoupeFacet.address)
  
  await new Promise(f => setTimeout(f, 1000));

  // deploy ProjectRegistryFacet
  const ProjectRegistryFacet = await ethers.getContractFactory('ProjectRegistryFacet')
  const projectRegistryFacet = await ProjectRegistryFacet.deploy()
  await projectRegistryFacet.deployed()
  console.log('ProjectRegistryFacet deployed:', projectRegistryFacet.address)

  // deploy ProjectRegistryFacet
  const STRegistryFacet = await ethers.getContractFactory('STRegistryFacet')
  const stRegistryFacet = await STRegistryFacet.deploy()
  await stRegistryFacet.deployed()
  console.log('STRegistryFacet deployed:', stRegistryFacet.address)

  // deploy facets
  console.log('')
  console.log('Deploying facets')

  const cut = []

  cut.push({
    facetAddress: diamondCutFacet.address,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(diamondCutFacet)
  })
  cut.push({
    facetAddress: diamondLoupeFacet.address,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(diamondLoupeFacet)
  })
  cut.push({
    facetAddress: projectRegistryFacet.address,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(projectRegistryFacet)
  })
  cut.push({
    facetAddress: stRegistryFacet.address,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(stRegistryFacet)
  })

  const FacetNames = [
    'OwnershipFacet',
    'ProjectFactoryFacet',
    'STFactoryFacet',
  ]

  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName)
    const facet = await Facet.deploy()
    await facet.deployed()
    console.log(`${FacetName} deployed: ${facet.address}`)
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet)
    })
  }

  // deploy ValuitRegistryProxy
  const ValuitRegistryProxy = await ethers.getContractFactory('ValuitRegistryProxy')
  const valuitRegistryProxy = await ValuitRegistryProxy.deploy(cut)
  await valuitRegistryProxy.deployed()
  console.log('ValuitRegistryProxy deployed:', valuitRegistryProxy.address)

  const SecurityTokenV1 = await ethers.getContractFactory("SecurityTokenV1");
  const securityTokenV1 = await SecurityTokenV1.deploy();
  // const securityToken = await SecurityToken.deploy("POLARIS Securities Example", "POLA", 1, mirrorToken.address, ['0xDA50FF6D7e4C4D4458cc9DE70fA82045A525CA58'], ['0x506F6C6172697300000000000000000000000000000000000000000000000000', '0x4C756E6100000000000000000000000000000000000000000000000000000000', '0x47616D6D61000000000000000000000000000000000000000000000000000000', '0x5374656C6C610000000000000000000000000000000000000000000000000000']);
  await securityTokenV1.deployed();
  console.log("Security Token V1 deployed to :", securityTokenV1.address);

  const ownershipFacet = await ethers.getContractAt("OwnershipFacet", valuitRegistryProxy.address);
  console.log('Owner()',await ownershipFacet.owner());

  const stoRegistry = await ethers.getContractAt("STRegistryFacet", valuitRegistryProxy.address);
  await stoRegistry.addNewLogicalContractVersion("0x5631000000000000000000000000000000000000000000000000000000000000", securityTokenV1.address)

  console.log('Get implementation address',await stoRegistry.getLatestLogicalContractAddress("0x5631000000000000000000000000000000000000000000000000000000000000"));

  return valuitRegistryProxy.address
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}