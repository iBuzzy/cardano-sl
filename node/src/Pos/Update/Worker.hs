-- | Update System related workers.

module Pos.Update.Worker
       ( usWorkers
       ) where

import           Universum

import           Formatting                 (sformat, (%))
import           Serokell.Util.Text         (listJson)
import           System.Wlog                (logDebug)

import           Pos.Communication.Protocol (OutSpecs, WorkerSpec, localOnNewSlotWorker)
import           Pos.Constants              (curSoftwareVersion)
import           Pos.Context                (recoveryCommGuard)
import           Pos.Core                   (SoftwareVersion (..))
import           Pos.Update.DB              (getConfirmedProposals)
import           Pos.Update.Download        (downloadUpdate)
import           Pos.Update.Logic.Local     (processNewSlot)
import           Pos.Update.Poll            (ConfirmedProposalState (..))
import           Pos.WorkMode.Class         (WorkMode)

-- | Update System related workers.
usWorkers :: WorkMode ssc ctx m => ([WorkerSpec m], OutSpecs)
usWorkers =
    first pure $
    localOnNewSlotWorker True $ \s ->
        recoveryCommGuard $ do
            logDebug "Updating slot for US..."
            processNewSlot s
            checkForUpdate

checkForUpdate :: WorkMode ssc ctx m => m ()
checkForUpdate = do
    logDebug "Checking for update..."
    proposals <- getConfirmedProposals (Just $ svNumber curSoftwareVersion)
    logDebug $ sformat ("Potentially relevant proposals: "%listJson)
                    (cpsUpdateProposal <$> proposals)
    mapM_ downloadUpdate proposals
