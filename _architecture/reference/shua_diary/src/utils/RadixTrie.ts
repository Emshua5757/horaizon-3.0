export interface TrieEntry {
    blockId: string;
    entryId: string;
    matchedWord?: string;
}

export interface SearchMatchDetail {
    word: string;
    distance: number;
    blockId: string;
}

export class TrieNode {
    children: Map<string, TrieNode>;
    entries: TrieEntry[];

    constructor() {
        this.children = new Map();
        this.entries = [];
    }
}

export class RadixTrie {
    private root: TrieNode;

    constructor() {
        this.root = new TrieNode();
    }

    public insert(tag: string, blockId: string, entryId: string): void {
        this._insert(this.root, tag, blockId, entryId, tag);
    }

    private _insert(node: TrieNode, suffix: string, blockId: string, entryId: string, fullTag: string): void {
        if (suffix.length === 0) {
            node.entries.push({ blockId, entryId, matchedWord: fullTag });
            return;
        }

        for (const [key, child] of node.children.entries()) {
            // Find the longest common prefix between the edge 'key' and our 'suffix'
            let i = 0;
            while (i < key.length && i < suffix.length && key[i] === suffix[i]) {
                i++;
            }

            if (i > 0) {
                if (i === key.length) {
                    this._insert(child, suffix.slice(i), blockId, entryId, fullTag);
                } else {
                    node.children.delete(key);
                    const newChild = new TrieNode();
                    node.children.set(key.slice(0, i), newChild);
                    newChild.children.set(key.slice(i), child);
                    if (i < suffix.length) {
                        const newLeaf = new TrieNode();
                        newLeaf.entries.push({ blockId, entryId, matchedWord: fullTag });
                        newChild.children.set(suffix.slice(i), newLeaf);
                    } else {
                        newChild.entries.push({ blockId, entryId, matchedWord: fullTag });
                    }
                }
                return;
            }
        }

        const newNode = new TrieNode();
        newNode.entries.push({ blockId, entryId, matchedWord: fullTag });
        node.children.set(suffix, newNode);
    }

    /**
     * Remove all trie entries matching the given word (and optionally blockId/entryId).
     *
     * Traversal: recursive post-order descent so that compaction decisions are made
     * bottom-up — a child is never merged into its parent before we know it has no
     * remaining children of its own.
     *
     * Post-remove cleanup (per node, on the way back up):
     *   1. Pruning   — if a node has no entries AND no children, delete it from the
     *                  parent's children map entirely (dead leaf / dead branch removal).
     *   2. Compaction — if a node has no entries AND exactly ONE child, merge the lone
     *                  child's edge key into the parent's edge so the tree stays
     *                  compressed (prevents degeneration to a flat character-per-node trie).
     *
     * Complexity: O(k + d) where k = word length (traversal depth) and d = subtree nodes
     * pruned (worst case, a deleted leaf that happens to compress a long branch).
     *
     * @param word     The full word string that was originally inserted.
     * @param entryId  Required: filter entries by entryId.
     * @param blockId  Optional: additionally filter by blockId (remove a single block's entry).
     * @returns        true if at least one TrieEntry was removed.
     */
    public remove(word: string, entryId: string, blockId?: string): boolean {
        const result = this._remove(this.root, word, entryId, blockId);
        return result.removed;
    }

    private _remove(
        node: TrieNode,
        suffix: string,
        entryId: string,
        blockId: string | undefined,
    ): { removed: boolean; isEmpty: boolean } {
        const noOp = { removed: false, isEmpty: false };

        if (suffix.length === 0) {
            // We are at the terminal node. Strip matching entries.
            const before = node.entries.length;
            node.entries = node.entries.filter(e => {
                if (e.entryId !== entryId) return true;
                if (blockId !== undefined && e.blockId !== blockId) return true;
                return false; // drop this entry
            });
            const removed = node.entries.length < before;
            const isEmpty = removed && node.entries.length === 0 && node.children.size === 0;
            return { removed, isEmpty };
        }

        // Walk down the compressed edge that shares a prefix with our suffix
        for (const [key, child] of node.children.entries()) {
            let i = 0;
            while (i < key.length && i < suffix.length && key[i] === suffix[i]) {
                i++;
            }

            if (i === 0) continue; // No common prefix — try next edge

            if (i < key.length) {
                // Partial edge match — word is NOT in the trie (was never inserted exactly)
                return noOp;
            }

            // Full edge consumed — recurse into child with the remaining suffix
            const result = this._remove(child, suffix.slice(i), entryId, blockId);
            if (!result.removed) return noOp;

            // ── Post-remove cleanup (bottom-up) ────────────────────────────────
            if (result.isEmpty) {
                // 1. Pruning: child is now dead (no entries, no children) — delete it
                node.children.delete(key);
            } else if (child.entries.length === 0 && child.children.size === 1) {
                // 2. Compaction: child has no entries and exactly one grandchild —
                //    merge the grandchild's edge key with our edge key to restore
                //    compressed-trie invariant.
                node.children.delete(key);
                const [grandKey, grandChild] = child.children.entries().next().value as [string, TrieNode];
                node.children.set(key + grandKey, grandChild);
            }

            const isEmpty = node.entries.length === 0 && node.children.size === 0;
            return { removed: true, isEmpty };
        }

        // No edge matched the suffix at all — word not found
        return noOp;
    }

    public search(prefix: string, maxDistance: number = 2): string[] {
        const matches = this.searchWithMatches(prefix, maxDistance);
        return Object.keys(matches);
    }

    public searchWithMatches(prefix: string, maxDistance: number = 2): { [entryId: string]: SearchMatchDetail[] } {
        if (!prefix || prefix.trim() === '') return {};
        
        const resultSet = new Map<string, SearchMatchDetail[]>();
        // Base Levenshtein Row: [0, 1, 2, ..., prefix.length]
        const currentRow = Array.from({ length: prefix.length + 1 }, (_, i) => i);
        
        for (const [key, child] of this.root.children.entries()) {
            this._fuzzySearch(child, key, prefix, currentRow, maxDistance, resultSet);
        }
        
        const resultObj: { [entryId: string]: SearchMatchDetail[] } = {};
        for (const [entryId, matches] of resultSet.entries()) {
            resultObj[entryId] = matches;
        }
        return resultObj;
    }

    private _fuzzySearch(
        node: TrieNode, 
        edgeKey: string, 
        query: string, 
        previousRow: number[], 
        maxDistance: number, 
        resultSet: Map<string, SearchMatchDetail[]>
    ): void {
        // High-Precision Memory Swap Optimization:
        // Allocate only two static arrays locally for this edge traversal, preventing thousands
        // of micro-allocations within the character loop!
        let lastRow = [...previousRow];
        let nextRow = new Array<number>(query.length + 1);

        for (let charIdx = 0; charIdx < edgeKey.length; charIdx++) {
            const char = edgeKey[charIdx];
            nextRow[0] = lastRow[0] + 1;
            let minDistanceInRow = nextRow[0];

            for (let i = 1; i <= query.length; i++) {
                const insertCost = nextRow[i - 1] + 1;
                const deleteCost = lastRow[i] + 1;
                const replaceCost = lastRow[i - 1] + (query[i - 1] === char ? 0 : 1);
                
                const val = Math.min(insertCost, deleteCost, replaceCost);
                nextRow[i] = val;
                minDistanceInRow = Math.min(minDistanceInRow, val);
            }

            // Extreme Optimization: Perfect exact match check
            // If the edit distance is exactly 0, we can halt traversal and abort recursion instantly
            // since the distance cannot possibly minimize any further!
            if (nextRow[query.length] === 0) {
                this.collectAllBlockIds(node, resultSet, 0);
                return;
            }

            // If the prefix query has been fully matched at an intermediate point along the compressed edge,
            // we record this subtree match, but we continue the loop in case a closer match (with a smaller edit distance)
            // is found further along the edge.
            if (nextRow[query.length] <= maxDistance) {
                this.collectAllBlockIds(node, resultSet, nextRow[query.length]);
            }

            // Pruning: The mathematical beauty. If the minimum error across this row exceeds our max,
            // this branch is a dead end. We abort instantly, saving massive CPU cycles.
            if (minDistanceInRow > maxDistance) {
                return;
            }
            
            // Swap row buffers locally instead of allocating a new array
            const temp = lastRow;
            lastRow = nextRow;
            nextRow = temp;
        }

        // If the edit distance at the END of the query is within tolerance, we found a fuzzy prefix match!
        if (lastRow[query.length] <= maxDistance) {
            // Harvest this node and ALL its children instantly.
            this.collectAllBlockIds(node, resultSet, lastRow[query.length]);
            return;
        }

        // Still searching, dive deeper into the compressed tree
        for (const [childKey, childNode] of node.children.entries()) {
            this._fuzzySearch(childNode, childKey, query, lastRow, maxDistance, resultSet);
        }
    }

    private collectAllBlockIds(node: TrieNode, resultSet: Map<string, SearchMatchDetail[]>, distance: number): void {
        for (const entry of node.entries) {
            if (entry.matchedWord) {
                const list = resultSet.get(entry.entryId) || [];
                const existingIdx = list.findIndex(m => m.word === entry.matchedWord);
                if (existingIdx === -1) {
                    list.push({ word: entry.matchedWord, distance, blockId: entry.blockId });
                } else if (list[existingIdx].distance > distance) {
                    list[existingIdx].distance = distance;
                    list[existingIdx].blockId = entry.blockId;
                }
                resultSet.set(entry.entryId, list);
            }
        }
        for (const childNode of node.children.values()) {
            this.collectAllBlockIds(childNode, resultSet, distance);
        }
    }
}