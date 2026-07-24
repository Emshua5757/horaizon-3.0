import { SduiBlueprintLoader } from './sdui_blueprint_loader';

export type HydrationContext = Record<string, any>;

export class SduiNodeBuilder {
  
  /**
   * Loads a blueprint by moduleName, finds the specific screenKey within it,
   * and hydrates it with the provided context.
   */
  static buildScreen(moduleName: string, screenKey: string, context: HydrationContext): any {
    const blueprint = SduiBlueprintLoader.loadBlueprint(moduleName);
    
    const screenTemplate = blueprint[screenKey];
    if (!screenTemplate) {
      throw new Error(`[SduiNodeBuilder] Screen key '${screenKey}' not found in module '${moduleName}'`);
    }

    // We clone and hydrate the AST
    return this.hydrateNode(screenTemplate, context);
  }

  /**
   * Recursively traverses the node tree, replacing string bindings and expanding iterators.
   */
  static hydrateNode(node: any, context: HydrationContext): any {
    if (node === null || node === undefined) return node;

    // Handle primitives and strings (where the actual {{}} replacement happens)
    if (typeof node === 'string') {
      return this.hydrateString(node, context);
    }
    
    // Arrays: map over each element
    if (Array.isArray(node)) {
      return node.map(child => this.hydrateNode(child, context));
    }

    // Objects: recursive copy
    if (typeof node === 'object') {
      const hydratedNode: any = {};
      
      for (const [key, value] of Object.entries(node)) {
        // Special case: Iterator nodes (nested inside content block 4 under data key 6)
        if (
          key === '4' &&
          value &&
          typeof value === 'object' &&
          '6' in value &&
          typeof (value as any)['6'] === 'object' &&
          'iterator' in (value as any)['6']
        ) {
          // This node wants to spawn a list of children based on an array in the context
          const iteratorKey = String((value as any)['6']['iterator']);
          const collection = context[iteratorKey];
          
          // Spec constraint: Do not expand the children on the backend!
          // We serialize the data and send it down in Content Key 6.
          hydratedNode['4'] = {
            '6': JSON.stringify(collection || [])
          };
          
          if (node['template']) {
             // The Flutter client expects the template as the FIRST and ONLY child.
             hydratedNode['2'] = [node['template']];
          }
          
          continue;
        }

        // We skip the 'template' key itself from the final output payload
        if (key === 'template') continue;

        hydratedNode[key] = this.hydrateNode(value, context);
      }
      
      return hydratedNode;
    }

    return node;
  }

  /**
   * Replaces exact matches of "{{key}}" with the actual value from context (preserving types like numbers/booleans).
   * Also handles string interpolation like "Hello {{name}}".
   */
  private static hydrateString(str: string, context: HydrationContext): any {
    const exactMatch = /^\{\{([^}]+)\}\}$/.exec(str);
    if (exactMatch) {
      const key = exactMatch[1];
      return context[key] !== undefined ? context[key] : null;
    }

    // Replace inline variables (always results in a string)
    return str.replace(/\{\{([^}]+)\}\}/g, (match, key) => {
      return context[key] !== undefined ? String(context[key]) : '';
    });
  }
}
