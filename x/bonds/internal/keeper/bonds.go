package keeper

import (
	"fmt"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/ixofoundation/ixo-blockchain/x/bonds/internal/types"
	"github.com/ixofoundation/ixo-blockchain/x/did"
)

func (k Keeper) GetBondIterator(ctx sdk.Context) sdk.Iterator {
	store := ctx.KVStore(k.storeKey)
	return sdk.KVStorePrefixIterator(store, types.BondsKeyPrefix)
}

func (k Keeper) GetBond(ctx sdk.Context, bondDid did.Did) (bond types.Bond, found bool) {
	store := ctx.KVStore(k.storeKey)
	if !k.BondExists(ctx, bondDid) {
		return
	}
	bz := store.Get(types.GetBondKey(bondDid))
	k.cdc.MustUnmarshalBinaryBare(bz, &bond)
	return bond, true
}

func (k Keeper) GetBondDid(ctx sdk.Context, bondToken string) (bondDid did.Did, found bool) {
	store := ctx.KVStore(k.storeKey)
	if !k.BondDidExists(ctx, bondToken) {
		return
	}
	bz := store.Get(types.GetBondDidsKey(bondToken))
	k.cdc.MustUnmarshalBinaryBare(bz, &bondDid)
	return bondDid, true
}

func (k Keeper) MustGetBond(ctx sdk.Context, bondDid did.Did) types.Bond {
	bond, found := k.GetBond(ctx, bondDid)
	if !found {
		panic(fmt.Sprintf("bond '%s' not found\n", bondDid))
	}
	return bond
}

func (k Keeper) MustGetBondByKey(ctx sdk.Context, key []byte) types.Bond {
	store := ctx.KVStore(k.storeKey)
	if !store.Has(key) {
		panic("bond not found")
	}

	bz := store.Get(key)
	var bond types.Bond
	k.cdc.MustUnmarshalBinaryBare(bz, &bond)

	return bond
}

func (k Keeper) BondExists(ctx sdk.Context, bondDid did.Did) bool {
	store := ctx.KVStore(k.storeKey)
	return store.Has(types.GetBondKey(bondDid))
}

func (k Keeper) BondDidExists(ctx sdk.Context, bondToken string) bool {
	store := ctx.KVStore(k.storeKey)
	return store.Has(types.GetBondDidsKey(bondToken))
}

func (k Keeper) SetBond(ctx sdk.Context, bondDid did.Did, bond types.Bond) {
	store := ctx.KVStore(k.storeKey)
	store.Set(types.GetBondKey(bondDid), k.cdc.MustMarshalBinaryBare(bond))
}

func (k Keeper) SetBondDid(ctx sdk.Context, bondToken string, bondDid did.Did) {
	store := ctx.KVStore(k.storeKey)
	store.Set(types.GetBondDidsKey(bondToken), k.cdc.MustMarshalBinaryBare(bondDid))
}

func (k Keeper) GetReserveBalances(ctx sdk.Context, bondDid did.Did) sdk.Coins {
	bond := k.MustGetBond(ctx, bondDid)
	return k.BankKeeper.GetCoins(ctx, bond.ReserveAddress)
}

func (k Keeper) GetSupplyAdjustedForBuy(ctx sdk.Context, bondDid did.Did) sdk.Coin {
	bond := k.MustGetBond(ctx, bondDid)
	batch := k.MustGetBatch(ctx, bondDid)
	supply := bond.CurrentSupply
	return supply.Add(batch.TotalBuyAmount)
}

func (k Keeper) GetSupplyAdjustedForSell(ctx sdk.Context, bondDid did.Did) sdk.Coin {
	bond := k.MustGetBond(ctx, bondDid)
	batch := k.MustGetBatch(ctx, bondDid)
	supply := bond.CurrentSupply
	return supply.Sub(batch.TotalSellAmount)
}

func (k Keeper) SetCurrentSupply(ctx sdk.Context, bondDid did.Did, currentSupply sdk.Coin) {
	if currentSupply.IsNegative() {
		panic("current supply cannot be negative")
	}
	bond := k.MustGetBond(ctx, bondDid)
	bond.CurrentSupply = currentSupply
	k.SetBond(ctx, bondDid, bond)
}
