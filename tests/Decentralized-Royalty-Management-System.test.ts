import { describe, it, expect, beforeEach } from "vitest";

// Mocking the royalty management system state and functions
const ERR_NOT_AUTHORIZED = "ERR_NOT_AUTHORIZED";
const ERR_NFT_NOT_FOUND = "ERR_NFT_NOT_FOUND";
const ERR_INVALID_PERCENTAGE = "ERR_INVALID_PERCENTAGE";

let royaltyMap: Map<any, any>;

const resetRoyaltyMap = () => {
  royaltyMap = new Map();
};

const registerNFT = (tokenId: number, baseRoyalty: number, sender: string) => {
  if (sender !== "CONTRACT_OWNER") return ERR_NOT_AUTHORIZED;
  if (baseRoyalty > 100) return ERR_INVALID_PERCENTAGE;

  royaltyMap.set(tokenId, {
    creator: sender,
    baseRoyalty,
    saleCount: 0,
    currentRoyalty: baseRoyalty,
  });
  return true;
};

const updateRoyalty = (tokenId: number) => {
  const nftData = royaltyMap.get(tokenId);
  if (!nftData) return ERR_NFT_NOT_FOUND;

  const newSaleCount = nftData.saleCount + 1;
  const adjustedRoyalty = calculateDynamicRoyalty(nftData.baseRoyalty, newSaleCount);

  royaltyMap.set(tokenId, {
    ...nftData,
    saleCount: newSaleCount,
    currentRoyalty: adjustedRoyalty,
  });
  return true;
};

const getNFTRoyalty = (tokenId: number) => royaltyMap.get(tokenId) || null;

const calculateDynamicRoyalty = (baseRoyalty: number, saleCount: number) => {
  const royaltyReduction = Math.floor((baseRoyalty * 5 * saleCount) / 100);
  return royaltyReduction > baseRoyalty ? 1 : baseRoyalty - royaltyReduction;
};

// Tests

describe("Royalty Management System", () => {
  beforeEach(() => {
    resetRoyaltyMap();
  });

  it("should allow the contract owner to register an NFT with valid royalty", () => {
    const result = registerNFT(1, 20, "CONTRACT_OWNER");
    const nft = getNFTRoyalty(1);

    expect(result).toBe(true);
    expect(nft).toBeDefined();
    expect(nft.creator).toBe("CONTRACT_OWNER");
    expect(nft.baseRoyalty).toBe(20);
    expect(nft.saleCount).toBe(0);
    expect(nft.currentRoyalty).toBe(20);
  });

  it("should reject NFT registration if sender is not the contract owner", () => {
    const result = registerNFT(2, 30, "NOT_OWNER");
    expect(result).toBe(ERR_NOT_AUTHORIZED);
  });

  it("should reject NFT registration with an invalid royalty percentage", () => {
    const result = registerNFT(3, 120, "CONTRACT_OWNER");
    expect(result).toBe(ERR_INVALID_PERCENTAGE);
  });

  it("should update the royalty correctly after a sale", () => {
    registerNFT(1, 20, "CONTRACT_OWNER");
    updateRoyalty(1);

    const nft = getNFTRoyalty(1);
    expect(nft.saleCount).toBe(1);
    expect(nft.currentRoyalty).toBe(19); // 20 - (20 * 5 * 1 / 100)
  });

  it("should handle multiple royalty updates for an NFT", () => {
    registerNFT(1, 30, "CONTRACT_OWNER");
    updateRoyalty(1);
    updateRoyalty(1);

    const nft = getNFTRoyalty(1);
    expect(nft.saleCount).toBe(2);
    expect(nft.currentRoyalty).toBe(27); // 30 - (30 * 5 * 2 / 100)
  });

  it("should reject royalty update for a non-existent NFT", () => {
    const result = updateRoyalty(999);
    expect(result).toBe(ERR_NFT_NOT_FOUND);
  });
});
