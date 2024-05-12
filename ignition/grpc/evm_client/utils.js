const grpc = require("@grpc/grpc-js");
const protoLoader = require("@grpc/proto-loader");
const { writeFileSync, readFileSync } = require("fs");
const { ethers } = require("hardhat");

let PROTO_PATH = __dirname + "./../protos/client.proto";
const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true,
});

const pullProto = grpc.loadPackageDefinition(packageDefinition).pull_service;
const client = new pullProto.PullService(
  "mainnet-dora.supraoracles.com",
  grpc.credentials.createSsl()
);

const pairIndexes = [19]; // Set the pair indexes as an array (ETH-USD)
const chainType = "evm"; // Set the chain type (evm, sui, aptos)
const request = {
  pair_indexes: pairIndexes,
  chain_type: chainType,
};
console.log("Requesting proof for price index : ", request.pair_indexes);

const getClientProof = () => {
  client.getProof(request, (err, response) => {
    if (err) {
      console.error("Error:", err.details);
      return;
    }
    console.log("Calling contract to verify the proofs.. ");
    console.log(response.evm.proof_bytes);
    const addressDir = `${__dirname}`;
    writeFileSync(
      `${__dirname}/proofbytes.txt`,
      JSON.stringify(response.evm.proof_bytes, null, 2)
    );
  });
};

const getSimpleProofBytes = () => {
  let jsonData = readFileSync(`${__dirname}/proofbytes_simple.txt`);
  jsonData = JSON.parse(jsonData, null, 2);
  return ethers.utils.hexlify(jsonData.data);
};

const getProofBytes = () => {
  let jsonData = readFileSync(`${__dirname}/proofbytes.txt`);
  jsonData = JSON.parse(jsonData, null, 2);
  return ethers.utils.hexlify(jsonData.data);
};

// getClientProof();

module.exports = {
  getSimpleProofBytes,
  getProofBytes,
};
