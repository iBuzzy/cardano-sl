module Cardano.Wallet.API.V1.Accounts where

import           Servant

import           Cardano.Wallet.API.Response
import           Cardano.Wallet.API.V1.Parameters
import           Cardano.Wallet.API.V1.Types


type API
    = "accounts" :> (
        Capture "walletId" WalletId
          :> Capture "accountIndex" AccountIndex
          :> Summary "Deletes an Account."
          :> DeleteNoContent '[ValidJSON] NoContent
        :<|> Capture "walletId" WalletId
          :> Capture "accountIndex" AccountIndex
          :> Summary "Retrieves a specific Account."
          :> Get '[ValidJSON] (WalletResponse Account)
        :<|> Capture "walletId" WalletId
          :> WalletRequestParams
          :> Summary "Retrieves the full list of Accounts."
          :> Get '[ValidJSON] (WalletResponse [Account])
        :<|> Capture "walletId" WalletId
          :> Summary "Creates a new Account for the given Wallet."
          :> ReqBody '[ValidJSON] (New Account)
          :> Post '[ValidJSON] (WalletResponse Account)
        :<|> Capture "walletId" WalletId
          :> Capture "accountIndex" AccountIndex
          :> Summary "Update an Account for the given Wallet."
          :> ReqBody '[ValidJSON] (Update Account)
          :> Put '[ValidJSON] (WalletResponse Account)
    )
