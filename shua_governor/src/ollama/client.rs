use anyhow::Result;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use tracing::info;

pub struct OllamaClient {
    http: Client,
    base_url: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum KeepAlive {
    /// Keep model loaded indefinitely (-1)
    #[default]
    Forever,
    /// Unload model immediately after inference (0)
    Immediate,
    /// Keep model loaded for custom duration in seconds
    Seconds(i64),
}

impl KeepAlive {
    pub fn as_i64(&self) -> i64 {
        match self {
            KeepAlive::Forever => -1,
            KeepAlive::Immediate => 0,
            KeepAlive::Seconds(s) => *s,
        }
    }
}

impl From<i32> for KeepAlive {
    fn from(val: i32) -> Self {
        match val {
            -1 => KeepAlive::Forever,
            0 => KeepAlive::Immediate,
            s => KeepAlive::Seconds(s as i64),
        }
    }
}

impl From<i64> for KeepAlive {
    fn from(val: i64) -> Self {
        match val {
            -1 => KeepAlive::Forever,
            0 => KeepAlive::Immediate,
            s => KeepAlive::Seconds(s),
        }
    }
}

impl Serialize for KeepAlive {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_i64(self.as_i64())
    }
}

impl<'de> Deserialize<'de> for KeepAlive {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        struct KeepAliveVisitor;

        impl<'de> serde::de::Visitor<'de> for KeepAliveVisitor {
            type Value = KeepAlive;

            fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
                formatter.write_str("an integer or string representing keep_alive seconds (-1, 0, or positive duration)")
            }

            fn visit_i64<E>(self, v: i64) -> Result<KeepAlive, E>
            where
                E: serde::de::Error,
            {
                Ok(KeepAlive::from(v))
            }

            fn visit_u64<E>(self, v: u64) -> Result<KeepAlive, E>
            where
                E: serde::de::Error,
            {
                Ok(KeepAlive::from(v as i64))
            }

            fn visit_str<E>(self, v: &str) -> Result<KeepAlive, E>
            where
                E: serde::de::Error,
            {
                if v == "-1" || v.eq_ignore_ascii_case("forever") {
                    Ok(KeepAlive::Forever)
                } else if v == "0" || v.eq_ignore_ascii_case("immediate") {
                    Ok(KeepAlive::Immediate)
                } else {
                    v.parse::<i64>().map(KeepAlive::from).map_err(E::custom)
                }
            }
        }

        deserializer.deserialize_any(KeepAliveVisitor)
    }
}

#[derive(Serialize)]
struct ChatPayload {
    model: String,
    messages: Vec<ChatMessage>,
    #[serde(skip_serializing_if = "Option::is_none")]
    tools: Option<Vec<serde_json::Value>>,
    stream: bool,
    keep_alive: KeepAlive,
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

/// Utility function to strip <think>...</think> reasoning tags from LLM responses
pub fn strip_think_tags(text: &str) -> String {
    use once_cell::sync::Lazy;
    use regex::Regex;

    static RE_THINK: Lazy<Regex> =
        Lazy::new(|| Regex::new(r"(?s)<think>.*?</think>").expect("valid regex"));
    RE_THINK.replace_all(text, "").trim().to_string()
}

impl ChatMessageResponse {
    pub fn effective_text(&self) -> String {
        let raw = if !self.content.trim().is_empty() {
            self.content.as_str()
        } else if let Some(r) = self
            .reasoning_content
            .as_deref()
            .filter(|s| !s.trim().is_empty())
        {
            r
        } else if let Some(t) = self.thinking.as_deref().filter(|s| !s.trim().is_empty()) {
            t
        } else {
            self.content.as_str()
        };
        strip_think_tags(raw)
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

    /// Load a model into RAM by sending a no-op chat (keep_alive = Forever keeps it alive)
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
            keep_alive: KeepAlive::Forever,
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

    /// Evict a model from RAM immediately (keep_alive = Immediate)
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
            keep_alive: KeepAlive::Immediate,
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
    pub async fn chat(
        &self,
        model: &str,
        messages: Vec<ChatMessage>,
        keep_alive: KeepAlive,
    ) -> Result<String> {
        let resp = self
            .chat_with_tools(model, messages, None, keep_alive)
            .await?;
        Ok(resp.content)
    }

    /// Send a chat prompt with tool schemas and return full ChatMessageResponse
    pub async fn chat_with_tools(
        &self,
        model: &str,
        messages: Vec<ChatMessage>,
        tools: Option<Vec<serde_json::Value>>,
        keep_alive: KeepAlive,
    ) -> Result<ChatMessageResponse> {
        let payload = ChatPayload {
            model: model.to_string(),
            messages,
            tools,
            stream: false,
            keep_alive,
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
        keep_alive: KeepAlive,
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
            keep_alive,
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
        let mut in_thinking_stream = false;

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
                    // Stream thinking / reasoning tokens live wrapped in <think> tags
                    let think_delta = resp
                        .message
                        .thinking
                        .as_deref()
                        .or(resp.message.reasoning_content.as_deref());
                    if let Some(t_delta) = think_delta {
                        if !t_delta.is_empty() {
                            if !in_thinking_stream {
                                in_thinking_stream = true;
                                on_delta("<think>\n");
                            }
                            on_delta(t_delta);
                            accumulated_thinking.push_str(t_delta);
                        }
                    }

                    // Stream standard content tokens live
                    if !resp.message.content.is_empty() {
                        if in_thinking_stream {
                            in_thinking_stream = false;
                            on_delta("\n</think>\n");
                        }
                        on_delta(&resp.message.content);
                        accumulated_content.push_str(&resp.message.content);
                    }

                    if let Some(tc) = resp.message.tool_calls {
                        accumulated_tool_calls = Some(tc);
                    }
                }
            }
        }

        if in_thinking_stream {
            on_delta("\n</think>\n");
        }

        let thinking = if !accumulated_thinking.trim().is_empty() {
            Some(accumulated_thinking.clone())
        } else {
            None
        };

        let final_content = if accumulated_content.trim().is_empty() && thinking.is_some() {
            strip_think_tags(thinking.as_deref().unwrap_or_default())
        } else {
            strip_think_tags(&accumulated_content)
        };

        Ok(ChatMessageResponse {
            role: "assistant".to_string(),
            content: final_content,
            thinking: thinking.clone(),
            reasoning_content: thinking,
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

    #[test]
    fn test_effective_text_fallback_with_empty_reasoning_content() {
        let msg = ChatMessageResponse {
            role: "assistant".to_string(),
            content: "".to_string(),
            reasoning_content: Some("".to_string()),
            thinking: Some("real text".to_string()),
            tool_calls: None,
        };
        assert_eq!(msg.effective_text(), "real text");
    }

    #[test]
    fn test_keep_alive_serde() {
        let ka_forever = KeepAlive::Forever;
        let serialized = serde_json::to_string(&ka_forever).unwrap();
        assert_eq!(serialized, "-1");
        let deserialized: KeepAlive = serde_json::from_str("-1").unwrap();
        assert_eq!(deserialized, KeepAlive::Forever);

        let ka_imm = KeepAlive::Immediate;
        let serialized = serde_json::to_string(&ka_imm).unwrap();
        assert_eq!(serialized, "0");
        let deserialized: KeepAlive = serde_json::from_str("0").unwrap();
        assert_eq!(deserialized, KeepAlive::Immediate);

        let ka_sec = KeepAlive::Seconds(300);
        let serialized = serde_json::to_string(&ka_sec).unwrap();
        assert_eq!(serialized, "300");
        let deserialized: KeepAlive = serde_json::from_str("300").unwrap();
        assert_eq!(deserialized, KeepAlive::Seconds(300));
    }
}
