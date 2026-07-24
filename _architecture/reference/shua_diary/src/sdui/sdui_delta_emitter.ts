import { Socket } from 'socket.io';
import { encode } from '@msgpack/msgpack';
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';

export type DeltaOp = 'insert' | 'remove' | 'patch';

interface DeltaInsert {
  op: 'insert';
  node: object;
  after_id: string | null;  // null = prepend at beginning
}

interface DeltaRemove {
  op: 'remove';
  node_id: string;
}

interface DeltaPatch {
  op: 'patch';
  node_id: string;
  behaviors?: Record<number, unknown>;
  content?: Record<number, unknown>;
}

export type DeltaEvent = DeltaInsert | DeltaRemove | DeltaPatch;

/**
 * SduiDeltaEmitter — pushes targeted AST mutations to a specific Flutter client.
 *
 * Flutter receives these on `patch_${screenId}` events and applies them
 * to the cached SduiNode tree without a full screen reload.
 *
 * Wire format: MsgPack-encoded DeltaEvent object.
 * Flutter-side handler: SduiTransport.applyDelta() (Phase 6 Flutter task).
 *
 * Design constraints:
 *  - All methods are static — no instance state, zero allocation overhead.
 *  - Encoding is lazy: only called when a socket client is actually present.
 *  - Event name `patch_${screenId}` mirrors `replace_${screenId}` convention.
 */
export class SduiDeltaEmitter {
  /**
   * Insert a new node after a specific sibling.
   * Used by: create_block → insert after the block the user clicked "+".
   *
   * @param socket    - The specific client socket to emit to
   * @param screenId  - e.g. "diary_editor_abc123"
   * @param node      - The fully assembled SDUI AST node to insert
   * @param afterId   - Sibling node ID to insert after. null = insert at start.
   */
  static emitInsert(socket: Socket, screenId: string, node: object, afterId: string | null): void {
    const delta: DeltaInsert = { op: 'insert', node, after_id: afterId };
    SduiDeltaEmitter._emit(socket, screenId, delta);
  }

  /**
   * Remove a node from the client tree.
   * Used by: delete_block → removes the block wrapper node by ID.
   */
  static emitRemove(socket: Socket, screenId: string, nodeId: string): void {
    const delta: DeltaRemove = { op: 'remove', node_id: nodeId };
    SduiDeltaEmitter._emit(socket, screenId, delta);
  }

  /**
   * Patch specific behavior or content keys on an existing node.
   * Used by: lock toggle → patch is_private flag on a card node.
   * Note: text content changes are NOT patched — they are handled by
   * SduiStateVault locally. Only server-authoritative state uses this.
   */
  static emitPatch(
    socket: Socket,
    screenId: string,
    nodeId: string,
    behaviors?: Record<number, unknown>,
    content?: Record<number, unknown>,
  ): void {
    const delta: DeltaPatch = { op: 'patch', node_id: nodeId };
    if (behaviors) delta.behaviors = behaviors;
    if (content) delta.content = content;
    SduiDeltaEmitter._emit(socket, screenId, delta);
  }

  private static _emit(socket: Socket, screenId: string, delta: DeltaEvent): void {
    if (!socket.connected) {
      logger.warn('sdui_delta_emitter', `Socket disconnected, dropping delta for '${screenId}': ${delta.op}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.NETWORK });
      return;
    }
    const bytes = encode(delta);
    socket.emit(`patch_${screenId}`, bytes);
  }
}
