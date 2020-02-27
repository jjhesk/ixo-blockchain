#!/usr/bin/env bash

PASSWORD="12345678"
MIGUEL=$(yes $PASSWORD | ixocli keys show miguel -a)
FRANCESCO=$(yes $PASSWORD | ixocli keys show francesco -a)
FEE=$(yes $PASSWORD | ixocli keys show fee -a)

wait() {
  echo "Waiting for chain to start..."
  while :; do
    RET=$(ixocli status 2>&1)
    if [[ ($RET == ERROR*) || ($RET == *'"latest_block_height": "0"'*) ]]; then
      sleep 1
    else
      echo "A few more seconds..."
      sleep 6
      break
    fi
  done
}

tx_from_m() {
  cmd=$1
  shift
  yes $PASSWORD | ixocli tx bonds "$cmd" --from miguel -y --broadcast-mode block "$@"
}

tx_from_f() {
  cmd=$1
  shift
  yes $PASSWORD | ixocli tx bonds "$cmd" --from francesco -y --broadcast-mode block "$@"
}

RET=$(ixocli status 2>&1)
if [[ ($RET == ERROR*) || ($RET == *'"latest_block_height": "0"'*) ]]; then
  wait
fi

echo "Creating bond..."
ixocli tx bonds create-bond \
  --token=abc \
  --name="A B C" \
  --description="Description about A B C" \
  --function-type=swapper_function \
  --function-parameters="" \
  --reserve-tokens=res,rez \
  --tx-fee-percentage=0.5 \
  --exit-fee-percentage=0.1 \
  --fee-address="$FEE" \
  --max-supply=1000000abc \
  --order-quantity-limits="10abc,5000res,5000rez" \
  --sanity-rate="0.5" \
  --sanity-margin-percentage="20" \
  --allow-sells=true \
  --signers="$MIGUEL" \
  --batch-blocks=1 \
  --from=miguel \
  --bond-did="{\"did\":\"U7GK8p8rVhJMKhBVRCJJ8c\",\"verifyKey\":\"FmwNAfvV2xEqHwszrVJVBR3JgQ8AFCQEVzo1p6x4L8VW\",\"encryptionPublicKey\":\"domKpTpjrHQtKUnaFLjCuDLe2oHeS4b1sKt7yU9cq7m\",\"secret\":{\"seed\":\"933e454dbcfc1437f3afc10a0cd512cf0339787b6595819849f53707c268b053\",\"signKey\":\"Aun1EpjR1HQu1idBsPQ4u4C4dMwtbYPe1SdSC5bUerFC\",\"encryptionPrivateKey\":\"Aun1EpjR1HQu1idBsPQ4u4C4dMwtbYPe1SdSC5bUerFC\"}}"
sleep 6
echo "Created bond..."
ixocli query bonds bond U7GK8p8rVhJMKhBVRCJJ8c

echo "Miguel buys 1abc..."
tx_from_m buy 1abc 500res,1000rez U7GK8p8rVhJMKhBVRCJJ8c
echo "Miguel's account..."
ixocli query auth account "$MIGUEL"

echo "Francesco buys 10abc..."
tx_from_f buy 10abc 10100res,10100rez U7GK8p8rVhJMKhBVRCJJ8c
echo "Francesco's account..."
ixocli query auth account "$FRANCESCO"

echo "Miguel swap 500 res to rez..."
tx_from_m swap 500 res rez U7GK8p8rVhJMKhBVRCJJ8c
echo "Miguel's account..."
ixocli query auth account "$MIGUEL"

echo "Francesco swap 500 rez to res..."
tx_from_f swap 500 rez res U7GK8p8rVhJMKhBVRCJJ8c
echo "Francesco's account..."
ixocli query auth account "$FRANCESCO"

echo "Miguel swaps above order limit..."
tx_from_m swap 5001 res rez U7GK8p8rVhJMKhBVRCJJ8c
echo "Miguel's account (no  changes)..."
ixocli query auth account "$MIGUEL"

echo "Francesco swaps to violate sanity..."
tx_from_f swap 5000 rez res U7GK8p8rVhJMKhBVRCJJ8c
echo "Francesco's account (no changes)..."
ixocli query auth account "$FRANCESCO"

echo "Miguel sells 1abc..."
tx_from_m sell 1abc U7GK8p8rVhJMKhBVRCJJ8c
echo "Miguel's account..."
ixocli query auth account "$MIGUEL"

echo "Francesco sells 10abc..."
tx_from_f sell 10abc U7GK8p8rVhJMKhBVRCJJ8c
echo "Francesco's account..."
ixocli query auth account "$FRANCESCO"
