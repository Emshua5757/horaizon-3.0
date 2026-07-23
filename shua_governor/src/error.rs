use thiserror::Error;

#[allow(dead_code)]
#[derive(Debug, Error)]
pub enum AppError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Config error: {0}")]
    Config(String),

    #[error("WebSocket error: {0}")]
    WebSocket(String),

    #[error("Serialization error: {0}")]
    Serialization(String),

    #[error("Module not found: {0}")]
    ModuleNotFound(String),

    #[error("Module asleep: {0}")]
    ModuleAsleep(String),

    #[error("Ollama error: {0}")]
    Ollama(String),

    #[error("Process error: {0}")]
    Process(String),
}

#[allow(dead_code)]
pub type Result<T> = std::result::Result<T, AppError>;
