pub mod client;
pub mod lifecycle;
pub mod model_registry;

#[allow(unused_imports)]
pub use client::{ChatMessage, OllamaClient};
pub use lifecycle::OllamaLifecycle;
pub use model_registry::{ModelRegistry, RegisteredModel};
