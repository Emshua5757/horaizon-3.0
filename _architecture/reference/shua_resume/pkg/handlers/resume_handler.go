package handlers

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/vmihailenco/msgpack/v5"
	"shua_resume/pkg/ai"
	"shua_resume/pkg/compiler"
	"shua_resume/pkg/db"
	"shua_resume/pkg/logger"
	"shua_resume/pkg/models"
)

// Compile semaphore to throttle concurrent typst compiles (max 2 parallel runs)
var compileSemaphore = make(chan struct{}, 2)

// parseRequestBody deserializes request parameters from JSON or HBP MessagePack dynamically
func parseRequestBody(c *fiber.Ctx) (map[string]string, error) {
	result := make(map[string]string)
	contentType := strings.ToLower(c.Get("Content-Type"))

	if strings.Contains(contentType, "msgpack") {
		var rawMap map[interface{}]interface{}
		if err := msgpack.Unmarshal(c.Body(), &rawMap); err != nil {
			// Fallback: try string keys
			var strMap map[string]interface{}
			if errStr := msgpack.Unmarshal(c.Body(), &strMap); errStr == nil {
				for k, v := range strMap {
					result[k] = fmt.Sprintf("%v", v)
				}
				return result, nil
			}
			return nil, fmt.Errorf("failed to unmarshal msgpack: %w", err)
		}

		for k, v := range rawMap {
			var keyStr string
			switch key := k.(type) {
			case string:
				keyStr = key
			case int:
				keyStr = strconv.Itoa(key)
			case int64:
				keyStr = strconv.FormatInt(key, 10)
			case uint64:
				keyStr = strconv.FormatUint(key, 10)
			default:
				keyStr = fmt.Sprintf("%v", key)
			}
			result[keyStr] = fmt.Sprintf("%v", v)
		}
		return result, nil
	}

	// Default to JSON
	var jsonMap map[string]interface{}
	if err := json.Unmarshal(c.Body(), &jsonMap); err != nil {
		// Fallback to Fiber's body parser
		var body map[string]string
		if errParser := c.BodyParser(&body); errParser == nil {
			return body, nil
		}
		return nil, fmt.Errorf("failed to parse JSON body: %w", err)
	}

	for k, v := range jsonMap {
		result[k] = fmt.Sprintf("%v", v)
	}
	return result, nil
}

// sendResponse serializes response payload to JSON or HBP MessagePack depending on incoming Content-Type
func sendResponse(c *fiber.Ctx, status int, data interface{}) error {
	contentType := strings.ToLower(c.Get("Content-Type"))
	isMsgpack := strings.Contains(contentType, "msgpack")

	if isMsgpack {
		payload := map[int]interface{}{
			0: status,
		}
		if data != nil {
			payload[1] = data
		}
		respBytes, err := msgpack.Marshal(payload)
		if err != nil {
			logger.Error("handlers", "Failed to encode msgpack response", err, nil)
			return c.Status(fiber.StatusInternalServerError).SendString("Internal server error")
		}
		c.Set(fiber.HeaderContentType, "application/msgpack")
		return c.Send(respBytes)
	}

	// Default JSON response
	resp := fiber.Map{
		"0": status,
	}
	if data != nil {
		resp["1"] = data
	}
	return c.JSON(resp)
}

// GetMatrixHandler resolves RPC 501: Retrieves the current resume matrix JSON
func GetMatrixHandler(c *fiber.Ctx) error {
	var matrixJSON string
	err := db.DB.QueryRow("SELECT matrix_json FROM shua_resume_matrix WHERE user_id = ?", "default").Scan(&matrixJSON)
	if err != nil {
		if err == sql.ErrNoRows {
			logger.Error("handlers", "Resume matrix not found in DB", nil, nil)
			return sendResponse(c, 1, "Resume matrix not found")
		}
		logger.Error("handlers", "Failed to query matrix", err, nil)
		return sendResponse(c, 4, "Database error")
	}

	return sendResponse(c, 0, matrixJSON)
}

// UpdateMatrixHandler resolves RPC 502: Updates the resume matrix JSON
func UpdateMatrixHandler(c *fiber.Ctx) error {
	body, err := parseRequestBody(c)
	if err != nil {
		return sendResponse(c, 1, "Invalid request body")
	}

	// Key "10" is content representing the updated matrix JSON
	matrixJSON, ok := body["10"]
	if !ok || matrixJSON == "" {
		return sendResponse(c, 1, "Missing matrix content key '10'")
	}

	// Validate JSON structure before storing
	var temp models.ResumeMatrix
	if err := json.Unmarshal([]byte(matrixJSON), &temp); err != nil {
		return sendResponse(c, 1, "Malformed resume matrix JSON structure")
	}

	now := time.Now().UnixNano() / int64(time.Millisecond)
	_, dbErr := db.DB.Exec(
		"INSERT INTO shua_resume_matrix (user_id, matrix_json, updated_at) VALUES (?, ?, ?) ON CONFLICT(user_id) DO UPDATE SET matrix_json = excluded.matrix_json, updated_at = excluded.updated_at",
		"default", matrixJSON, now,
	)
	if dbErr != nil {
		logger.Error("handlers", "Failed to write matrix to DB", dbErr, nil)
		return sendResponse(c, 4, "Database save failure")
	}

	logger.Info("handlers", "Resume matrix updated successfully", nil)
	return sendResponse(c, 0, nil)
}

// CompilePdfHandler resolves RPC 503: Compiles the active nodes to Typst PDF
func CompilePdfHandler(c *fiber.Ctx) error {
	// Throttle with semaphore to respect Pi 5 cores limit
	select {
	case compileSemaphore <- struct{}{}:
		defer func() { <-compileSemaphore }()
	default:
		logger.Error("handlers", "Compile concurrency limit reached", nil, nil)
		return sendResponse(c, 6, "Server busy")
	}

	body, err := parseRequestBody(c)
	if err != nil {
		return sendResponse(c, 1, "Invalid request body")
	}

	// Key "24" is the template name
	templateName, ok := body["24"]
	if !ok || templateName == "" {
		templateName = "ats_technical"
	}

	// Key "0" is the Job Description text
	jobDescription := body["0"]

	// Fetch matrix from database
	var matrixJSON string
	dbErr := db.DB.QueryRow("SELECT matrix_json FROM shua_resume_matrix WHERE user_id = ?", "default").Scan(&matrixJSON)
	if dbErr != nil {
		logger.Error("handlers", "Failed to retrieve matrix for compilation", dbErr, nil)
		return sendResponse(c, 4, "Matrix data missing")
	}

	var matrix models.ResumeMatrix
	if err := json.Unmarshal([]byte(matrixJSON), &matrix); err != nil {
		return sendResponse(c, 1, "Database matrix corrupt")
	}

	// If job description is provided, filter and tailor active resume nodes
	if strings.TrimSpace(jobDescription) != "" {
		config := ai.DefaultTailorConfig()

		if val, ok := body["work_limit"]; ok {
			if limit, err := strconv.Atoi(val); err == nil {
				config.WorkLimit = limit
			}
		} else if val, ok := body["20"]; ok {
			if limit, err := strconv.Atoi(val); err == nil {
				config.WorkLimit = limit
			}
		}

		if val, ok := body["project_limit"]; ok {
			if limit, err := strconv.Atoi(val); err == nil {
				config.ProjectLimit = limit
			}
		} else if val, ok := body["21"]; ok {
			if limit, err := strconv.Atoi(val); err == nil {
				config.ProjectLimit = limit
			}
		}

		if val, ok := body["min_score"]; ok {
			if score, err := strconv.ParseFloat(val, 64); err == nil {
				config.MinScore = score
			}
		}

		if val, ok := body["use_ai"]; ok {
			config.UseAI = (val != "false")
		} else if val, ok := body["23"]; ok {
			config.UseAI = (val != "false")
		}

		filteredMatrix := ai.FilterResume(&matrix, jobDescription, config)
		tailoredMatrix := ai.TailorResume(filteredMatrix, jobDescription, config)
		matrix = *tailoredMatrix
	}

	// Execute Typst compile subprocess pipeline
	pdfBytes, compileErr := compiler.CompileTypst(&matrix, templateName)
	if compileErr != nil {
		logger.Error("handlers", "Compilation failed", compileErr, nil)
		return sendResponse(c, 1, compileErr.Error())
	}

	// Archive the compiled PDF to the Governor's CAS vault with offline-resilience fallback
	exhibitID, uploadErr := uploadToCAS(pdfBytes)
	if uploadErr != nil {
		logger.Error("handlers", "Failed to archive compiled PDF to CAS (running offline-fallback)", uploadErr, nil)
	} else {
		// Log to compilation history
		if historyErr := saveCompilationToHistory(templateName, exhibitID, jobDescription); historyErr != nil {
			logger.Error("handlers", "Failed to save compilation history record", historyErr, nil)
		}
	}

	governorHost := os.Getenv("GOVERNOR_HOST")
	if governorHost == "" {
		h := c.Hostname()
		if idx := strings.Index(h, ":"); idx != -1 {
			h = h[:idx]
		}
		if h == "" || h == "localhost" || h == "127.0.0.1" {
			governorHost = DetectedHostIP
		} else {
			governorHost = h
		}
	}
	respData := map[string]interface{}{
		"exhibit_id": exhibitID,
		"url":        fmt.Sprintf("/api/media/uploads/%s.pdf", exhibitID),
	}
	return sendResponse(c, 0, respData)
}

// uploadToCAS uploads raw PDF bytes to the Governor's media server.
// It returns the file hash (which is the CAS ID) on success, or an error.
func uploadToCAS(pdfBytes []byte) (string, error) {
	bodyBuf := &bytes.Buffer{}
	bodyWriter := multipart.NewWriter(bodyBuf)

	// Create file field
	fileWriter, err := bodyWriter.CreateFormFile("file", "resume.pdf")
	if err != nil {
		return "", fmt.Errorf("failed to create form file field: %w", err)
	}

	// Copy PDF bytes
	if _, err := io.Copy(fileWriter, bytes.NewReader(pdfBytes)); err != nil {
		return "", fmt.Errorf("failed to copy file bytes: %w", err)
	}

	// Add module_owner field
	if err := bodyWriter.WriteField("module_owner", "shua_resume"); err != nil {
		return "", fmt.Errorf("failed to write module_owner field: %w", err)
	}

	if err := bodyWriter.Close(); err != nil {
		return "", fmt.Errorf("failed to close multipart writer: %w", err)
	}

	// Send POST request
	reqUrl := "http://127.0.0.1:3000/api/media/upload"
	req, err := http.NewRequest("POST", reqUrl, bodyBuf)
	if err != nil {
		return "", fmt.Errorf("failed to create http request: %w", err)
	}

	req.Header.Set("Content-Type", bodyWriter.FormDataContentType())
	// Injected to trust loopback connection
	req.Header.Set("X-Forwarded-For", "127.0.0.1")

	client := &http.Client{
		Timeout: 5 * time.Second,
	}

	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to execute post request to governor: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		respBodyBytes, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("governor upload failed with status %d: %s", resp.StatusCode, string(respBodyBytes))
	}

	// Parse response JSON: {"success": true, "hash": "...", "url": "..."}
	var res struct {
		Success bool   `json:"success"`
		Hash    string `json:"hash"`
		Url     string `json:"url"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&res); err != nil {
		return "", fmt.Errorf("failed to decode governor response: %w", err)
	}

	if !res.Success || res.Hash == "" {
		return "", fmt.Errorf("governor response indicated failure or empty hash")
	}

	return res.Hash, nil
}

// saveCompilationToHistory saves the compilation run to the local history table
// and prunes older records keeping only the top 20.
func saveCompilationToHistory(templateID string, exhibitID string, jd string) error {
	id := uuid.New().String()
	now := time.Now().UnixNano() / int64(time.Millisecond)

	// Trim job description to make notes clean
	notes := "Compiled resume"
	trimmedJd := strings.TrimSpace(jd)
	if trimmedJd != "" {
		if len(trimmedJd) > 40 {
			notes = fmt.Sprintf("Tailored for: %s...", trimmedJd[:40])
		} else {
			notes = fmt.Sprintf("Tailored for: %s", trimmedJd)
		}
	}

	// 1. Insert history record
	_, err := db.DB.Exec(
		"INSERT INTO shua_compiled_resumes (id, user_id, template_id, exhibit_id, version_tag, meta_notes, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
		id, "default", templateID, exhibitID, "v1.0.0", notes, now,
	)
	if err != nil {
		return fmt.Errorf("failed to insert compile run record: %w", err)
	}

	// 2. Auto-Pruning Policy: Delete records older than the top 20
	var threshold int64
	err = db.DB.QueryRow(
		"SELECT created_at FROM shua_compiled_resumes ORDER BY created_at DESC LIMIT 1 OFFSET 19",
	).Scan(&threshold)

	if err == nil {
		// Delete everything older than the 20th record
		_, delErr := db.DB.Exec("DELETE FROM shua_compiled_resumes WHERE created_at < ?", threshold)
		if delErr != nil {
			logger.Error("handlers", "Failed to prune compilation history", delErr, nil)
		} else {
			logger.Info("handlers", "Pruned compilation history to keep top 20 records", nil)
		}
	} else if err != sql.ErrNoRows {
		logger.Error("handlers", "Failed to query pruning threshold", err, nil)
	}

	return nil
}

// GetTemplatesHandler resolves RPC 504: Lists all available Typst templates
func GetTemplatesHandler(c *fiber.Ctx) error {
	rows, err := db.DB.Query("SELECT id, name, template_type FROM shua_resume_templates")
	if err != nil {
		logger.Error("handlers", "Failed to query templates table", err, nil)
		return sendResponse(c, 4, "Database query failure")
	}
	defer rows.Close()

	var list []map[string]interface{}
	for rows.Next() {
		var id, name, tType string
		if err := rows.Scan(&id, &name, &tType); err != nil {
			logger.Error("handlers", "Row scan failure in templates list", err, nil)
			continue
		}
		list = append(list, map[string]interface{}{
			"id":            id,
			"name":          name,
			"template_type": tType,
		})
	}
	if err := rows.Err(); err != nil {
		logger.Error("handlers", "Error iterating templates table rows", err, nil)
		return sendResponse(c, 4, "Database iteration failure")
	}

	return sendResponse(c, 0, list)
}

// ListCompiledHandler resolves RPC 505: Returns previously compiled resumes history
func ListCompiledHandler(c *fiber.Ctx) error {
	body, err := parseRequestBody(c)
	if err != nil {
		return sendResponse(c, 1, "Invalid request body")
	}

	limit := 10
	offset := 0

	if val, ok := body["limit"]; ok {
		if l, err := strconv.Atoi(val); err == nil {
			limit = l
		}
	} else if val, ok := body["20"]; ok {
		if l, err := strconv.Atoi(val); err == nil {
			limit = l
		}
	}

	if val, ok := body["offset"]; ok {
		if o, err := strconv.Atoi(val); err == nil {
			offset = o
		}
	} else if val, ok := body["21"]; ok {
		if o, err := strconv.Atoi(val); err == nil {
			offset = o
		}
	}

	rows, err := db.DB.Query(
		"SELECT id, user_id, template_id, exhibit_id, version_tag, meta_notes, created_at FROM shua_compiled_resumes ORDER BY created_at DESC LIMIT ? OFFSET ?",
		limit, offset,
	)
	if err != nil {
		logger.Error("handlers", "Failed to query compiled resumes table", err, nil)
		return sendResponse(c, 4, "Database query failure")
	}
	defer rows.Close()

	var list []map[string]interface{}
	for rows.Next() {
		var id, userID, templateID, version, notes string
		var exhibitID sql.NullString
		var createdAt int64
		err := rows.Scan(&id, &userID, &templateID, &exhibitID, &version, &notes, &createdAt)
		if err != nil {
			logger.Error("handlers", "Row scan failure in compiled list", err, nil)
			continue
		}

		exhibit := ""
		if exhibitID.Valid {
			exhibit = exhibitID.String
		}

		list = append(list, map[string]interface{}{
			"id":          id,
			"user_id":     userID,
			"template_id": templateID,
			"exhibit_id":  exhibit,
			"version_tag": version,
			"meta_notes":  notes,
			"created_at":  createdAt,
		})
	}
	if err := rows.Err(); err != nil {
		logger.Error("handlers", "Error iterating compiled resumes table rows", err, nil)
		return sendResponse(c, 4, "Database iteration failure")
	}

	return sendResponse(c, 0, list)
}

// HealthCheckHandler handles readiness probes
func HealthCheckHandler(c *fiber.Ctx) error {
	return c.SendStatus(fiber.StatusOK)
}
