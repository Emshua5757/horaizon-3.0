use anyhow::Result;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use tracing::info;

pub struct OllamaClient {
    http: Client,
    base_url: String,
}

#[derive(Serialize)]
struct ChatPayload {
    model: String,
    messages: Vec<ChatMessage>,
    #[serde(skip_serializing_if = "Option::is_none")]
    tools: Option<Vec<serde_json::Value>>,
    stream: bool,
    keep_alive: String,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct ChatMessage {
    pub role: String,
    pub content: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tool_calls: Option<Vec<ToolCall>>,
}

impl ChatMessage {
    pub fn user(content: impl Into<String>) -> Self {
        Self {
            role: "user".into(),
            content: content.into(),
            tool_calls: None,
        }
    }

    pub fn system(content: impl Into<String>) -> Self {
        Self {
            role: "system".into(),
            content: content.into(),
            tool_calls: None,
        }
    }

    pub fn tool(content: impl Into<String>) -> Self {
        Self {
            role: "tool".into(),
            content: content.into(),
            tool_calls: None,
        }
    }
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct ToolCall {
    pub function: ToolCallFunction,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct ToolCallFunction {
    pub name: String,
    pub arguments: serde_json::Value,
}

#[derive(Deserialize)]
struct ChatResponse {
    message: ChatMessageResponse,
}

#[derive(Deserialize)]
pub struct ChatMessageResponse {
    #[allow(dead_code)]
    pub role: String,
    pub content: String,
    pub tool_calls: Option<Vec<ToolCall>>,
}

impl OllamaClient {
    pub fn new(base_url: &str) -> Self {
        Self {
            http: Client::new(),
            base_url: base_url.to_string(),
        }
    }

    pub fn base_url(&self) -> &str {
        &self.base_url
    }

    /// Load a model into RAM by sending a no-op chat (keep_alive = -1 keeps it alive)
    pub async fn load_model(&self, model: &str) -> Result<()> {
        let payload = ChatPayload {
            model: model.to_string(),
            messages: vec![ChatMessage {
                role: "user".into(),
                content: "hi".into(),
                tool_calls: None,
            }],
            tools: None,
            stream: false,
            keep_alive: "-1".to_string(),
        };

        self.http
            .post(format!("{}/api/chat", self.base_url))
            .json(&payload)
            .send()
            .await?
            .error_for_status()?;

        info!(
            subsystem = "ollama_client",
            base_url = %self.base_url,
            model = model,
            "Model loaded into Ollama RAM"
        );
        Ok(())
    }

    /// Evict a model from RAM immediately
    pub async fn evict_model(&self, model: &str) -> Result<()> {
        let payload = ChatPayload {
            model: model.to_string(),
            messages: vec![ChatMessage {
                role: "user".into(),
                content: "bye".into(),
                tool_calls: None,
            }],
            tools: None,
            stream: false,
            keep_alive: "0".to_string(),
        };

        self.http
            .post(format!("{}/api/chat", self.base_url))
            .json(&payload)
            .send()
            .await?
            .error_for_status()?;

        info!(
            subsystem = "ollama_client",
            base_url = %self.base_url,
            model = model,
            "Model evicted from Ollama RAM"
        );
        Ok(())
    }

    /// Send a chat prompt and return the response string
    #[allow(dead_code)]
    pub async fn chat(&self, model: &str, messages: Vec<ChatMessage>, keep_alive: i32) -> Result<String> {
        let resp = self.chat_with_tools(model, messages, None, keep_alive).await?;
        Ok(resp.content)
    }

    /// Send a chat prompt with tool schemas and return full ChatMessageResponse
    pub async fn chat_with_tools(
        &self,
        model: &str,
        messages: Vec<ChatMessage>,
        tools: Option<Vec<serde_json::Value>>,
        keep_alive: i32,
    ) -> Result<ChatMessageResponse> {
        let payload = ChatPayload {
            model: model.to_string(),
            messages,
            tools,
            stream: false,
            keep_alive: keep_alive.to_string(),
        };

        let resp: ChatResponse = self
            .http
            .post(format!("{}/api/chat", self.base_url))
            .json(&payload)
            .send()
            .await?
            .error_for_status()?
            .json()
            .await?;

        Ok(resp.message)
    }
}
