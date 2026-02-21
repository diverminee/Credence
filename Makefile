.PHONY: build test test-v snapshot fmt clean deploy-local deploy-sepolia deploy-chainlink

build:
	forge build

test:
	forge test

test-v:
	forge test -vvv

test-deploy:
	forge test --match-path test/DeployCredenceTest.t.sol -vvv

snapshot:
	forge snapshot

fmt:
	forge fmt

clean:
	rm -rf out/ cache/ broadcast/ .env.deployed

deploy-local:
	forge script script/DeployCredence.s.sol --rpc-url http://127.0.0.1:8545 --broadcast

deploy-sepolia:
	forge script script/DeployCredence.s.sol --rpc-url $${SEPOLIA_RPC_URL} --broadcast --verify

deploy-chainlink:
	USE_CHAINLINK_ORACLE=true forge script script/DeployCredence.s.sol --rpc-url $${SEPOLIA_RPC_URL} --broadcast --verify
