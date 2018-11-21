# beacon_chain
# Copyright (c) 2018 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import ../datatypes, tables, hashes, sets

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
  BlockChain* = TableRef[BlockHash, BeaconBlock]
  Slot* = uint64

  SlotBlockHash* = tuple[slot: Slot, block_hash: BlockHash]

  ForkChoiceState* = ref object
    main_chain*: BlockChain
    messages*: TableRef[BLSSig, AttestationSignedData] # Validator messages
    processed*: HashSet[BLSSig]                        # Keep track of processed messages
    scores*: TableRef[BlockHash, int]                  # Final score for each proposed block, it is the highest score it has at any slot
    scores_at_slot*: TableRef[SlotBlockHash, int]      # Score at each slot, if missing slot in slot_x < slot_missing < slot_y, use slot_x

# ############################################################
#
#           Hash table helpers for Fork Choice Stage 1
#
# ############################################################

func hash*(x: BlockHash): Hash =
  ## Hash for Blake2 digests for Nim hash tables
  # We just slice the first 4 or 8 bytes of the block hash
  # depending of if we are on a 32 or 64-bit platform
  const size = sizeof(BlockHash)
  const num_hashes = size div sizeof(int)

  result = cast[array[num_hashes, Hash]](x)[0]

func hash*(x: SlotBlockHash): Hash =
  ## Hash for (slot + Blake2 digests) for Nim hash tables
  const size = sizeof(SlotBlockHash)
  result = hash(x.block_hash)
  result = result !& x.slot.int

# ############################################################
#
#           Auxiliary procs for block ancestry
#
# ############################################################

func get_common_ancestor_slot()
      fk_choice: ForkChoiceState,
      a, b: BlockHash
    ): Slot =
  

# ############################################################
#
#           Core processing for Fork Choice stage 1
#
# ############################################################

func on_receive_attestation*(
        fk_choice: ForkChoiceState,
        attest_data: AttestationSignedData
    ) =
  ## Prerequisites:
  ##    - During `block_processing`, the `aggregate_sig` verifies the `attest_data`
  ##      using the group public key
  ##    - The raw `attest_data` message has been deserialized (via SimpleSerialise SSZ)

