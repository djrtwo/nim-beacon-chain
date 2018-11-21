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

type
  BlockChain* = TableRef[Blake2_256_Digest, BeaconBlock]

  SlotBlockHash* = tuple[slot: uint64, block_hash: Blake2_256_Digest]

  ForkChoiceState* = object
    main_chain*: BlockChain
    messages*: TableRef[BLSSig, AttestationSignedData] # Validator messages
    processed*: HashSet[BLSSig]                        # Keep track of processed messages
    scores*: TableRef[Blake2_256_Digest, int]          # Final score for each proposed block, it is the highest score it has at any slot
    scores_at_slot*: TableRef[SlotBlockHash, int]      # Score at each slot, if missing slot in slot_x < slot_missing < slot_y, use slot_x


# HashTables helpers
func hash*(x: Blake2_256_Digest): Hash =
  ## Hash for Blake2 digests for Nim hash tables
  # We just slice the first 4 or 8 bytes of the block hash
  # depending of if we are on a 32 or 64-bit platform
  const size = sizeof(Blake2_256_Digest)
  const num_hashes = size div sizeof(int)

  result = cast[array[num_hashes, Hash]](x)[0]

func hash*(x: SlotBlockHash): Hash =
  ## Hash for (slot + Blake2 digests) for Nim hash tables
  const size = sizeof(SlotBlockHash)
  result = hash(x.block_hash)
  result = result !& x.slot.int
