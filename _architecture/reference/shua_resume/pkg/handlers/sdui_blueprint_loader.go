package handlers

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// LoadAndHydrateBlueprint reads all JSON blueprints from schemas/blueprints/resume/,
// extracts the specified screen, and recursively hydrates dynamic token bindings.
func LoadAndHydrateBlueprint(screenId string, ctx map[string]interface{}) (interface{}, error) {
	blueprintDir := filepath.Join("..", "..", "schemas", "blueprints", "resume")
	if _, err := os.Stat(blueprintDir); os.IsNotExist(err) {
		blueprintDir = filepath.Join("schemas", "blueprints", "resume")
	}

	blueprints := make(map[string]interface{})
	entries, err := os.ReadDir(blueprintDir)
	if err != nil {
		return nil, fmt.Errorf("failed to read blueprint directory: %w", err)
	}

	for _, entry := range entries {
		if !entry.IsDir() && strings.HasSuffix(entry.Name(), ".json") {
			data, err := os.ReadFile(filepath.Join(blueprintDir, entry.Name()))
			if err != nil {
				continue
			}
			if len(data) >= 3 && data[0] == 0xef && data[1] == 0xbb && data[2] == 0xbf {
				data = data[3:]
			}
			var fileBlueprints map[string]interface{}
			if err := json.Unmarshal(data, &fileBlueprints); err == nil {
				for k, v := range fileBlueprints {
					blueprints[k] = v
				}
			}
		}
	}

	screenTemplate, exists := blueprints[screenId]
	if !exists {
		return nil, fmt.Errorf("screen template '%s' not found in blueprint", screenId)
	}

	return hydrateValue(screenTemplate, ctx), nil
}

func hydrateValue(node interface{}, ctx map[string]interface{}) interface{} {
	if node == nil {
		return nil
	}

	switch val := node.(type) {
	case float64:
		if val == float64(int64(val)) {
			return int(val)
		}
		return val
	case string:
		return hydrateString(val, ctx)
	case []interface{}:
		res := make([]interface{}, len(val))
		for i, child := range val {
			res[i] = hydrateValue(child, ctx)
		}
		return res
	case map[string]interface{}:
		hydrated := make(map[string]interface{})
		for k, v := range val {
			// Special case: Iterator nodes (nested inside content block 4 under data key 6)
			if k == "4" {
				if contentMap, ok := v.(map[string]interface{}); ok {
					if dataObj, exists := contentMap["6"]; exists {
						if dataMap, isMap := dataObj.(map[string]interface{}); isMap {
							if iteratorVal, hasIterator := dataMap["iterator"]; hasIterator {
								if iteratorKey, isStr := iteratorVal.(string); isStr {
									collection := ctx[iteratorKey]
									var items []map[string]interface{}
									if collection != nil {
										if b, err := json.Marshal(collection); err == nil {
											_ = json.Unmarshal(b, &items)
										}
									}

									contentCopy := make(map[string]interface{})
									for ck, cv := range contentMap {
										if ck != "6" {
											contentCopy[ck] = hydrateValue(cv, ctx)
										}
									}
									var stringifiedData string = "[]"
									if len(items) > 0 {
										if b, err := json.Marshal(items); err == nil {
											stringifiedData = string(b)
										}
									}
									contentCopy["6"] = stringifiedData
									hydrated["4"] = contentCopy

									if templateNode, hasTemplate := val["template"]; hasTemplate {
										children := make([]interface{}, 0)
										children = append(children, hydrateValue(templateNode, ctx))
										hydrated["2"] = children
									}
									continue
								}
							}
						}
					}
				}
			}

			if k == "template" {
				continue
			}
			hydrated[k] = hydrateValue(v, ctx)
		}
		return hydrated
	default:
		return val
	}
}

func hydrateString(str string, ctx map[string]interface{}) interface{} {
	if strings.HasPrefix(str, "{{") && strings.HasSuffix(str, "}}") {
		key := str[2 : len(str)-2]
		if val, exists := ctx[key]; exists {
			return val
		}
		return str
	}

	result := str
	for k, v := range ctx {
		placeholder := "{{" + k + "}}"
		if strings.Contains(result, placeholder) {
			result = strings.ReplaceAll(result, placeholder, fmt.Sprintf("%v", v))
		}
	}
	return result
}
