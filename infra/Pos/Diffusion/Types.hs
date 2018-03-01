{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE RankNTypes #-}

module Pos.Diffusion.Types
    ( DiffusionLayer (..)
    , Diffusion (..)
    , hoistDiffusion
    , dummyDiffusionLayer
    ) where

import           Universum
import           Formatting                       (Format)
import           Pos.Communication.Types.Protocol (NodeId)
import           Pos.Core.Block                   (Block, BlockHeader, MainBlockHeader)
import           Pos.Core                         (HeaderHash, ProxySKHeavy)
import           Pos.Core.Txp                     (TxAux)
import           Pos.Core.Update                  (UpId, UpdateVote, UpdateProposal)
import           Pos.Reporting.Health.Types       (HealthStatus (..))
import           Pos.Core.Ssc                     (Opening, InnerSharesMap, SignedCommitment,
                                                   VssCertificate)
import           Pos.Util.Chrono                  (OldestFirst (..))

-- | The interface to a diffusion layer, i.e. some component which takes care
-- of getting data in from and pushing data out to a network.
data Diffusion m = Diffusion
    { -- | Get all blocks from a set of checkpoints to a given tip.
      -- The blocks come in oldest first, and form a chain (prev header of
      -- {n}'th is the header of {n-1}th.
      getBlocks          :: NodeId
                         -> BlockHeader
                         -> [HeaderHash]
                         -> m (OldestFirst [] Block)
      -- | Request tip-of-chain from peers.
      -- Each value in the map will block until the header has been received.
      -- In IO treatments, one would probably throw an IO exception in case it
      -- could not be retrieved.
    , requestTips        :: m (Map NodeId (m BlockHeader))
      -- | Announce a block header.
    , announceBlockHeader :: MainBlockHeader -> m ()
      -- | Returns a Bool iff at least one peer accepted the transaction.
      -- I believe it's for the benefit of wallets who wish to know that the
      -- transaction has a hope of making it into a block.
    , sendTx             :: TxAux -> m Bool
      -- | Send an update proposal.
    , sendUpdateProposal :: UpId -> UpdateProposal -> [UpdateVote] -> m ()
      -- | Send a vote for a proposal.
    , sendVote           :: UpdateVote -> m ()
      -- | SSC: send our certificate (diffusion layer takes care of relaying
      -- certs for other stakeholders).
    , sendSscCert        :: VssCertificate -> m ()
      -- | SSC: send our opening (diffusion layer takes care of relaying openings
      -- for other stakeholders).
    , sendSscOpening     :: Opening -> m ()
      -- | SSC: send our shares (diffusion layer takes care of relaying shares
      -- for other stakeholders).
    , sendSscShares      :: InnerSharesMap -> m ()
      -- | SSC: send our commitment (diffusion layer takes care of relaying
      -- commitments for other stakeholders).
    , sendSscCommitment  :: SignedCommitment -> m ()
      -- | Delegation: send a heavy certificate.
    , sendPskHeavy       :: ProxySKHeavy -> m ()

      -- | FIXME stopgap measure: there's an amazon route53 health check server
      -- that we have to support. Also a reporting mechanism that still
      -- demands to know the current set of peers we may be talking to.
      -- In the future we should roll this in with a more general status/debug
      -- system: to be used by the reporting mechanism (supply info about
      -- network topology) and also by the user interface (how's our connection
      -- quality?). [CSL-2147]
    , healthStatus       :: m HealthStatus
    , formatPeers        :: forall r . (forall a . Format r a -> a) -> m (Maybe r)
    }

-- | A diffusion layer: its interface, and a way to run it.
data DiffusionLayer m = DiffusionLayer
    { runDiffusionLayer :: forall x . m x -> m x
    , diffusion         :: Diffusion m
    }

hoistDiffusion :: Functor m => (forall t . m t -> n t) -> Diffusion m -> Diffusion n
hoistDiffusion nat orig = Diffusion
    { getBlocks = \nid bh hs -> nat $ getBlocks orig nid bh hs
    , requestTips = nat $ (fmap . fmap) nat (requestTips orig)
    , announceBlockHeader = nat . announceBlockHeader orig
    , sendTx = nat . sendTx orig
    , sendUpdateProposal = \upid upp upvs -> nat $ sendUpdateProposal orig upid upp upvs
    , sendVote = nat . sendVote orig
    , sendSscCert = nat . sendSscCert orig
    , sendSscOpening = nat . sendSscOpening orig
    , sendSscShares = nat . sendSscShares orig
    , sendSscCommitment = nat . sendSscCommitment orig
    , sendPskHeavy = nat . sendPskHeavy orig
    , healthStatus = nat $ healthStatus orig
    , formatPeers = \fmt -> nat $ formatPeers orig fmt
    }

-- | A diffusion layer that does nothing.
dummyDiffusionLayer :: Applicative m => DiffusionLayer m
dummyDiffusionLayer = DiffusionLayer
    { runDiffusionLayer = identity
    , diffusion         = dummyDiffusion
    }
  where
    dummyDiffusion :: Applicative m => Diffusion m
    dummyDiffusion = Diffusion
        { getBlocks          = \_ _ _ -> pure (OldestFirst [])
        , requestTips        = pure mempty
        , announceBlockHeader = \_ -> pure ()
        , sendTx             = \_ -> pure True
        , sendUpdateProposal = \_ _ _ -> pure ()
        , sendVote           = \_ -> pure ()
        , sendSscCert        = \_ -> pure ()
        , sendSscOpening     = \_ -> pure ()
        , sendSscShares      = \_ -> pure ()
        , sendSscCommitment  = \_ -> pure ()
        , sendPskHeavy       = \_ -> pure ()
        , healthStatus       = pure (HSUnhealthy "I'm a dummy")
        , formatPeers        = \_ -> pure Nothing
        }
