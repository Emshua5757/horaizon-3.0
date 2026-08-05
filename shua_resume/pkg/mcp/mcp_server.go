// Package mcp manages the WebSocket IPC connection to the Governor (port 7701)
// and handles MCP tool call dispatch.
package mcp

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/vmihailenco/msgpack/v5"

	"shua_resume/pkg/ai"
	"shua_resume/pkg/logger"
	"shua_resume/pkg/models"
	"shua_resume/pkg/repository"
)

const (
	governorIPC = "ws://127.0.0.1:7701"
	moduleID    = "shua.resume"
	version     = "3.0.0"
	scope       = "resume"
)

// Server manages the IPC connection to the Governor.
type Server struct {
	mu      sync.Mutex
	conn    *websocket.Conn
	pending map[string]chan string // request_id -> reply channel
	// OnHBPFrame is called for incoming HBP frames forwarded from dispatcher.
	// Set by mcp_server.go after construction.
	OnHBPFrame func(raw []byte)
}

// New creates a disconnected Server. Call Connect() to establish the IPC link.
func New() *Server {
	return &Server{
		pending: make(map[string]chan string),
	}
}

// Connect dials the Governor IPC endpoint and registers the MCP manifest.
// Retries on failure with exponential backoff (max 30s).
func (s *Server) Connect() {
	backoff := time.Second
	for {
		if err := s.connect(); err != nil {
			logger.Warn("mcp_server", "IPC connect failed — retrying", map[string]interface{}{
				"backoff_s": backoff.Seconds(),
				"error":     err.Error(),
			})
			time.Sleep(backoff)
			if backoff < 30*time.Second {
				backoff *= 2
			}
			continue
		}
		logger.Info("mcp_server", "Connected to Governor IPC and registered MCP tools", nil)
		backoff = time.Second

		// Read loop — blocks until disconnected
		s.readLoop()

		logger.Warn("mcp_server", "IPC connection lost — reconnecting", nil)
		time.Sleep(2 * time.Second)
	}
}

func (s *Server) connect() error {
	conn, _, err := websocket.DefaultDialer.Dial(governorIPC, nil)
	if err != nil {
		return fmt.Errorf("dial %s: %w", governorIPC, err)
	}

	manifest := map[string]interface{}{
		"op":        "governor.mcp.register",
		"module_id": moduleID,
		"version":   version,
		"scope":     scope,
		"tools": []map[string]interface{}{
			{
				"name":        "resume_tailor_jaccard",
				"description": "Filters the active resume matrix against a job description using Jaccard token similarity. Returns a filtered ResumeMatrix with match score.",
				"scope":       scope,
				"timeout_s":   15,
				"input_schema": map[string]interface{}{
					"type": "object",
					"properties": map[string]interface{}{
						"job_desc":  map[string]string{"type": "string"},
						"threshold": map[string]interface{}{"type": "number", "description": "Minimum Jaccard score (0.0-1.0, default 0.15)"},
					},
					"required": []string{"job_desc"},
				},
			},
			{
				"name":        "resume_compile_pdf",
				"description": "Compiles the active resume matrix into a Typst PDF. Returns exhibit_id and vault URL for the PDF on Pi 5.",
				"scope":       scope,
				"timeout_s":   60,
				"input_schema": map[string]interface{}{
					"type": "object",
					"properties": map[string]interface{}{
						"template":   map[string]interface{}{"type": "string", "enum": []string{"default", "modern", "minimalist"}},
						"job_desc":   map[string]string{"type": "string"},
						"tailor":     map[string]string{"type": "boolean"},
						"ai_enhance": map[string]string{"type": "boolean"},
					},
					"required": []string{"template"},
				},
			},
		},
	}

	b, err := json.Marshal(manifest)
	if err != nil {
		conn.Close()
		return fmt.Errorf("marshal manifest: %w", err)
	}
	if err := conn.WriteMessage(websocket.TextMessage, b); err != nil {
		conn.Close()
		return fmt.Errorf("send manifest: %w", err)
	}

	s.mu.Lock()
	s.conn = conn
	s.mu.Unlock()
	return nil
}

func (s *Server) readLoop() {
	s.mu.Lock()
	conn := s.conn
	s.mu.Unlock()
	if conn == nil {
		return
	}

	for {
		_, msg, err := conn.ReadMessage()
		if err != nil {
			logger.Warn("mcp_server", "IPC read error", map[string]interface{}{"error": err.Error()})
			return
		}

		// 1. Try JSON unmarshal first
		var frame map[string]interface{}
		if err := json.Unmarshal(msg, &frame); err == nil {
			id, _ := frame["id"].(string)
			if id != "" {
				s.mu.Lock()
				ch, ok := s.pending[id]
				s.mu.Unlock()
				if ok {
					var reply string

					// --- FIX: Catch Governor Error Frames ---
					if errObj, hasErr := frame["err"]; hasErr && errObj != nil {
						b, _ := json.Marshal(errObj)
						reply = fmt.Sprintf(`{"error": %s}`, string(b))
					} else if r, ok := frame["reply"].(string); ok && r != "" {
						reply = r
					} else if r, ok := frame["result"]; ok {
						b, _ := json.Marshal(r)
						reply = string(b)
					} else if pStr, ok := frame["p"].(string); ok && pStr != "" {
						if decoded, err := base64.StdEncoding.DecodeString(pStr); err == nil {
							var payload map[string]interface{}
							if err := msgpack.Unmarshal(decoded, &payload); err == nil {
								if r, ok := payload["reply"].(string); ok {
									reply = r
								} else {
									b, _ := json.Marshal(payload)
									reply = string(b)
								}
							} else {
								reply = string(decoded)
							}
						} else {
							reply = pStr
						}
					}

					ch <- reply
					s.mu.Lock()
					delete(s.pending, id)
					s.mu.Unlock()
					continue
				}
			}

			op, _ := frame["op"].(string)
			if op == "mcp.tool.call" || op == "tool_call" {
				s.handleToolCall(frame)
				continue
			}

			if s.OnHBPFrame != nil {
				s.OnHBPFrame(msg)
			}
			continue
		}

		// Unhandled binary fallback...
		if s.OnHBPFrame != nil {
			s.OnHBPFrame(msg)
		}
	}
}

// Strictly typed struct to ensure perfect MsgPack mapping for the Governor
type AiRouteRequest struct {
	Prompt           string `msgpack:"prompt"`
	ContextHint      string `msgpack:"context_hint,omitempty"`
	OffloadDeviceUrl string `msgpack:"offload_device_url,omitempty"`
	Model            string `msgpack:"model,omitempty"`
	SessionId        string `msgpack:"session_id,omitempty"`
}

func (s *Server) SendAIRoute(op string, payload map[string]interface{}) (string, error) {
	fmt.Println("🚨🚨🚨 SEND_AI_ROUTE CALLED DIRECTLY! op =", op)
	id := uuid.New().String()

	var prompt string
	if val, ok := payload["prompt"]; ok {
		if pStr, ok := val.(string); ok {
			prompt = pStr
		}
	}
	if prompt == "" {
		prompt = "SYSTEM: You are a JSON transformation engine. Return ONLY valid JSON matching the exact ResumeMatrix schema."
	}

	// Build a flat request structure so Rust's AiRouteRequest can decode it directly
	frame := map[string]interface{}{
		"v":      2,
		"t":      1,
		"op":     op,
		"id":     id,
		"mod":    "shua.governor",
		"prompt": prompt,
	}

	if hint, ok := payload["context_hint"].(string); ok && hint != "" {
		frame["context_hint"] = hint
	}
	if model, ok := payload["model"].(string); ok && model != "" {
		frame["model"] = model
	}
	if offload, ok := payload["offload_device_url"].(string); ok && offload != "" {
		frame["offload_device_url"] = offload
	}
	if sid, ok := payload["session_id"].(string); ok && sid != "" {
		frame["session_id"] = sid
	}

	ch := make(chan string, 1)
	s.mu.Lock()
	s.pending[id] = ch
	conn := s.conn
	s.mu.Unlock()

	if conn == nil {
		s.mu.Lock()
		delete(s.pending, id)
		s.mu.Unlock()
		return "", fmt.Errorf("IPC not connected")
	}

	b, _ := json.Marshal(frame)
	if err := conn.WriteMessage(websocket.TextMessage, b); err != nil {
		s.mu.Lock()
		delete(s.pending, id)
		s.mu.Unlock()
		return "", fmt.Errorf("send ai.route: %w", err)
	}

	select {
	case reply := <-ch:
		return reply, nil
	case <-time.After(600 * time.Second):
		s.mu.Lock()
		delete(s.pending, id)
		s.mu.Unlock()
		return "", fmt.Errorf("governor.ai.route timeout")
	}
}

func (s *Server) handleToolCall(frame map[string]interface{}) {
	callID, _ := frame["id"].(string)
	toolName, _ := frame["tool_name"].(string)
	params, _ := frame["params"].(map[string]interface{})
	if params == nil {
		params = make(map[string]interface{})
	}

	logger.Info("mcp_server", "MCP tool call received", map[string]interface{}{
		"tool": toolName, "call_id": callID,
	})

	var result interface{}
	var toolErr string

	switch toolName {
	case "resume_tailor_jaccard":
		matrix, err := repository.GetMatrix("shua")
		if err != nil {
			toolErr = fmt.Sprintf("get matrix: %v", err)
			break
		}
		jobDesc, _ := params["job_desc"].(string)
		threshold := 0.15
		if t, ok := params["threshold"].(float64); ok {
			threshold = t
		}
		cfg := ai.DefaultTailorConfig()
		cfg.MinScore = threshold
		filtered, score := ai.FilterResume(matrix, jobDesc, cfg)
		result = map[string]interface{}{
			"matrix":       filtered,
			"tailor_score": score,
		}

	default:
		toolErr = fmt.Sprintf("unknown tool: %s", toolName)
	}

	response := map[string]interface{}{
		"id":     callID,
		"status": "ok",
		"result": result,
	}
	if toolErr != "" {
		response["status"] = "error"
		response["error"] = toolErr
	}

	b, _ := json.Marshal(response)
	s.mu.Lock()
	conn := s.conn
	s.mu.Unlock()
	if conn != nil {
		if err := conn.WriteMessage(websocket.TextMessage, b); err != nil {
			logger.Error("mcp_server", "failed to send tool call response", err, map[string]interface{}{"call_id": callID})
		}
	}
}

// SendHBPReply writes a raw HBP response frame (already JSON-encoded by
// hbp.Handle via encodeOK/encodeError) back over the IPC WebSocket to
// Governor, which routes it back to the client that made the request.
func (s *Server) SendHBPReply(raw []byte) error {
	s.mu.Lock()
	conn := s.conn
	s.mu.Unlock()
	if conn == nil {
		return fmt.Errorf("IPC not connected")
	}
	return conn.WriteMessage(websocket.TextMessage, raw)
}

// SendVaultUpload sends a vault.upload IPC frame and waits for the Governor's response.
// Returns sha256_hash and vault_url.
func (s *Server) SendVaultUpload(module, fileName, mimeType, dataBase64 string) (string, string, error) {
	id := uuid.New().String()
	frame := map[string]interface{}{
		"op":          "vault.upload",
		"id":          id,
		"module":      module,
		"file_name":   fileName,
		"mime_type":   mimeType,
		"data_base64": dataBase64,
	}

	ch := make(chan string, 1)
	s.mu.Lock()
	s.pending[id] = ch
	conn := s.conn
	s.mu.Unlock()

	if conn == nil {
		s.mu.Lock()
		delete(s.pending, id)
		s.mu.Unlock()
		return "", "", fmt.Errorf("IPC not connected")
	}

	b, _ := json.Marshal(frame)
	if err := conn.WriteMessage(websocket.TextMessage, b); err != nil {
		s.mu.Lock()
		delete(s.pending, id)
		s.mu.Unlock()
		return "", "", fmt.Errorf("send vault.upload: %w", err)
	}

	select {
	case reply := <-ch:
		var resp map[string]interface{}
		if err := json.Unmarshal([]byte(reply), &resp); err != nil {
			// Might already be parsed as the result map
			_ = err
		}
		// Try result field first, then top-level
		if result, ok := resp["result"].(map[string]interface{}); ok {
			sha256, _ := result["sha256_hash"].(string)
			url, _ := result["url"].(string)
			return sha256, url, nil
		}
		sha256, _ := resp["sha256_hash"].(string)
		url, _ := resp["url"].(string)
		return sha256, url, nil
	case <-time.After(15 * time.Second):
		s.mu.Lock()
		delete(s.pending, id)
		s.mu.Unlock()
		return "", "", fmt.Errorf("vault.upload IPC timeout")
	}
}

// TemplateInfo describes an available Typst template.
type TemplateInfo struct {
	Id          string `json:"id" msgpack:"id"`
	Name        string `json:"name" msgpack:"name"`
	Description string `json:"description" msgpack:"description"`
}

// AvailableTemplates is the static template list.
var AvailableTemplates = []TemplateInfo{
	{"default", "Default", "Clean ATS-friendly single-column layout"},
	{"modern", "Modern", "Two-column with sidebar for skills and education"},
	{"minimalist", "Minimalist", "Compact tight-layout for one-page resumes"},
}

// FilteredMatrix is the result of a Jaccard tailor operation.
type FilteredMatrix struct {
	Matrix      *models.ResumeMatrix `json:"matrix" msgpack:"matrix"`
	TailorScore float64              `json:"tailor_score" msgpack:"tailor_score"`
}
