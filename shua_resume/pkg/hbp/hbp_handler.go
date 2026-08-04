// Package hbp decodes incoming HBP v2 frames from the Governor dispatcher,
// dispatches to the correct handler, and encodes the response.
//
// Frame routing:
//
//	shua.resume.matrix.get     -> handleMatrixGet
//	shua.resume.matrix.update  -> handleMatrixUpdate
//	shua.resume.compile        -> handleCompile
//	shua.resume.history.list   -> handleHistoryList
//	shua.resume.templates.list -> handleTemplatesList
package hbp

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/vmihailenco/msgpack/v5"

	"shua_resume/pkg/ai"
	"shua_resume/pkg/compiler"
	"shua_resume/pkg/logger"
	"shua_resume/pkg/mcp"
	"shua_resume/pkg/models"
	"shua_resume/pkg/repository"
)

// Frame is a minimal HBP v2 frame envelope (JSON, as forwarded by the Governor IPC).
type Frame struct {
	ID  string          `json:"id"`
	Mod string          `json:"mod"`
	Op  string          `json:"op"`
	P   json.RawMessage `json:"p"`
	Ts  int64           `json:"ts"`
}

// Handler routes incoming HBP frames to operation handlers.
type Handler struct {
	mcp *mcp.Server
}

// New creates a Handler with a reference to the shared MCP server
// (needed for vault.upload IPC and governor.ai.route RPC).
func New(mcpSrv *mcp.Server) *Handler {
	return &Handler{mcp: mcpSrv}
}

// Handle decodes a raw JSON HBP frame (forwarded from the Governor dispatcher)
// and dispatches it to the correct handler. Returns an encoded JSON response frame.
func (h *Handler) Handle(raw []byte) []byte {
	var frame Frame
	if err := json.Unmarshal(raw, &frame); err != nil {
		logger.Error("hbp_handler", "frame decode error", err, nil)
		return encodeError(frame.ID, frame.Mod, frame.Op, "ERR_FRAME_DECODE")
	}

	logger.Info("hbp_handler", "RPC dispatch", map[string]interface{}{
		"op": frame.Op, "id": frame.ID,
	})

	switch frame.Op {
	case "matrix.get":
		return h.handleMatrixGet(frame)
	case "matrix.update":
		return h.handleMatrixUpdate(frame)
	case "compile":
		return h.handleCompile(frame)
	case "history.list":
		return h.handleHistoryList(frame)
	case "templates.list":
		return h.handleTemplatesList(frame)
	default:
		logger.Warn("hbp_handler", "unknown op", map[string]interface{}{"op": frame.Op})
		return encodeError(frame.ID, frame.Mod, frame.Op, "ERR_UNKNOWN_OP")
	}
}

// handleMatrixGet loads the full ResumeMatrix and encodes it as msgpack.
func (h *Handler) handleMatrixGet(frame Frame) []byte {
	matrix, err := repository.GetMatrix("shua")
	if err != nil {
		logger.Error("hbp_handler", "matrix.get DB error", err, nil)
		return encodeError(frame.ID, frame.Mod, frame.Op, fmt.Sprintf("ERR_DB: %v", err))
	}
	return encodeOK(frame.ID, frame.Mod, frame.Op, matrix)
}

// handleMatrixUpdate processes upsert/delete/reorder actions on a resume section.
func (h *Handler) handleMatrixUpdate(frame Frame) []byte {
	var req struct {
		Section string                 `json:"section" msgpack:"section"`
		Action  string                 `json:"action" msgpack:"action"`
		Item    map[string]interface{} `json:"item" msgpack:"item"`
		ID      string                 `json:"id" msgpack:"id"`
	}
	if err := decodeMsgpackOrJSON(frame.P, &req); err != nil {
		return encodeError(frame.ID, frame.Mod, frame.Op, "ERR_MALFORMED_PAYLOAD")
	}

	newID, err := repository.UpdateSection("shua", req.Section, req.Action, req.Item, req.ID)
	if err != nil {
		logger.Error("hbp_handler", "matrix.update error", err, map[string]interface{}{
			"section": req.Section, "action": req.Action,
		})
		return encodeError(frame.ID, frame.Mod, frame.Op, fmt.Sprintf("ERR_DB: %v", err))
	}

	logger.Info("hbp_handler", "matrix.update ok", map[string]interface{}{
		"section": req.Section, "action": req.Action, "id": newID,
	})
	return encodeOK(frame.ID, frame.Mod, frame.Op, map[string]interface{}{"ok": true, "id": newID})
}

// handleCompile runs the full PDF compile pipeline:
// 1. Load matrix
// 2. Optional Jaccard filter
// 3. Optional AI enhance via governor.ai.route
// 4. Typst compile → []byte PDF (markdown fallback on error)
// 5. vault.upload IPC → sha256 + vault_url
// 6. Save history row
// 7. Return ResumeCompileResponse
func (h *Handler) handleCompile(frame Frame) []byte {
	var req struct {
		MatrixID  string `json:"matrix_id" msgpack:"matrix_id"`
		Template  string `json:"template" msgpack:"template"`
		JobDesc   string `json:"job_desc" msgpack:"job_desc"`
		Tailor    bool   `json:"tailor" msgpack:"tailor"`
		AIEnhance bool   `json:"ai_enhance" msgpack:"ai_enhance"`
	}
	if err := decodeMsgpackOrJSON(frame.P, &req); err != nil {
		return encodeError(frame.ID, frame.Mod, frame.Op, "ERR_MALFORMED_PAYLOAD")
	}
	if req.Template == "" {
		req.Template = "default"
	}

	logger.Info("hbp_handler", "resume.compile dispatched", map[string]interface{}{
		"template": req.Template, "tailor": req.Tailor, "ai_enhance": req.AIEnhance,
	})

	start := time.Now()

	// 1. Load matrix
	matrix, err := repository.GetMatrix("shua")
	if err != nil {
		return encodeError(frame.ID, frame.Mod, frame.Op, fmt.Sprintf("ERR_DB: %v", err))
	}

	// 2. Jaccard filter
	var tailorScore *float32
	if req.Tailor && req.JobDesc != "" {
		cfg := ai.DefaultTailorConfig()
		cfg.UseAI = false // Jaccard only here
		_, score := ai.FilterResume(matrix, req.JobDesc, cfg)
		sf := float32(score)
		tailorScore = &sf
	}

	// 3. AI enhance
	if req.AIEnhance && req.JobDesc != "" {
		cfg := ai.DefaultTailorConfig()
		cfg.UseAI = true
		matrix = ai.TailorResumeViaGovernor(matrix, req.JobDesc, cfg, h.mcp.SendAIRoute)
	}

	// 4. Typst compile — markdown fallback on error
	var pdfBytes []byte
	var compileErr string
	pdfBytes, err = compiler.CompileTypst(matrix, req.Template)
	if err != nil {
		if strings.HasPrefix(err.Error(), "ERR_TYPST_UNAVAILABLE") {
			compileErr = "ERR_TYPST_UNAVAILABLE"
			// Fallback: encode markdown as UTF-8 bytes
			md := compiler.MatrixToMarkdown(matrix)
			pdfBytes = []byte(md)
			logger.Warn("compiler", "typst binary absent — markdown fallback activated", nil)
		} else {
			return encodeError(frame.ID, frame.Mod, frame.Op, fmt.Sprintf("ERR_COMPILE: %v", err))
		}
	}

	// 5. Vault upload via Governor IPC
	ts := time.Now().UTC().Format("20060102T150405")
	fileName := fmt.Sprintf("resume_%s.pdf", ts)
	mimeType := "application/pdf"
	if compileErr != "" {
		fileName = fmt.Sprintf("resume_%s.md", ts)
		mimeType = "text/markdown"
	}
	b64Data := base64.StdEncoding.EncodeToString(pdfBytes)
	sha256Hash, vaultURL, vaultErr := h.mcp.SendVaultUpload("resume", fileName, mimeType, b64Data)
	if vaultErr != nil {
		logger.Error("vault_ipc", "vault.upload IPC failed", vaultErr, map[string]interface{}{"file": fileName})
		// Use a local placeholder to avoid blocking the response
		sha256Hash = uuid.New().String()
		vaultURL = ""
	}

	// 6. Save history
	durationMs := uint32(time.Since(start).Milliseconds())
	history := models.HistoryItem{
		ExhibitId:   sha256Hash,
		VaultUrl:    vaultURL,
		TemplateId:  req.Template,
		JobDesc:     req.JobDesc,
		TailorScore: tailorScore,
		AiEnhanced:  req.AIEnhance,
		DurationMs:  durationMs,
		CompiledAt:  time.Now().UTC().Format(time.RFC3339),
	}
	if err := repository.SaveHistory(history); err != nil {
		logger.Error("hbp_handler", "save history error", err, nil)
	}

	logger.Info("hbp_handler", "resume.compile complete", map[string]interface{}{
		"exhibit_id": sha256Hash, "vault_url": vaultURL, "duration_ms": durationMs,
	})

	// 7. Response
	resp := map[string]interface{}{
		"1": sha256Hash,  // exhibit_id
		"2": vaultURL,    // pdf_url
		"3": durationMs,  // duration_ms
		"4": tailorScore, // tailor_score (nil if not tailored)
	}
	if compileErr != "" {
		resp["err"] = compileErr
		resp["p"] = string(pdfBytes) // markdown fallback text
	}
	return encodeOK(frame.ID, frame.Mod, frame.Op, resp)
}

// handleHistoryList returns the last 50 PDF compilation history rows.
func (h *Handler) handleHistoryList(frame Frame) []byte {
	items, err := repository.ListHistory()
	if err != nil {
		logger.Error("hbp_handler", "history.list error", err, nil)
		return encodeError(frame.ID, frame.Mod, frame.Op, fmt.Sprintf("ERR_DB: %v", err))
	}
	return encodeOK(frame.ID, frame.Mod, frame.Op, map[string]interface{}{"items": items})
}

// handleTemplatesList returns the static list of available Typst templates.
func (h *Handler) handleTemplatesList(frame Frame) []byte {
	return encodeOK(frame.ID, frame.Mod, frame.Op, map[string]interface{}{
		"templates": mcp.AvailableTemplates,
	})
}

// ── encode helpers ────────────────────────────────────────────────────────────

func encodeOK(id, mod, op string, payload interface{}) []byte {
	p, _ := msgpack.Marshal(payload)
	b64 := base64.StdEncoding.EncodeToString(p)
	frame := map[string]interface{}{
		"t":   2, // MessageTypeResponse
		"id":  id,
		"mod": mod,
		"op":  op,
		"p":   b64,
		"ts":  time.Now().UnixMilli(),
	}
	b, _ := json.Marshal(frame)
	return b
}

func encodeError(id, mod, op, errMsg string) []byte {
	frame := map[string]interface{}{
		"t":   6, // MessageTypeError
		"id":  id,
		"mod": mod,
		"op":  op,
		"err": errMsg,
		"ts":  time.Now().UnixMilli(),
	}
	b, _ := json.Marshal(frame)
	return b
}

// decodeMsgpackOrJSON tries msgpack first, falls back to JSON.
// decodeMsgpackOrJSON tries msgpack (Base64 or Int Array) first, falls back to JSON.
func decodeMsgpackOrJSON(raw json.RawMessage, dst interface{}) error {
	if len(raw) == 0 {
		return nil
	}

	// 1. Attempt Base64 + msgpack (HBP v2 canonical)
	var b64str string
	if err := json.Unmarshal(raw, &b64str); err == nil {
		decoded, err := base64.StdEncoding.DecodeString(b64str)
		if err == nil {
			if err := msgpack.Unmarshal(decoded, dst); err == nil {
				return nil
			}
		}
	}

	// 2. Attempt JSON array of integers (if Dart sent List<int> directly)
	var intArr []int
	if err := json.Unmarshal(raw, &intArr); err == nil {
		bytes := make([]byte, len(intArr))
		for i, v := range intArr {
			bytes[i] = byte(v)
		}
		if err := msgpack.Unmarshal(bytes, dst); err == nil {
			return nil
		}
	}

	// 3. Fallback: plain JSON object decoding
	err := json.Unmarshal(raw, dst)
	if err != nil {
		// Stop failing silently! Log the exact reason decoding failed.
		logger.Error("hbp_handler", "all payload decoders failed", err, map[string]interface{}{
			"raw_payload": string(raw),
		})
	}

	return err
}
