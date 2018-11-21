# beacon_chain
# Copyright (c) 2018 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  tables, hashes, sets,
  milagro_crypto, # Needed for signature hashing
  ../ssz, ../datatypes, ../private/helpers

# This is an implementation of stage 1 of Casper Fork Choice rule
# according to the mini-specs https://ethresear.ch/t/beacon-chain-casper-ffg-rpj-mini-spec/2760

# Stage 1 does not include justification, finalization and a dynamic validator set

# ############################################################
#
#           Data types for Fork Choice Stage 1
#
# ############################################################

type
  BlockHash* = Blake2_256_Digest
  BeaconChain* = OrderedTableRef[BlockHash, BeaconBlock]
  Slot* = uint64

  SlotBlockHash* = tuple[slot: Slot, block_hash: BlockHash]

  ConsensusState* = ref object
    beacon_chain*: BeaconChain
    messages*: TableRef[BLSSig, AttestationSignedData] # Validator messages
    processed*: HashSet[BLSSig]                        # Keep track of processed messages
    scores*: TableRef[BlockHash, int]                  # Final score for each proposed block, it is the highest score it has at any slot
    scores_at_slot*: TableRef[SlotBlockHash, int]      # Score at each slot, if missing slot in slot_x < slot_missing < slot_y, use slot_x

# ############################################################
#
#           Hash table helpers for Fork Choice Stage 1
#
# ############################################################

func hash(x: BlockHash): Hash =
  ## Hash for Blake2 digests for Nim hash tables
  # We just slice the first 4 or 8 bytes of the block hash
  # depending of if we are on a 32 or 64-bit platform
  const size = 32 # sizeof(BlockHash)
  const num_hashes = size div sizeof(int)

  result = cast[array[num_hashes, Hash]](x)[0]

func hash(x: SlotBlockHash): Hash =
  ## Hash for (slot + Blake2 digests) for Nim hash tables
  result = hash(x.block_hash)
  result = result !& x.slot.int

func hash(x: BLSsig): Hash =
  ## Hash for BLS signature for Nim Hash sets
  const size = 48
  const num_hashes = size div sizeof(int)

  result = cast[array[num_hashes, Hash]](x.getRaw())[0]

# ############################################################
#
#                   Consensus State
#
# ############################################################

func resetConsensus(
        consensus: ConsensusState,
        beacon_chain: BeaconChain) =
  consensus.beacon_chain = beacon_chain
  consensus.messages.clear()
  consensus.processed.clear()
  consensus.scores.clear()
  consensus.scores_at_slot.clear()

func newConsensus(
        beacon_chain: BeaconChain): ConsensusState =
  new result
  result.beacon_chain = beacon_chain
  result.messages = newTable[BLSsig, AttestationSignedData]()
  init result.processed
  result.scores = newTable[BlockHash, int]()
  result.scores_at_slot = newTable[SlotBlockHash, int]()

# ############################################################
#
#           Auxiliary procs for block ancestry
#
# ############################################################

func direct_parent(blck: BeaconBlock): BlockHash =
  ## Ancestor_hashes is of type array[32, BlockHash]
  ## with ancestor_hashes[i] the most recent parent
  ## whose slot is a multiple of 2^i
  blck.ancestor_hashes[0]

  # TODO: what's the difference between
  #       BeaconBlock.ancestor_hashes[0] and
  #       BeaconBlock.state_root

func get_common_ancestor_slot(
      consensus: ConsensusState,
      hash_a, hash_b: BlockHash
    ): Slot =

  # Note: we don't use BeaconState.recent_block_hashes
  #       nor get_block_hash(BeaconState, BeaconBlock, Slot) -> Blake2_256_Digest
  #       as we will process candidate blocks that are not part of the main chain.

  var a = consensus.beacon_chain[hash_a]
  var b = consensus.beacon_chain[hash_b]

  while b.slot > a.slot:
    b = consensus.beacon_chain[b.direct_parent]
  while a.slot > b.slot:
    a = consensus.beacon_chain[a.direct_parent]
  while hashSSZ(a) != hashSSZ(b):
    a = consensus.beacon_chain[a.direct_parent]
    b = consensus.beacon_chain[b.direct_parent]
  result = a.slot

# ############################################################
#
#           Core processing for Fork Choice stage 1
#
# ############################################################

# We assume that block proposers are doing the fork choice rule.

func broadcast_new_block(consensus: ConsensusState, beacon_state: beacon_state) =
  ## Stub - Run by block proposer
  ##   - Reset the consensusState
  ##   - Broadcast the new beacon block
  discard

func on_receive_candidate_block(consensus: ConsensusState, beacon_state: beacon_state) =
  ## Stub - Run by validators once they received a block proposal
  discard

func on_receive_consensus_block(consensus: ConsensusState, beacon_state: beacon_state) =
  ## Stub - Run by everyone once a Proof-of-Stake consensus is broadcasted
  ## This isn't be needed by full clients as they can reconstruct
  ## the distributed consensus from the previous state + candidate block + attestations
  ##
  ## A light client, an "observer/monitor" or a logging framework can listen to thos eevent.
  discard

func on_receive_attestation*(
        consensus: ConsensusState,
        sig: BLSSig,
        attest_data: AttestationSignedData,
        reprocess = false
    ) =
  ## Prerequisites:
  ##    - During `block_processing`, the `aggregate_sig` verifies the `attest_data`
  ##      using the group public key
  ##    - The raw `attest_data` message has been deserialized (via SimpleSerialise SSZ)

  ## TODO: update `beacon_state.pending_attestations: seq[AttestationRecord]`

  # 1. remove duplicates
  if sig in consensus.processed and not reprocess:
    return

  # TODO: commit/rollback scheme to leave ConsensusState consistent
  #       in case of failure
  consensus.processed.incl sig





