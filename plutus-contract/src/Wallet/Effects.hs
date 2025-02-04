{-# LANGUAGE DataKinds          #-}
{-# LANGUAGE DeriveAnyClass     #-}
{-# LANGUAGE DeriveGeneric      #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE DerivingVia        #-}
{-# LANGUAGE FlexibleContexts   #-}
{-# LANGUAGE GADTs              #-}
{-# LANGUAGE KindSignatures     #-}
{-# LANGUAGE LambdaCase         #-}
{-# LANGUAGE NamedFieldPuns     #-}
{-# LANGUAGE OverloadedStrings  #-}
{-# LANGUAGE TemplateHaskell    #-}
module Wallet.Effects(
    WalletEffects
    -- * Wallet effect
    , WalletEffect(..)
    , Payment(..)
    , submitTxn
    , ownPubKey
    , updatePaymentWithChange
    , walletSlot
    , ownOutputs
    , walletAddSignature
    -- * Node client
    , NodeClientEffect(..)
    , publishTx
    , getClientSlot
    -- * Chain index
    , ChainIndexEffect(..)
    , AddressChangeRequest(..)
    , AddressChangeResponse(..)
    , startWatching
    , watchedAddresses
    , confirmedBlocks
    , transactionConfirmed
    , addressChanged
    -- * Contract runtime
    , ContractRuntimeEffect(..)
    , sendNotification
    ) where

import           Control.Monad.Freer.TH (makeEffect)
import           Ledger                 (Address, Block, PubKey, Slot, Tx, TxId, Value)
import           Ledger.AddressMap      (AddressMap, UtxoMap)
import           Wallet.Types           (AddressChangeRequest (..), AddressChangeResponse (..), Notification,
                                         NotificationError, Payment (..))

data WalletEffect r where
    SubmitTxn :: Tx -> WalletEffect ()
    OwnPubKey :: WalletEffect PubKey
    UpdatePaymentWithChange :: Value -> Payment -> WalletEffect Payment
    WalletSlot :: WalletEffect Slot
    OwnOutputs :: WalletEffect UtxoMap
    WalletAddSignature :: Tx -> WalletEffect Tx
makeEffect ''WalletEffect

data NodeClientEffect r where
    PublishTx :: Tx -> NodeClientEffect ()
    GetClientSlot :: NodeClientEffect Slot
makeEffect ''NodeClientEffect

{-| Access the chain index. The chain index keeps track of the
    datums that are associated with unspent transaction outputs. Addresses that
    are of interest need to be added with 'startWatching' before their outputs
    show up in the 'AddressMap' returned by 'watchedAddresses'.
-}
data ChainIndexEffect r where
    StartWatching :: Address -> ChainIndexEffect ()
    WatchedAddresses :: ChainIndexEffect AddressMap
    ConfirmedBlocks :: ChainIndexEffect [Block]
    -- TODO: In the future we should have degrees of confirmation
    TransactionConfirmed :: TxId -> ChainIndexEffect Bool
    AddressChanged :: AddressChangeRequest -> ChainIndexEffect AddressChangeResponse
makeEffect ''ChainIndexEffect

{-| Interact with other contracts.
-}
data ContractRuntimeEffect r where
    SendNotification :: Notification -> ContractRuntimeEffect (Maybe NotificationError)

makeEffect ''ContractRuntimeEffect

-- | Effects that allow contracts to interact with the blockchain
type WalletEffects =
    '[ WalletEffect
    , NodeClientEffect
    , ChainIndexEffect
    , ContractRuntimeEffect
    ]
