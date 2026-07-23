// shua_governor — SDUI-4 Node AST Primitive & Custom Integer-Keyed Serializer
// Architecture spec: _architecture/sdui4/schema-sdui4.md

use serde::ser::{Serialize, SerializeMap, Serializer};
use serde_json::Value;
use std::collections::HashMap;

/// The /// central AST primitive for SDUI-4 rendering.
///
/// Emits integer-keyed maps over MessagePack/JSON for zero-overhead client parsing.
#[derive(Debug, Clone, PartialEq)]
pub struct SduiNode {
    pub node_type: i32,                // Wire Key 0
    pub id: String,                    // Wire Key 1
    pub children: Vec<SduiNode>,       // Wire Key 2
    pub behavior: HashMap<i32, Value>, // Wire Key 3
    pub content: HashMap<i32, Value>,  // Wire Key 4
    pub visible: bool,                 // Wire Key 5
    pub enabled: bool,                 // Wire Key 6
}

impl SduiNode {
    /// Creates a new SduiNode with sane defaults (visible=true, enabled=true, empty children/maps).
    pub fn new(node_type: i32) -> Self {
        Self {
            node_type,
            id: uuid::Uuid::new_v4().to_string(),
            children: Vec::new(),
            behavior: HashMap::new(),
            content: HashMap::new(),
            visible: true,
            enabled: true,
        }
    }

    /// Builder pattern helper for adding behavior properties.
    pub fn with_behavior(mut self, key: i32, val: impl Into<Value>) -> Self {
        self.behavior.insert(key, val.into());
        self
    }

    /// Builder pattern helper for adding content properties.
    pub fn with_content(mut self, key: i32, val: impl Into<Value>) -> Self {
        self.content.insert(key, val.into());
        self
    }

    /// Builder pattern helper for adding a child node.
    pub fn with_child(mut self, child: SduiNode) -> Self {
        self.children.push(child);
        self
    }
}

/// Custom Serde Serialize implementation emitting integer keys (0–6) instead of named fields.
impl Serialize for SduiNode {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        // Calculate dynamic map length so serializer allocates exact memory buffer
        let mut map_len = 3; // node_type(0), id(1), children(2) always serialized
        if !self.behavior.is_empty() {
            map_len += 1;
        }
        if !self.content.is_empty() {
            map_len += 1;
        }
        if !self.visible {
            map_len += 1;
        }
        if !self.enabled {
            map_len += 1;
        }

        let mut map = serializer.serialize_map(Some(map_len))?;

        map.serialize_entry(&0, &self.node_type)?;
        map.serialize_entry(&1, &self.id)?;
        map.serialize_entry(&2, &self.children)?;

        if !self.behavior.is_empty() {
            map.serialize_entry(&3, &self.behavior)?;
        }
        if !self.content.is_empty() {
            map.serialize_entry(&4, &self.content)?;
        }
        if !self.visible {
            map.serialize_entry(&5, &self.visible)?;
        }
        if !self.enabled {
            map.serialize_entry(&6, &self.enabled)?;
        }

        map.end()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sdui_node_construction() {
        let node = SduiNode::new(1);
        assert_eq!(node.node_type, 1);
        assert!(!node.id.is_empty());
    }

    #[test]
    fn test_sdui_node_builders() {
        let child = SduiNode::new(2);
        let node = SduiNode::new(1)
            .with_behavior(10, "sweeper")
            .with_content(20, 155.0)
            .with_child(child);

        assert_eq!(node.node_type, 1);
        assert_eq!(node.behavior.get(&10).unwrap(), "sweeper");
        assert_eq!(node.content.get(&20).unwrap(), 155.0);
        assert_eq!(node.children.len(), 1);
        assert_eq!(node.children[0].node_type, 2);
    }
}
