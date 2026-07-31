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
    keep_alive: serde_json::Value,
    #[serde(skip_serializing_if = "Option::is_none")]
    options: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    think: Option<serde_json::Value>,
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
    #[serde(default)]
    pub id: Option<String>,
    pub function: ToolCallFunction,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct ToolCallFunction {
    #[serde(default)]
    pub index: Option<usize>,
    pub name: String,
    #[serde(default = "default_serde_json_object")]
    pub arguments: serde_json::Value,
}

fn default_serde_json_object() -> serde_json::Value {
    serde_json::json!({})
}

#[derive(Deserialize)]
struct ChatResponse {
    message: ChatMessageResponse,
}

#[derive(Deserialize)]
pub struct ChatMessageResponse {
    #[allow(dead_code)]
    #[serde(default)]
    pub role: String,
    #[serde(default)]
    pub content: String,
    #[serde(default)]
    pub thinking: Option<String>,
    #[serde(default)]
    pub reasoning_content: Option<String>,
    #[serde(default)]
    pub tool_calls: Option<Vec<ToolCall>>,
}

pub fn strip_think_tags(text: &str) -> String {
    use once_cell::sync::Lazy;
    use regex::Regex;

    static RE_THINK: Lazy<Regex> = Lazy::new(|| {
        Regex::new(r"(?s)<think>.*?</think>").expect("valid regex")
    });
    RE_THINK.replace_all(text, "").trim().to_string()
}

impl ChatMessageResponse {
    pub fn effective_text(&self) -> String {
        let raw = if !self.content.trim().is_empty() {
            self.content.clone()
        } else if let Some(ref r) = self.reasoning_content {
            if !r.trim().is_empty() {
                r.clone()
            } else {
                self.content.clone()
            }
        } else if let Some(ref t) = self.thinking {
            t.clone()
        } else {
            self.content.clone()
        };
        strip_think_tags(&raw)
    }
}

impl OllamaClient {
    pub fn new(base_url: &str) -> Self {
        let http = Client::builder()
            .timeout(std::time::Duration::from_secs(120))
            .connect_timeout(std::time::Duration::from_secs(5))
            .build()
            .unwrap_or_else(|_| Client::new());

        Self {
            http,
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
            keep_alive: serde_json::json!(-1),
            options: None,
            think: None,
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
            keep_alive: serde_json::json!(0),
            options: None,
            think: None,
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
            keep_alive: serde_json::json!(keep_alive),
            options: Some(serde_json::json!({"num_ctx": 8192})),
            think: Some(serde_json::json!(true)),
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

    /// Send a chat prompt with tool schemas and stream NDJSON token deltas to on_delta callback live
    pub async fn chat_with_tools_stream<F>(
        &self,
        model: &str,
        messages: Vec<ChatMessage>,
        tools: Option<Vec<serde_json::Value>>,
        keep_alive: i32,
        mut on_delta: F,
    ) -> Result<ChatMessageResponse>
    where
        F: FnMut(&str),
    {
        let payload = ChatPayload {
            model: model.to_string(),
            messages,
            tools,
            stream: true,
            keep_alive: serde_json::json!(keep_alive),
            options: Some(serde_json::json!({"num_ctx": 8192})),
            think: Some(serde_json::json!(true)),
        };

        let mut res = self
            .http
            .post(format!("{}/api/chat", self.base_url))
            .json(&payload)
            .send()
            .await?
            .error_for_status()?;

        let mut accumulated_content = String::new();
        let mut accumulated_thinking = String::new();
        let mut accumulated_tool_calls: Option<Vec<ToolCall>> = None;
        let mut thinking: Option<String> = None;
        let mut reasoning_content: Option<String> = None;

        let mut buffer = Vec::new();
        while let Ok(Some(chunk)) = res.chunk().await {
            buffer.extend_from_slice(&chunk);

            while let Some(pos) = buffer.iter().position(|&b| b == b'\n') {
                let line_bytes: Vec<u8> = buffer.drain(..=pos).collect();
                let line = String::from_utf8_lossy(&line_bytes);
                let trimmed = line.trim();
                if trimmed.is_empty() {
                    continue;
                }

                if let Ok(resp) = serde_json::from_str::<ChatResponse>(trimmed) {
                    if !resp.message.content.is_empty() {
                        on_delta(&resp.message.content);
                        accumulated_content.push_str(&resp.message.content);
                    }
                    if let Some(ref t) = resp.message.thinking {
                        accumulated_thinking.push_str(t);
                        thinking = Some(accumulated_thinking.clone());
                    }
                    if let Some(ref r) = resp.message.reasoning_content {
                        accumulated_thinking.push_str(r);
                        reasoning_content = Some(accumulated_thinking.clone());
                    }
                    if let Some(tc) = resp.message.tool_calls {
                        accumulated_tool_calls = Some(tc);
                    }
                }
            }
        }

        let final_content = if accumulated_content.trim().is_empty() && !accumulated_thinking.trim().is_empty() {
            strip_think_tags(&accumulated_thinking)
        } else {
            strip_think_tags(&accumulated_content)
        };

        Ok(ChatMessageResponse {
            role: "assistant".to_string(),
            content: final_content,
            thinking,
            reasoning_content,
            tool_calls: accumulated_tool_calls,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_strip_think_tags() {
        let input = "Sure! <think>Let me calculate 2+2=4</think> The answer is 4.";
        assert_eq!(strip_think_tags(input), "Sure!  The answer is 4.");
    }

    #[test]
    fn test_effective_text_strips_inline_think_tags() {
        let msg = ChatMessageResponse {
            role: "assistant".to_string(),
            content: "<think>Internal thoughts</think>Final response".to_string(),
            thinking: None,
            reasoning_content: None,
            tool_calls: None,
        };
        assert_eq!(msg.effective_text(), "Final response");
    }
}

