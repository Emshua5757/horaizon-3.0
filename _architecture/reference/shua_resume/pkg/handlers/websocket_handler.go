package handlers

import (
	"encoding/json"
	"fmt"
	"net"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"shua_resume/pkg/ai"
	"shua_resume/pkg/compiler"
	"shua_resume/pkg/db"
	"shua_resume/pkg/logger"
	"shua_resume/pkg/models"

	"github.com/gofiber/contrib/websocket"
	"github.com/google/uuid"
	"github.com/vmihailenco/msgpack/v5"
)

var DetectedHostIP string = "127.0.0.1"

// SocketConnection wraps the websocket connection and provides Engine.io/Socket.io compatibility.
type SocketConnection struct {
	Conn *websocket.Conn
	mu   sync.Mutex
}

func (s *SocketConnection) Emit(event string, payload interface{}) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Socket.io v4 Binary Event Protocol (Engine.io text frame header + binary frame payload)
	if bytesData, ok := payload.([]byte); ok {
		header := fmt.Sprintf(`451-["%s",{"_placeholder":true,"num":0}]`, event)
		if err := s.Conn.WriteMessage(websocket.TextMessage, []byte(header)); err != nil {
			return err
		}
		return s.Conn.WriteMessage(websocket.BinaryMessage, bytesData)
	}

	// Standard Socket.io v4 Text Event Protocol
	packetBytes, err := json.Marshal([]interface{}{event, payload})
	if err != nil {
		return err
	}
	packet := "42" + string(packetBytes)
	return s.Conn.WriteMessage(websocket.TextMessage, []byte(packet))
}

type RpcRequest struct {
	Method        string                 `json:"method"`
	Params        map[string]interface{} `json:"params"`
	TransactionID string                 `json:"transaction_id"`
}

// HandleWebSocket manages the Socket.io WebSocket connection lifecycle on the Go microservice
func HandleWebSocket(c *websocket.Conn) {
	if c != nil && c.LocalAddr() != nil {
		localAddr := c.LocalAddr().String()
		if host, _, err := net.SplitHostPort(localAddr); err == nil {
			if host != "" && host != "::1" && host != "0.0.0.0" && host != "::" {
				DetectedHostIP = host
			}
		} else {
			if idx := strings.Index(localAddr, ":"); idx != -1 {
				DetectedHostIP = localAddr[:idx]
			} else {
				DetectedHostIP = localAddr
			}
		}
	}

	s := &SocketConnection{Conn: c}

	// 1. Send Engine.io Handshake Open Packet immediately upon upgrade connection
	sid := uuid.New().String()
	handshake := fmt.Sprintf(`0{"sid":"%s","upgrades":[],"pingInterval":25000,"pingTimeout":20000}`, sid)
	if err := c.WriteMessage(websocket.TextMessage, []byte(handshake)); err != nil {
		logger.Error("websocket", "Failed to send handshake open packet", err, nil)
		fmt.Printf("[WebSocket Error] Failed to send handshake: %v\n", err)
		return
	}

	logger.Info("websocket", "Client upgraded to Engine.io session", map[string]interface{}{"sid": sid})
	fmt.Printf("[WebSocket] Handshake sent successfully for sid: %s\n", sid)

	for {
		mt, msgBytes, err := c.ReadMessage()
		if err != nil {
			logger.Info("websocket", "Connection closed by client", map[string]interface{}{"error": err.Error()})
			fmt.Printf("[WebSocket] Connection closed: %v\n", err)
			break
		}

		if mt != websocket.TextMessage {
			continue
		}

		msg := string(msgBytes)
		if len(msg) == 0 {
			continue
		}

		fmt.Printf("[WebSocket] Received packet: %s\n", msg)

		// Handle Engine.io Packet Types
		switch msg[0] {
		case '2': // Engine.io PING -> respond with PONG
			s.mu.Lock()
			_ = c.WriteMessage(websocket.TextMessage, []byte("3"))
			s.mu.Unlock()
			continue

		case '4': // Engine.io MESSAGE (covers Socket.io sub-packets)
			if len(msg) < 2 {
				continue
			}
			subType := msg[1]
			switch subType {
			case '0': // Socket.io CONNECT -> respond with CONNECT
				s.mu.Lock()
				connectAck := fmt.Sprintf(`40{"sid":"%s"}`, sid)
				_ = c.WriteMessage(websocket.TextMessage, []byte(connectAck))
				s.mu.Unlock()
				logger.Info("websocket", "Socket.io namespace connected", nil)
				fmt.Printf("[WebSocket] Socket.io namespace connection established (sent: %s)\n", connectAck)

			case '2': // Socket.io EVENT -> parse RPC
				eventPayload := msg[2:]
				var arr []json.RawMessage
				if err := json.Unmarshal([]byte(eventPayload), &arr); err != nil {
					logger.Error("websocket", "Malformed Socket.io event array", err, nil)
					continue
				}

				if len(arr) < 2 {
					continue
				}

				var eventName string
				_ = json.Unmarshal(arr[0], &eventName)
				fmt.Printf("[DEBUG] Parsed Socket.io Event Name: %q (raw: %s)\n", eventName, string(arr[0]))

				if eventName == "rpc" {
					var rpc ReqRpc
					if err := json.Unmarshal(arr[1], &rpc); err != nil {
						logger.Error("websocket", "Malformed RPC request body", err, nil)
						continue
					}
					fmt.Printf("[WebSocket] Processing RPC Method: %s (tx: %s)\n", rpc.Method, rpc.TransactionID)
					go handleRpcCall(s, rpc)
				}
			}
		}
	}
}

// Map the struct key variants of Socket.io client
type ReqRpc struct {
	Method        string                 `json:"method"`
	Params        map[string]interface{} `json:"params"`
	TransactionID string                 `json:"transaction_id"`
}

func handleRpcCall(s *SocketConnection, rpc ReqRpc) {
	logger.Info("websocket", "Inbound RPC dispatch", map[string]interface{}{
		"method": rpc.Method,
		"tx_id":  rpc.TransactionID,
	})

	switch rpc.Method {
	case "request_screen":
		screenId, _ := rpc.Params["screenId"].(string)
		if screenId == "" {
			sendRpcError(s, rpc.TransactionID, "Missing screenId parameter")
			return
		}

		// Query and assemble the screen layout dynamically
		fmt.Printf("[DEBUG-TRACE] Calling assembleScreen(%s)\n", screenId)
		payload, err := assembleScreen(screenId)
		if err != nil {
			fmt.Printf("[DEBUG-TRACE] assembleScreen returned error: %v\n", err)
			logger.Error("websocket", "Failed to assemble screen blueprint", err, map[string]interface{}{"screenId": screenId})
			sendRpcError(s, rpc.TransactionID, err.Error())
			return
		}

		fmt.Printf("[DEBUG-TRACE] assembleScreen succeeded. Encoding msgpack...\n")
		// MsgPack encode the full list and emit it to replace_${screenId}
		// Flutter's SduiTransport._parseList() strictly requires a top-level array.
		msgpackBytes, err := msgpack.Marshal([]interface{}{payload})
		if err != nil {
			fmt.Printf("[DEBUG-TRACE] MsgPack encode failed: %v\n", err)
			logger.Error("websocket", "MsgPack encoding failed for screen replacement", err, nil)
			sendRpcError(s, rpc.TransactionID, "Encoding failed")
			return
		}

		fmt.Printf("[DEBUG-TRACE] MsgPack encoded %d bytes. Emitting to replace_%s\n", len(msgpackBytes), screenId)
		errEmit := s.Emit(fmt.Sprintf("replace_%s", screenId), msgpackBytes)
		if errEmit != nil {
			fmt.Printf("[DEBUG-TRACE] s.Emit returned error: %v\n", errEmit)
		} else {
			fmt.Printf("[DEBUG-TRACE] s.Emit succeeded.\n")
		}

		sendRpcSuccess(s, rpc.TransactionID, nil)

	case "shua.resume.compile_pdf":
		// Handle compilation via WebSocket
		go handleWsofflineCompile(s, rpc)

	case "shua.resume.add_work", "shua.resume.update_work", "shua.resume.delete_work",
		"shua.resume.add_education", "shua.resume.update_education", "shua.resume.delete_education",
		"shua.resume.add_project", "shua.resume.update_project", "shua.resume.delete_project",
		"shua.resume.add_skill", "shua.resume.delete_skill":
		go handleMatrixCrud(s, rpc)

	case "shua.resume.get_matrix":
		var matrixJSON string
		err := db.DB.QueryRow("SELECT matrix_json FROM shua_resume_matrix WHERE user_id = ?", "default").Scan(&matrixJSON)
		if err != nil {
			sendRpcError(s, rpc.TransactionID, "Matrix not found")
			return
		}
		sendRpcSuccess(s, rpc.TransactionID, matrixJSON)

	case "shua.resume.get_templates":
		list, err := getTemplatesList()
		if err != nil {
			sendRpcError(s, rpc.TransactionID, err.Error())
			return
		}
		sendRpcSuccess(s, rpc.TransactionID, list)

	case "shua.resume.list_compiled":
		list, err := getCompiledHistory(rpc.Params)
		if err != nil {
			sendRpcError(s, rpc.TransactionID, err.Error())
			return
		}
		sendRpcSuccess(s, rpc.TransactionID, list)

	case "shua.resume.delete_compilation":
		go handleDeleteCompilation(s, rpc)

	default:
		sendRpcError(s, rpc.TransactionID, fmt.Sprintf("Unknown RPC method: %s", rpc.Method))
	}
}

func sendRpcError(s *SocketConnection, txId string, message string) {
	resp := map[int]interface{}{
		0: 1, // status: error
		2: message,
		3: txId,
	}
	encoded, _ := msgpack.Marshal(resp)
	_ = s.Emit("rpc_response", encoded)
}

func sendRpcSuccess(s *SocketConnection, txId string, data interface{}) {
	resp := map[int]interface{}{
		0: 0, // status: success
		3: txId,
	}
	if data != nil {
		resp[1] = data
	}
	encoded, _ := msgpack.Marshal(resp)
	_ = s.Emit("rpc_response", encoded)
}

func assembleScreen(screenId string) (interface{}, error) {
	governorHost := os.Getenv("GOVERNOR_HOST")
	if governorHost == "" {
		governorHost = DetectedHostIP
	}

	baseScreenId := screenId
	var queryId string
	if strings.Contains(screenId, "?id=") {
		parts := strings.Split(screenId, "?id=")
		baseScreenId = parts[0]
		queryId = parts[1]
	}

	switch baseScreenId {
	case "resume_dashboard":
		// Load master matrix for stat counts
		var matrixJSON string
		var workCount, projectCount, skillCount, certCount int
		var basicsName, basicsLabel string
		err := db.DB.QueryRow("SELECT matrix_json FROM shua_resume_matrix WHERE user_id = ?", "default").Scan(&matrixJSON)
		if err == nil {
			var mat models.ResumeMatrix
			if json.Unmarshal([]byte(matrixJSON), &mat) == nil {
				workCount = len(mat.Work)
				projectCount = len(mat.Projects)
				skillCount = len(mat.Skills)
				certCount = len(mat.Certificates)
				basicsName = mat.Basics.Name
				basicsLabel = mat.Basics.Label
			}
		}

		// Count compiled PDF versions
		var historyCount int
		_ = db.DB.QueryRow("SELECT COUNT(*) FROM shua_compiled_resumes").Scan(&historyCount)

		// Fetch recent compiled history
		rows, err := db.DB.Query("SELECT id, template_id, exhibit_id, version_tag, meta_notes, created_at FROM shua_compiled_resumes ORDER BY created_at DESC LIMIT 20")
		historyItems := []map[string]interface{}{}
		if err == nil {
			defer rows.Close()
			for rows.Next() {
				var id, templateID, exhibitID, version, notes string
				var createdAt int64
				if errScan := rows.Scan(&id, &templateID, &exhibitID, &version, &notes, &createdAt); errScan == nil {
					t := time.Unix(0, createdAt*int64(time.Millisecond))
					dateStr := t.Format("2006-01-02 15:04")
					historyItems = append(historyItems, map[string]interface{}{
						"id":          id,
						"version_tag": version,
						"meta_notes":  fmt.Sprintf("%s · %s", notes, dateStr),
						"exhibit_url": fmt.Sprintf("http://%s:3000/api/media/uploads/%s.pdf", governorHost, exhibitID),
					})
				}
			}
			if errRows := rows.Err(); errRows != nil {
				logger.Error("websocket", "Failed to iterate history rows", errRows, nil)
			}
		}

		ctx := map[string]interface{}{
			"basics.name":   basicsName,
			"basics.label":  basicsLabel,
			"work_count":    fmt.Sprintf("%d", workCount),
			"project_count": fmt.Sprintf("%d", projectCount),
			"skill_count":   fmt.Sprintf("%d", skillCount),
			"cert_count":    fmt.Sprintf("%d", certCount),
			"history_count": fmt.Sprintf("%d", historyCount),
			"history_items": historyItems,
		}

		return LoadAndHydrateBlueprint("resume_dashboard", ctx)

	case "resume_forge":
		ctx := map[string]interface{}{
			"exhibit_url": "",
		}
		return LoadAndHydrateBlueprint("resume_forge", ctx)

	case "resume_matrix":
		// Read master matrix from DB and hydrate the arrays
		var matrixJSON string
		err := db.DB.QueryRow("SELECT matrix_json FROM shua_resume_matrix WHERE user_id = ?", "default").Scan(&matrixJSON)

		ctx := map[string]interface{}{}
		if err == nil {
			var mat models.ResumeMatrix
			if json.Unmarshal([]byte(matrixJSON), &mat) == nil {
				ctx["basics"] = mat.Basics

				// formatBullets emits SDUI-4 ListEditor wire format for list_style:2 (bullets with dash prefix).
				// e.g. ["A","B"] → "- A\n- B"
				formatBullets := func(arr []string) string {
					if len(arr) == 0 {
						return ""
					}
					lines := make([]string, 0, len(arr))
					for _, item := range arr {
						item = strings.TrimSpace(item)
						if item != "" {
							lines = append(lines, "- "+item)
						}
					}
					return strings.Join(lines, "\n")
				}
				// formatTags emits SDUI-4 ListEditor wire format for list_style:0 (tags with # prefix).
				// e.g. ["A","B"] → "# A\n# B"
				formatTags := func(arr []string) string {
					if len(arr) == 0 {
						return ""
					}
					lines := make([]string, 0, len(arr))
					for _, item := range arr {
						item = strings.TrimSpace(item)
						if item != "" {
							lines = append(lines, "# "+item)
						}
					}
					return strings.Join(lines, "\n")
				}

				workList := make([]map[string]interface{}, 0)
				for _, w := range mat.Work {
					b, _ := json.Marshal(w)
					var m map[string]interface{}
					json.Unmarshal(b, &m)
					m["highlightsFormatted"] = formatBullets(w.Highlights)
					m["skillsFormatted"] = formatTags(w.Skills)
					workList = append(workList, m)
				}
				ctx["work_items"] = workList

				eduList := make([]map[string]interface{}, 0)
				for _, e := range mat.Education {
					b, _ := json.Marshal(e)
					var m map[string]interface{}
					json.Unmarshal(b, &m)
					m["coursesFormatted"] = formatTags(e.Courses)
					eduList = append(eduList, m)
				}
				ctx["education_items"] = eduList

				projList := make([]map[string]interface{}, 0)
				for _, p := range mat.Projects {
					b, _ := json.Marshal(p)
					var m map[string]interface{}
					json.Unmarshal(b, &m)
					m["highlightsFormatted"] = formatBullets(p.Highlights)
					m["exhibitsFormatted"] = formatTags(p.Exhibits)
					projList = append(projList, m)
				}
				ctx["project_items"] = projList

				skillList := make([]map[string]interface{}, 0)
				for _, s := range mat.Skills {
					b, _ := json.Marshal(s)
					var m map[string]interface{}
					json.Unmarshal(b, &m)
					m["keywordsFormatted"] = formatTags(s.Keywords)
					skillList = append(skillList, m)
				}
				ctx["skill_items"] = skillList

				ctx["certificate_items"] = mat.Certificates
				ctx["award_items"] = mat.Awards
			}
		}

		res, errLoad := LoadAndHydrateBlueprint("resume_matrix", ctx)
		if errLoad == nil {
			if b, e := json.MarshalIndent(res, "", "  "); e == nil {
				fmt.Println("\n\n[DEBUG-MATRIX] Hydrated matrix payload:\n" + string(b) + "\n\n")
			}
		}
		return res, errLoad

	case "resume_add_work", "resume_add_education", "resume_add_project", "resume_add_skill", "resume_add_certificate", "resume_add_award":
		var submitRpc int
		switch baseScreenId {
		case "resume_add_work":
			submitRpc = 506
		case "resume_add_education":
			submitRpc = 509
		case "resume_add_project":
			submitRpc = 512
		case "resume_add_skill":
			submitRpc = 515
		case "resume_add_certificate":
			submitRpc = 518
		case "resume_add_award":
			submitRpc = 521
		}

		ctx := map[string]interface{}{
			"submit_rpc":  submitRpc,
			"modal_title": "Add " + strings.Title(strings.Split(baseScreenId, "_")[2]),
			"is_update":   false,
		}
		return LoadAndHydrateBlueprint(baseScreenId, ctx)

	case "edit_work", "edit_education", "edit_project", "edit_skill", "edit_certificate", "edit_award":
		var submitRpc int
		switch baseScreenId {
		case "edit_work":
			submitRpc = 507
		case "edit_education":
			submitRpc = 510
		case "edit_project":
			submitRpc = 513
		case "edit_skill":
			submitRpc = 517
		case "edit_certificate":
			submitRpc = 519
		case "edit_award":
			submitRpc = 522
		}

		ctx := map[string]interface{}{
			"submit_rpc":  submitRpc,
			"modal_title": "Update " + strings.Title(strings.Split(baseScreenId, "_")[1]),
			"is_update":   true,
			"id":          queryId,
		}

		var matrixJSON string
		db.DB.QueryRow("SELECT matrix_json FROM shua_resume_matrix WHERE user_id = ?", "default").Scan(&matrixJSON)
		var mat models.ResumeMatrix
		if err := json.Unmarshal([]byte(matrixJSON), &mat); err == nil {
			switch baseScreenId {
			case "edit_work":
				for _, w := range mat.Work {
					if w.Id == queryId {
						wBytes, _ := json.Marshal(w)
						json.Unmarshal(wBytes, &ctx)
						ctx["highlights"] = strings.Join(w.Highlights, "\n")
						ctx["skills"] = strings.Join(w.Skills, "\n")
					}
				}
			case "edit_education":
				for _, w := range mat.Education {
					if w.Id == queryId {
						wBytes, _ := json.Marshal(w)
						json.Unmarshal(wBytes, &ctx)
						ctx["courses"] = strings.Join(w.Courses, "\n")
					}
				}
			case "edit_project":
				for _, w := range mat.Projects {
					if w.Id == queryId {
						wBytes, _ := json.Marshal(w)
						json.Unmarshal(wBytes, &ctx)
						ctx["highlights"] = strings.Join(w.Highlights, "\n")
						ctx["exhibits"] = strings.Join(w.Exhibits, "\n")
					}
				}
			case "edit_skill":
				for _, w := range mat.Skills {
					if w.Id == queryId {
						wBytes, _ := json.Marshal(w)
						json.Unmarshal(wBytes, &ctx)
						ctx["keywords"] = strings.Join(w.Keywords, "\n")
					}
				}
			case "edit_certificate":
				for _, w := range mat.Certificates {
					if w.Id == queryId {
						wBytes, _ := json.Marshal(w)
						json.Unmarshal(wBytes, &ctx)
					}
				}
			case "edit_award":
				for _, w := range mat.Awards {
					if w.Id == queryId {
						wBytes, _ := json.Marshal(w)
						json.Unmarshal(wBytes, &ctx)
					}
				}
			}
		}

		blueprintName := strings.ReplaceAll(baseScreenId, "edit_", "resume_add_")
		return LoadAndHydrateBlueprint(blueprintName, ctx)
	}

	return nil, fmt.Errorf("unknown screenId: %s", screenId)
}

func getTemplatesList() ([]map[string]interface{}, error) {
	rows, err := db.DB.Query("SELECT id, name, template_type FROM shua_resume_templates")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []map[string]interface{}
	for rows.Next() {
		var id, name, tType string
		if err := rows.Scan(&id, &name, &tType); err == nil {
			list = append(list, map[string]interface{}{
				"id":            id,
				"name":          name,
				"template_type": tType,
			})
		}
	}
	if errRows := rows.Err(); errRows != nil {
		return nil, errRows
	}
	return list, nil
}

func getCompiledHistory(params map[string]interface{}) ([]map[string]interface{}, error) {
	limit := 10
	offset := 0

	if val, ok := params["limit"]; ok {
		if l, ok := val.(float64); ok {
			limit = int(l)
		} else if lStr, ok := val.(string); ok {
			if parsed, err := strconv.Atoi(lStr); err == nil {
				limit = parsed
			}
		}
	}
	if val, ok := params["offset"]; ok {
		if o, ok := val.(float64); ok {
			offset = int(o)
		} else if oStr, ok := val.(string); ok {
			if parsed, err := strconv.Atoi(oStr); err == nil {
				offset = parsed
			}
		}
	}

	rows, err := db.DB.Query(
		"SELECT id, user_id, template_id, exhibit_id, version_tag, meta_notes, created_at FROM shua_compiled_resumes ORDER BY created_at DESC LIMIT ? OFFSET ?",
		limit, offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []map[string]interface{}
	for rows.Next() {
		var id, userID, templateID, exhibitID, version, notes string
		var createdAt int64
		if err := rows.Scan(&id, &userID, &templateID, &exhibitID, &version, &notes, &createdAt); err == nil {
			list = append(list, map[string]interface{}{
				"id":          id,
				"user_id":     userID,
				"template_id": templateID,
				"exhibit_id":  exhibitID,
				"version_tag": version,
				"meta_notes":  notes,
				"created_at":  createdAt,
			})
		}
	}
	if errRows := rows.Err(); errRows != nil {
		return nil, errRows
	}
	return list, nil
}

func handleWsofflineCompile(s *SocketConnection, rpc ReqRpc) {
	// Semaphore concurrency protection
	select {
	case compileSemaphore <- struct{}{}:
		defer func() { <-compileSemaphore }()
	default:
		sendRpcError(s, rpc.TransactionID, "Server busy")
		return
	}

	governorHost := os.Getenv("GOVERNOR_HOST")
	if governorHost == "" {
		governorHost = DetectedHostIP
	}

	logger.Info("resume_forge", "handleWsofflineCompile started. parsing parameters...", nil)
	// Parse params
	var jd string
	if val, ok := rpc.Params["resume_forge:jd_input"]; ok {
		jd, _ = val.(string)
	} else if val, ok := rpc.Params["jd_input"]; ok {
		jd, _ = val.(string)
	}
	logger.Info("resume_forge", fmt.Sprintf("Job Description length: %d characters", len(jd)), nil)

	var templateName = "ats_technical"
	if val, ok := rpc.Params["resume_forge:template_picker"]; ok && val != nil {
		if tStr, ok := val.(string); ok && tStr != "" {
			if strings.HasPrefix(tStr, "{") {
				var parsed map[string]interface{}
				if err := json.Unmarshal([]byte(tStr), &parsed); err == nil {
					if v, ok := parsed["value"].(string); ok && v != "" {
						templateName = v
					}
				}
			} else {
				templateName = tStr
			}
		}
	}
	logger.Info("resume_forge", fmt.Sprintf("Selected template: %s", templateName), nil)

	var useAI bool
	if val, ok := rpc.Params["resume_forge:ai_toggle"]; ok && val != nil {
		useAI, _ = val.(bool)
	}
	logger.Info("resume_forge", fmt.Sprintf("Use AI tailoring: %v", useAI), nil)

	// Optimistic UI: immediately show shimmer + hide empty state before heavy work begins.
	logger.Info("resume_forge", "Emitting optimistic start patch (showing shimmer, hiding empty/pdf viewer)...", nil)
	startPatch := map[string]interface{}{
		"op": "batch",
		"ops": []interface{}{
			map[string]interface{}{
				"op":        "patch",
				"node_id":   "resume_forge:preview_shimmer",
				"behaviors": map[string]interface{}{"5": true},
			},
			map[string]interface{}{
				"op":        "patch",
				"node_id":   "resume_forge:empty_state",
				"behaviors": map[string]interface{}{"5": false},
			},
			map[string]interface{}{
				"op":        "patch",
				"node_id":   "resume_forge:preview_pdf",
				"behaviors": map[string]interface{}{"5": false},
			},
			map[string]interface{}{
				"op":        "patch",
				"node_id":   "resume_forge:download_row",
				"behaviors": map[string]interface{}{"5": false},
			},
		},
	}
	if startBytes, encErr := msgpack.Marshal(startPatch); encErr == nil {
		_ = s.Emit("patch_resume_forge", startBytes)
	}

	// Fetch matrix from database
	logger.Info("resume_forge", "Querying resume matrix from database...", nil)
	var matrixJSON string
	err := db.DB.QueryRow("SELECT matrix_json FROM shua_resume_matrix WHERE user_id = ?", "default").Scan(&matrixJSON)
	if err != nil {
		logger.Error("resume_forge", "Failed to query matrix", err, nil)
		sendRpcError(s, rpc.TransactionID, "Matrix missing")
		return
	}

	var matrix models.ResumeMatrix
	if err := json.Unmarshal([]byte(matrixJSON), &matrix); err != nil {
		logger.Error("resume_forge", "Failed to unmarshal matrix JSON", err, nil)
		sendRpcError(s, rpc.TransactionID, "Matrix JSON corrupt")
		return
	}
	logger.Info("resume_forge", fmt.Sprintf("Loaded resume matrix for: %s", matrix.Basics.Name), nil)

	// Run Relevance Pre-Filtering & Tailoring
	if strings.TrimSpace(jd) != "" {
		logger.Info("resume_forge", "Running relevance pre-filtering and AI tailoring...", nil)
		config := ai.DefaultTailorConfig()
		config.UseAI = useAI

		filteredMatrix := ai.FilterResume(&matrix, jd, config)
		tailoredMatrix := ai.TailorResume(filteredMatrix, jd, config)
		matrix = *tailoredMatrix
		logger.Info("resume_forge", "Filtering and tailoring completed successfully.", nil)
	} else {
		logger.Info("resume_forge", "Empty Job Description: skipping filtering and AI tailoring pass.", nil)
	}

	// Compile Typst PDF
	logger.Info("resume_forge", fmt.Sprintf("Compiling PDF template '%s' via Typst...", templateName), nil)
	pdfBytes, compileErr := compiler.CompileTypst(&matrix, templateName)
	if compileErr != nil {
		logger.Error("resume_forge", "Typst compilation failed", compileErr, nil)
		sendRpcError(s, rpc.TransactionID, compileErr.Error())
		return
	}
	logger.Info("resume_forge", fmt.Sprintf("Typst compilation successful. Output PDF size: %d bytes", len(pdfBytes)), nil)

	// Upload to CAS
	logger.Info("resume_forge", "Uploading PDF to CAS media vault...", nil)
	exhibitID, uploadErr := uploadToCAS(pdfBytes)
	if uploadErr != nil {
		logger.Error("resume_forge", "CAS upload failed", uploadErr, nil)
		sendRpcError(s, rpc.TransactionID, "Upload to CAS failed: "+uploadErr.Error())
		return
	}
	logger.Info("resume_forge", fmt.Sprintf("Upload successful. Exhibit ID: %s", exhibitID), nil)

	// Log to history
	logger.Info("resume_forge", "Logging compilation run to local database history...", nil)
	if historyErr := saveCompilationToHistory(templateName, exhibitID, jd); historyErr != nil {
		logger.Error("resume_forge", "Failed to log compilation to history", historyErr, nil)
	}

	exhibitURL := fmt.Sprintf("/api/media/uploads/%s.pdf", exhibitID)
	logger.Info("resume_forge", fmt.Sprintf("Generated CAS PDF URL: %s", exhibitURL), nil)

	// Send all state transitions as a single atomic batch delta.
	batchPatch := map[string]interface{}{
		"op": "batch",
		"ops": []interface{}{
			// Op 1: Hide shimmer
			map[string]interface{}{
				"op":      "patch",
				"node_id": "resume_forge:preview_shimmer",
				"behaviors": map[string]interface{}{
					"5": false,
				},
			},
			// Op 2: Show PDF viewer and bind CAS URL
			map[string]interface{}{
				"op":      "patch",
				"node_id": "resume_forge:preview_pdf",
				"behaviors": map[string]interface{}{
					"5": true,
				},
				"content": map[string]interface{}{
					"5": exhibitURL,
				},
			},
			// Op 3: Show download/copy buttons row
			map[string]interface{}{
				"op":      "patch",
				"node_id": "resume_forge:download_row",
				"behaviors": map[string]interface{}{
					"5": true,
				},
			},
			// Op 4: Ensure empty state placeholder is hidden
			map[string]interface{}{
				"op":      "patch",
				"node_id": "resume_forge:empty_state",
				"behaviors": map[string]interface{}{
					"5": false,
				},
			},
			// Op 5: Patch download button action payload
			map[string]interface{}{
				"op":      "patch",
				"node_id": "resume_forge:btn_download_pdf",
				"behaviors": map[string]interface{}{
					"70": map[string]interface{}{
						"0": 5,
						"3": exhibitURL,
					},
				},
			},
			// Op 6: Patch copy link button action payload
			map[string]interface{}{
				"op":      "patch",
				"node_id": "resume_forge:btn_copy_link",
				"behaviors": map[string]interface{}{
					"70": map[string]interface{}{
						"0": 8,
						"3": exhibitURL,
					},
				},
			},
		},
	}
	batchBytes, _ := msgpack.Marshal(batchPatch)
	_ = s.Emit("patch_resume_forge", batchBytes)

	// Return successful RPC response to let Flutter complete the form submission
	sendRpcSuccess(s, rpc.TransactionID, map[string]interface{}{
		"exhibit_id": exhibitID,
		"url":        exhibitURL,
	})
}

// ==========================================
// Phase 9: Matrix Configurable CRUD Redesign
// ==========================================

func parseListEditorString(val interface{}) []string {
	str, ok := val.(string)
	if !ok || str == "" {
		return []string{}
	}
	var res []string
	lines := strings.Split(str, "\n")
	for _, l := range lines {
		l = strings.TrimSpace(l)
		if l == "" {
			continue
		}
		if strings.HasPrefix(l, "- ") {
			l = strings.TrimPrefix(l, "- ")
		} else if strings.HasPrefix(l, "# ") {
			l = strings.TrimPrefix(l, "# ")
		} else if strings.HasPrefix(l, "> ") {
			l = strings.TrimPrefix(l, "> ")
		}
		res = append(res, l)
	}
	return res
}

func parseBoolStr(val interface{}) bool {
	str, ok := val.(string)
	if !ok {
		return false
	}
	return str == "true" || str == "1"
}

func handleMatrixCrud(s *SocketConnection, rpc ReqRpc) {
	var matrixJSON string
	err := db.DB.QueryRow("SELECT matrix_json FROM shua_resume_matrix WHERE user_id = ?", "default").Scan(&matrixJSON)
	if err != nil {
		sendRpcError(s, rpc.TransactionID, "Matrix not found")
		return
	}

	var matrix models.ResumeMatrix
	if err := json.Unmarshal([]byte(matrixJSON), &matrix); err != nil {
		sendRpcError(s, rpc.TransactionID, "Corrupt matrix data")
		return
	}

	entryId, _ := rpc.Params["id"].(string)
	// Some delete actions might pass entryId in "5" or "id"
	if entryId == "" {
		entryId, _ = rpc.Params["5"].(string)
	}

	switch rpc.Method {
	case "shua.resume.add_work":
		var item models.WorkItem
		item.Id = uuid.NewString()
		item.Name, _ = rpc.Params["name"].(string)
		item.Position, _ = rpc.Params["position"].(string)
		item.Url, _ = rpc.Params["url"].(string)
		item.StartDate, _ = rpc.Params["startDate"].(string)
		item.EndDate, _ = rpc.Params["endDate"].(string)
		item.Summary, _ = rpc.Params["summary"].(string)
		item.Highlights = parseListEditorString(rpc.Params["highlights"])
		item.Skills = parseListEditorString(rpc.Params["skills"])
		item.Active = parseBoolStr(rpc.Params["active"])
		matrix.Work = append(matrix.Work, item)

	case "shua.resume.update_work":
		for i, w := range matrix.Work {
			if w.Id == entryId {
				matrix.Work[i].Name, _ = rpc.Params["name"].(string)
				matrix.Work[i].Position, _ = rpc.Params["position"].(string)
				matrix.Work[i].Url, _ = rpc.Params["url"].(string)
				matrix.Work[i].StartDate, _ = rpc.Params["startDate"].(string)
				matrix.Work[i].EndDate, _ = rpc.Params["endDate"].(string)
				matrix.Work[i].Summary, _ = rpc.Params["summary"].(string)
				matrix.Work[i].Highlights = parseListEditorString(rpc.Params["highlights"])
				matrix.Work[i].Skills = parseListEditorString(rpc.Params["skills"])
				matrix.Work[i].Active = parseBoolStr(rpc.Params["active"])
				break
			}
		}
	case "shua.resume.delete_work":
		var filtered []models.WorkItem
		for _, w := range matrix.Work {
			if w.Id != entryId {
				filtered = append(filtered, w)
			}
		}
		matrix.Work = filtered

	case "shua.resume.add_education":
		var item models.Education
		item.Id = uuid.NewString()
		item.Institution, _ = rpc.Params["institution"].(string)
		item.Url, _ = rpc.Params["url"].(string)
		item.Area, _ = rpc.Params["area"].(string)
		item.StudyType, _ = rpc.Params["studyType"].(string)
		item.StartDate, _ = rpc.Params["startDate"].(string)
		item.EndDate, _ = rpc.Params["endDate"].(string)
		item.Score, _ = rpc.Params["score"].(string)
		item.Courses = parseListEditorString(rpc.Params["courses"])
		matrix.Education = append(matrix.Education, item)

	case "shua.resume.update_education":
		for i, w := range matrix.Education {
			if w.Id == entryId {
				matrix.Education[i].Institution, _ = rpc.Params["institution"].(string)
				matrix.Education[i].Url, _ = rpc.Params["url"].(string)
				matrix.Education[i].Area, _ = rpc.Params["area"].(string)
				matrix.Education[i].StudyType, _ = rpc.Params["studyType"].(string)
				matrix.Education[i].StartDate, _ = rpc.Params["startDate"].(string)
				matrix.Education[i].EndDate, _ = rpc.Params["endDate"].(string)
				matrix.Education[i].Score, _ = rpc.Params["score"].(string)
				matrix.Education[i].Courses = parseListEditorString(rpc.Params["courses"])
				break
			}
		}
	case "shua.resume.delete_education":
		var filtered []models.Education
		for _, w := range matrix.Education {
			if w.Id != entryId {
				filtered = append(filtered, w)
			}
		}
		matrix.Education = filtered

	case "shua.resume.add_project":
		var item models.ProjectItem
		item.Id = uuid.NewString()
		item.Name, _ = rpc.Params["name"].(string)
		item.Description, _ = rpc.Params["description"].(string)
		item.Url, _ = rpc.Params["url"].(string)
		item.Highlights = parseListEditorString(rpc.Params["highlights"])
		item.Exhibits = parseListEditorString(rpc.Params["exhibits"])
		item.Active = parseBoolStr(rpc.Params["active"])
		matrix.Projects = append(matrix.Projects, item)

	case "shua.resume.update_project":
		for i, w := range matrix.Projects {
			if w.Id == entryId {
				matrix.Projects[i].Name, _ = rpc.Params["name"].(string)
				matrix.Projects[i].Description, _ = rpc.Params["description"].(string)
				matrix.Projects[i].Url, _ = rpc.Params["url"].(string)
				matrix.Projects[i].Highlights = parseListEditorString(rpc.Params["highlights"])
				matrix.Projects[i].Exhibits = parseListEditorString(rpc.Params["exhibits"])
				matrix.Projects[i].Active = parseBoolStr(rpc.Params["active"])
				break
			}
		}
	case "shua.resume.delete_project":
		var filtered []models.ProjectItem
		for _, w := range matrix.Projects {
			if w.Id != entryId {
				filtered = append(filtered, w)
			}
		}
		matrix.Projects = filtered

	case "shua.resume.add_skill":
		var item models.Skill
		item.Id = uuid.NewString()
		item.Name, _ = rpc.Params["name"].(string)
		item.Level, _ = rpc.Params["level"].(string)
		item.Keywords = parseListEditorString(rpc.Params["keywords"])
		matrix.Skills = append(matrix.Skills, item)

	case "shua.resume.update_skill":
		for i, w := range matrix.Skills {
			if w.Id == entryId {
				matrix.Skills[i].Name, _ = rpc.Params["name"].(string)
				matrix.Skills[i].Level, _ = rpc.Params["level"].(string)
				matrix.Skills[i].Keywords = parseListEditorString(rpc.Params["keywords"])
				break
			}
		}
	case "shua.resume.delete_skill":
		var filtered []models.Skill
		for _, w := range matrix.Skills {
			if w.Id != entryId {
				filtered = append(filtered, w)
			}
		}
		matrix.Skills = filtered

	case "shua.resume.add_certificate":
		var item models.Certificate
		item.Id = uuid.NewString()
		item.Name, _ = rpc.Params["name"].(string)
		item.Issuer, _ = rpc.Params["issuer"].(string)
		item.Date, _ = rpc.Params["date"].(string)
		item.Url, _ = rpc.Params["url"].(string)
		matrix.Certificates = append(matrix.Certificates, item)

	case "shua.resume.update_certificate":
		for i, w := range matrix.Certificates {
			if w.Id == entryId {
				matrix.Certificates[i].Name, _ = rpc.Params["name"].(string)
				matrix.Certificates[i].Issuer, _ = rpc.Params["issuer"].(string)
				matrix.Certificates[i].Date, _ = rpc.Params["date"].(string)
				matrix.Certificates[i].Url, _ = rpc.Params["url"].(string)
				break
			}
		}
	case "shua.resume.delete_certificate":
		var filtered []models.Certificate
		for _, w := range matrix.Certificates {
			if w.Id != entryId {
				filtered = append(filtered, w)
			}
		}
		matrix.Certificates = filtered

	case "shua.resume.add_award":
		var item models.Award
		item.Id = uuid.NewString()
		item.Title, _ = rpc.Params["title"].(string)
		item.Date, _ = rpc.Params["date"].(string)
		item.Sender, _ = rpc.Params["awarder"].(string)
		item.Summary, _ = rpc.Params["summary"].(string)
		matrix.Awards = append(matrix.Awards, item)

	case "shua.resume.update_award":
		for i, w := range matrix.Awards {
			if w.Id == entryId {
				matrix.Awards[i].Title, _ = rpc.Params["title"].(string)
				matrix.Awards[i].Date, _ = rpc.Params["date"].(string)
				matrix.Awards[i].Sender, _ = rpc.Params["awarder"].(string)
				matrix.Awards[i].Summary, _ = rpc.Params["summary"].(string)
				break
			}
		}
	case "shua.resume.delete_award":
		var filtered []models.Award
		for _, w := range matrix.Awards {
			if w.Id != entryId {
				filtered = append(filtered, w)
			}
		}
		matrix.Awards = filtered
	}

	newJsonBytes, _ := json.Marshal(matrix)
	now := time.Now().UnixNano() / int64(time.Millisecond)
	_, dbErr := db.DB.Exec(
		"INSERT INTO shua_resume_matrix (user_id, matrix_json, updated_at) VALUES (?, ?, ?) ON CONFLICT(user_id) DO UPDATE SET matrix_json = excluded.matrix_json, updated_at = excluded.updated_at",
		"default", string(newJsonBytes), now,
	)

	if dbErr != nil {
		sendRpcError(s, rpc.TransactionID, "Database save failure")
		return
	}

	sendRpcSuccess(s, rpc.TransactionID, "OK")
}
